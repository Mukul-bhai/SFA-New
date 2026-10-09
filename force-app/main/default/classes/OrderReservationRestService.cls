@RestResource(urlMapping='/api/v1/orders/reserve-and-submit')
global inherited sharing class OrderReservationRestService {

    global class OrderRequestItem {
        public String productId;
        public Decimal quantity;
        public Decimal unitPrice;
    }

    global class OrderSubmissionRequest {
        public String idempotencyKey;
        public String retailerId;
        public String visitId;
        public List<OrderRequestItem> items;
    }

    global class OrderSubmissionResponse {
        public Boolean success;
        public String orderId;
        public String status;
        public String message;
        public List<AllocationDetail> allocations;
    }

    global class AllocationDetail {
        public String productId;
        public Decimal requestedQty;
        public Decimal allocatedQty;
        public Decimal backorderQty;
        public String fulfillingDistributorId;
        public String fulfillmentType;
    }

    @HttpPost
    global static OrderSubmissionResponse handleHttpPost() {
        RestRequest req = RestContext.request;
        String jsonBody = (req != null && req.requestBody != null) ? req.requestBody.toString() : '';
        if (String.isBlank(jsonBody)) {
            OrderSubmissionResponse err = new OrderSubmissionResponse();
            err.success = false;
            err.message = 'Empty request body';
            return err;
        }
        OrderSubmissionRequest parsedReq;
        try {
            parsedReq = (OrderSubmissionRequest) JSON.deserialize(jsonBody, OrderSubmissionRequest.class);
        } catch (Exception ex) {
            OrderSubmissionResponse err = new OrderSubmissionResponse();
            err.success = false;
            err.message = 'JSON Deserialization error: ' + ex.getMessage();
            return err;
        }
        return submitOrder(parsedReq);
    }

    global static OrderSubmissionResponse submitOrder(OrderSubmissionRequest req) {
        OrderSubmissionResponse response = new OrderSubmissionResponse();
        response.allocations = new List<AllocationDetail>();

        if (req == null || req.retailerId == null || req.items == null || req.items.isEmpty()) {
            response.success = false;
            response.message = 'Invalid request payload: retailerId and items are required.';
            return response;
        }

        // 1. Idempotency Check
        if (String.isNotBlank(req.idempotencyKey)) {
            List<Order__c> existingOrders = [
                SELECT Id, Status__c, Total_Amount__c 
                FROM Order__c 
                WHERE Idempotency_Key__c = :req.idempotencyKey 
                LIMIT 1
            ];
            if (!existingOrders.isEmpty()) {
                response.success = true;
                response.orderId = existingOrders[0].Id;
                response.status = existingOrders[0].Status__c;
                response.message = 'Idempotent replay: Order already processed.';
                return response;
            }
        }

        Savepoint sp = Database.setSavepoint();

        try {
            // 2. Fetch Retailer Details
            Retailer__c retailer = [
                SELECT Id, Name, Primary_Distributor__c, Backup_Distributor__c, 
                       Primary_Distributor__r.Default_Warehouse__c,
                       Backup_Distributor__r.Default_Warehouse__c,
                       Allow_Backup_Fulfillment__c, Credit_Hold__c, Outstanding_Balance__c, Credit_Limit__c
                FROM Retailer__c 
                WHERE Id = :req.retailerId 
                LIMIT 1
            ];

            if (retailer.Credit_Hold__c) {
                response.success = false;
                response.message = 'Retailer is on Credit Hold. Order cannot be placed.';
                return response;
            }

            Set<Id> productIds = new Set<Id>();
            for (OrderRequestItem item : req.items) {
                productIds.add(item.productId);
            }

            Id primaryWhId = retailer.Primary_Distributor__r.Default_Warehouse__c;
            Id backupWhId = (retailer.Allow_Backup_Fulfillment__c && retailer.Backup_Distributor__c != null) 
                            ? retailer.Backup_Distributor__r.Default_Warehouse__c : null;

            Set<Id> warehouseIds = new Set<Id>();
            if (primaryWhId != null) warehouseIds.add(primaryWhId);
            if (backupWhId != null) warehouseIds.add(backupWhId);

            // 3. PESSIMISTIC LOCKING: Lock inventory rows for involved warehouses
            Map<String, Inventory__c> invMap = new Map<String, Inventory__c>();
            if (!warehouseIds.isEmpty()) {
                List<Inventory__c> lockedInventories = [
                    SELECT Id, Warehouse__c, Product__c, Available_Stock__c, Physical_Stock__c, Reserved_Stock__c
                    FROM Inventory__c
                    WHERE Warehouse__c IN :warehouseIds AND Product__c IN :productIds
                    FOR UPDATE
                ];

                for (Inventory__c inv : lockedInventories) {
                    String key = inv.Warehouse__c + '_' + inv.Product__c;
                    invMap.put(key, inv);
                }
            }

            // 4. Create Order Header
            Order__c newOrder = new Order__c(
                Retailer__c = retailer.Id,
                Primary_Distributor__c = retailer.Primary_Distributor__c,
                Visit__c = req.visitId,
                Idempotency_Key__c = req.idempotencyKey,
                Status__c = 'Submitted',
                Order_Date__c = System.now(),
                Sales_Executive__c = UserInfo.getUserId(),
                Total_Amount__c = 0
            );
            insert newOrder;

            List<Order_Line__c> linesToInsert = new List<Order_Line__c>();
            Map<Id, Decimal> invReservedStockMap = new Map<Id, Decimal>();
            List<Inventory_Ledger__c> ledgersToInsert = new List<Inventory_Ledger__c>();
            Decimal orderTotal = 0;

            // 5. Intelligent Multi-Tier Allocation Loop
            for (OrderRequestItem item : req.items) {
                String primaryKey = (primaryWhId != null) ? primaryWhId + '_' + item.productId : null;
                Inventory__c primaryInv = (primaryKey != null) ? invMap.get(primaryKey) : null;

                Decimal requested = item.quantity;
                Decimal allocatedFromPrimary = 0;
                Decimal allocatedFromBackup = 0;
                Decimal unfulfilled = requested;

                AllocationDetail detail = new AllocationDetail();
                detail.productId = item.productId;
                detail.requestedQty = requested;

                // Check Primary Distributor Stock
                if (primaryInv != null && primaryInv.Available_Stock__c > 0) {
                    allocatedFromPrimary = Math.min(primaryInv.Available_Stock__c, unfulfilled);
                    Decimal currentReserved = invReservedStockMap.containsKey(primaryInv.Id) 
                        ? invReservedStockMap.get(primaryInv.Id) 
                        : (primaryInv.Reserved_Stock__c != null ? primaryInv.Reserved_Stock__c : 0);
                    
                    Decimal newReserved = currentReserved + allocatedFromPrimary;
                    invReservedStockMap.put(primaryInv.Id, newReserved);
                    unfulfilled -= allocatedFromPrimary;

                    ledgersToInsert.add(new Inventory_Ledger__c(
                        Inventory__c = primaryInv.Id,
                        Type__c = 'Order_Reservation',
                        Quantity_Delta__c = allocatedFromPrimary,
                        Reference_Record_Id__c = newOrder.Id,
                        Notes__c = 'Order Reservation - Primary Distributor',
                        Timestamp__c = System.now()
                    ));
                }

                // Fallback to Backup Distributor if permitted and primary was insufficient
                if (unfulfilled > 0 && backupWhId != null) {
                    String backupKey = backupWhId + '_' + item.productId;
                    Inventory__c backupInv = invMap.get(backupKey);

                    if (backupInv != null && backupInv.Available_Stock__c > 0) {
                        allocatedFromBackup = Math.min(backupInv.Available_Stock__c, unfulfilled);
                        Decimal currentReserved = invReservedStockMap.containsKey(backupInv.Id) 
                            ? invReservedStockMap.get(backupInv.Id) 
                            : (backupInv.Reserved_Stock__c != null ? backupInv.Reserved_Stock__c : 0);
                        
                        Decimal newReserved = currentReserved + allocatedFromBackup;
                        invReservedStockMap.put(backupInv.Id, newReserved);
                        unfulfilled -= allocatedFromBackup;

                        ledgersToInsert.add(new Inventory_Ledger__c(
                            Inventory__c = backupInv.Id,
                            Type__c = 'Order_Reservation',
                            Quantity_Delta__c = allocatedFromBackup,
                            Reference_Record_Id__c = newOrder.Id,
                            Notes__c = 'Order Reservation - Backup Distributor',
                            Timestamp__c = System.now()
                        ));
                    }
                }

                // Create Order Lines
                if (allocatedFromPrimary > 0) {
                    linesToInsert.add(new Order_Line__c(
                        Order__c = newOrder.Id,
                        Product__c = item.productId,
                        Quantity__c = allocatedFromPrimary,
                        Unit_Price__c = item.unitPrice,
                        Fulfilling_Distributor__c = retailer.Primary_Distributor__c,
                        Fulfillment_Status__c = 'Allocated_Primary'
                    ));
                    orderTotal += (allocatedFromPrimary * (item.unitPrice != null ? item.unitPrice : 0));
                }
                if (allocatedFromBackup > 0) {
                    linesToInsert.add(new Order_Line__c(
                        Order__c = newOrder.Id,
                        Product__c = item.productId,
                        Quantity__c = allocatedFromBackup,
                        Unit_Price__c = item.unitPrice,
                        Fulfilling_Distributor__c = retailer.Backup_Distributor__c,
                        Fulfillment_Status__c = 'Allocated_Backup'
                    ));
                    orderTotal += (allocatedFromBackup * (item.unitPrice != null ? item.unitPrice : 0));
                }
                if (unfulfilled > 0) {
                    linesToInsert.add(new Order_Line__c(
                        Order__c = newOrder.Id,
                        Product__c = item.productId,
                        Quantity__c = unfulfilled,
                        Unit_Price__c = item.unitPrice,
                        Fulfilling_Distributor__c = retailer.Primary_Distributor__c,
                        Fulfillment_Status__c = 'Backordered'
                    ));
                    orderTotal += (unfulfilled * (item.unitPrice != null ? item.unitPrice : 0));
                }

                detail.allocatedQty = allocatedFromPrimary + allocatedFromBackup;
                detail.backorderQty = unfulfilled;
                detail.fulfillmentType = (unfulfilled == 0) ? 
                    (allocatedFromBackup > 0 ? 'SPLIT_PRIMARY_BACKUP' : 'PRIMARY') : 'PARTIAL_BACKORDER';
                response.allocations.add(detail);
            }

            if (!linesToInsert.isEmpty()) {
                insert linesToInsert;
            }
            if (!invReservedStockMap.isEmpty()) {
                List<Inventory__c> cleanUpdates = new List<Inventory__c>();
                for (Id invId : invReservedStockMap.keySet()) {
                    cleanUpdates.add(new Inventory__c(
                        Id = invId,
                        Reserved_Stock__c = invReservedStockMap.get(invId)
                    ));
                }
                update cleanUpdates;
            }
            if (!ledgersToInsert.isEmpty()) {
                insert ledgersToInsert;
            }

            newOrder.Total_Amount__c = orderTotal;
            update newOrder;

            response.success = true;
            response.orderId = newOrder.Id;
            response.status = 'Submitted';
            response.message = 'Order processed and inventory reserved successfully.';
            return response;

        } catch (Exception ex) {
            Database.rollback(sp);
            response.success = false;
            response.message = 'Order reservation failed: ' + ex.getMessage();
            return response;
        }
    }
}

// Exposes this Apex class as a REST API endpoint.
// The mobile app or frontend can send an HTTP POST request to this URL.
@RestResource(urlMapping='/api/v1/orders/reserve-and-submit')

// global makes the class accessible to external Apex REST clients.
// inherited sharing follows the sharing rules of the calling context.
global inherited sharing class OrderReservationRestService {

    // Represents one product requested in an order.
    global class OrderRequestItem {
        public String productId;    // Salesforce ID of the product.
        public Decimal quantity;    // Quantity the retailer wants to order.
        public Decimal unitPrice;   // Price of one unit of the product.
    }

    // Represents the complete order request received from the frontend.
    global class OrderSubmissionRequest {
        public String idempotencyKey;       // Unique key used to detect repeated requests.
        public String retailerId;            // ID of the retailer placing the order.
        public String visitId;               // Related sales visit ID, if available.
        public List<OrderRequestItem> items; // List of products and requested quantities.
    }

    // Defines the response returned after processing an order request.
    global class OrderSubmissionResponse {
        public Boolean success;                   // Indicates whether processing succeeded.
        public String orderId;                     // ID of the created or existing order.
        public String status;                      // Current order status.
        public String message;                     // Message explaining the result.
        public List<AllocationDetail> allocations; // Stock allocation details for products.
    }

    // Explains how much of a requested product was allocated or backordered.
    global class AllocationDetail {
        public String productId;                   // ID of the requested product.
        public Decimal requestedQty;                // Quantity requested by the retailer.
        public Decimal allocatedQty;                // Quantity allocated from available stock.
        public Decimal backorderQty;                // Quantity that could not be allocated.
        public String fulfillingDistributorId;      // Distributor responsible for fulfillment.
        public String fulfillmentType;              // Allocation result, such as PRIMARY or PARTIAL_BACKORDER.
    }

    // Handles incoming HTTP POST requests to the REST endpoint.
    @HttpPost
    global static OrderSubmissionResponse handleHttpPost() {

        RestRequest req = RestContext.request;
        // Gets the HTTP request received by Salesforce.

        String jsonBody = (req != null && req.requestBody != null)
            ? req.requestBody.toString()
            : '';
        // Reads the request body as a string.
        // If the request or body is missing, uses an empty string.

        if (String.isBlank(jsonBody)) {
            // Checks whether the request body is empty or contains only whitespace.

            OrderSubmissionResponse err = new OrderSubmissionResponse();
            // Creates a response object for the error.

            err.success = false;
            // Marks the request as unsuccessful.

            err.message = 'Empty request body';
            // Explains why the request cannot be processed.

            return err;
            // Stops execution and returns the error response.
        }

        OrderSubmissionRequest parsedReq;
        // Declares the variable that will contain the converted request data.

        try {
            // Starts a block to safely handle invalid JSON.

            parsedReq = (OrderSubmissionRequest) JSON.deserialize(
                jsonBody,
                OrderSubmissionRequest.class
            );
            // Converts the JSON request into an Apex OrderSubmissionRequest object.
            // The JSON field names should match the properties in that class.

        } catch (Exception ex) {
            // Runs if JSON conversion fails.

            OrderSubmissionResponse err = new OrderSubmissionResponse();
            // Creates an error response.

            err.success = false;
            // Indicates that the request failed.

            err.message = 'JSON Deserialization error: ' + ex.getMessage();
            // Includes the reason JSON conversion failed.

            return err;
            // Returns the error without processing the order.
        }

        return submitOrder(parsedReq);
        // Passes the converted request to the main order-processing method.
    }

    // Main method that validates the request, allocates stock and creates the order.
    global static OrderSubmissionResponse submitOrder(OrderSubmissionRequest req) {

        OrderSubmissionResponse response = new OrderSubmissionResponse();
        // Creates the response object that will be returned to the caller.

        response.allocations = new List<AllocationDetail>();
        // Initializes an empty list to store allocation results for each product.

        if (req == null || req.retailerId == null ||
            req.items == null || req.items.isEmpty()) {
            // Checks whether the request, retailer ID or product list is missing.

            response.success = false;
            // Marks the request as unsuccessful.

            response.message =
                'Invalid request payload: retailerId and items are required.';
            // Explains which required information is missing.

            return response;
            // Stops processing when the required information is unavailable.
        }

        // STEP 1: Check whether this request has already created an order.
        if (String.isNotBlank(req.idempotencyKey)) {
            // Performs this check only when the request includes an idempotency key.

            List<Order__c> existingOrders = [
                SELECT Id, Status__c, Total_Amount__c
                FROM Order__c
                WHERE Idempotency_Key__c = :req.idempotencyKey
                LIMIT 1
            ];
            // Searches for an order with the same idempotency key.
            // The colon binds the Apex variable to the SOQL query.
            // LIMIT 1 returns at most one matching record.

            if (!existingOrders.isEmpty()) {
                // Checks whether an order with this key already exists.

                response.success = true;
                // Treats the repeated request as successfully handled.

                response.orderId = existingOrders[0].Id;
                // Returns the ID of the existing order.

                response.status = existingOrders[0].Status__c;
                // Returns the existing order's current status.

                response.message = 'Idempotent replay: Order already processed.';
                // Explains that the existing order is being returned instead
                // of creating another order.

                return response;
                // Stops processing to avoid creating a duplicate order.
            }
        }

        Savepoint sp = Database.setSavepoint();
        // Saves the current transaction state.
        // If a later operation fails, Database.rollback(sp) can undo changes
        // made after this savepoint.

        try {
            // Starts the main order-processing block.

            // STEP 2: Retrieve the retailer and distributor information.
            Retailer__c retailer = [
                SELECT Id, Name, Primary_Distributor__c, Backup_Distributor__c,
                       Primary_Distributor__r.Default_Warehouse__c,
                       Backup_Distributor__r.Default_Warehouse__c,
                       Allow_Backup_Fulfillment__c, Credit_Hold__c,
                       Outstanding_Balance__c, Credit_Limit__c
                FROM Retailer__c
                WHERE Id = :req.retailerId
                LIMIT 1
            ];
            // Retrieves the retailer's primary and backup distributors,
            // their default warehouses and the retailer's credit details.
            // This query throws an exception if no matching retailer is found.

            if (retailer.Credit_Hold__c) {
                // Checks whether the retailer is blocked from placing orders
                // because of a credit hold.

                response.success = false;
                // Marks the order request as unsuccessful.

                response.message =
                    'Retailer is on Credit Hold. Order cannot be placed.';
                // Provides the reason the order was rejected.

                return response;
                // Stops processing when the retailer is on credit hold.
            }

            Set<Id> productIds = new Set<Id>();
            // Creates a Set to store unique product IDs.
            // A Set automatically avoids duplicate IDs.

            for (OrderRequestItem item : req.items) {
                // Iterates through every product submitted in the request.

                productIds.add(item.productId);
                // Adds the current product ID to the Set.
            }

            Id primaryWhId =
                retailer.Primary_Distributor__r.Default_Warehouse__c;
            // Gets the default warehouse of the primary distributor.

            Id backupWhId =
                (retailer.Allow_Backup_Fulfillment__c &&
                 retailer.Backup_Distributor__c != null)
                ? retailer.Backup_Distributor__r.Default_Warehouse__c
                : null;
            // Uses the backup distributor's warehouse only when backup
            // fulfillment is allowed and a backup distributor is assigned.
            // Otherwise, backupWhId is null.

            Set<Id> warehouseIds = new Set<Id>();
            // Creates a Set for the warehouses involved in fulfillment.

            if (primaryWhId != null) {
                warehouseIds.add(primaryWhId);
                // Adds the primary warehouse if it exists.
            }

            if (backupWhId != null) {
                warehouseIds.add(backupWhId);
                // Adds the backup warehouse if it exists.
            }

            // STEP 3: Lock the relevant inventory records.
            // This is called pessimistic locking and helps prevent
            // concurrent transactions from modifying the same stock records.
            Map<String, Inventory__c> invMap =
                new Map<String, Inventory__c>();
            // Creates a Map that will store inventory records using a combined
            // warehouse ID and product ID as the key.

            if (!warehouseIds.isEmpty()) {
                // Queries inventory only when at least one warehouse is available.

                List<Inventory__c> lockedInventories = [
                    SELECT Id, Warehouse__c, Product__c,
                           Available_Stock__c, Physical_Stock__c,
                           Reserved_Stock__c
                    FROM Inventory__c
                    WHERE Warehouse__c IN :warehouseIds
                      AND Product__c IN :productIds
                    FOR UPDATE
                ];
                // Retrieves inventory for the selected warehouses and products.
                // FOR UPDATE locks the returned records until the transaction ends.

                for (Inventory__c inv : lockedInventories) {
                    // Processes each retrieved inventory record.

                    String key = inv.Warehouse__c + '_' + inv.Product__c;
                    // Creates a unique lookup key using warehouse ID and product ID.

                    invMap.put(key, inv);
                    // Stores the inventory record in the Map for quick lookup.
                }
            }

            // STEP 4: Create the main order record, also called the order header.
            Order__c newOrder = new Order__c(
                Retailer__c = retailer.Id,
                // Links the order to the retailer.

                Primary_Distributor__c = retailer.Primary_Distributor__c,
                // Stores the retailer's primary distributor on the order.

                Visit__c = req.visitId,
                // Links the order to the sales visit, if supplied.

                Idempotency_Key__c = req.idempotencyKey,
                // Stores the request key used to detect duplicate submissions.

                Status__c = 'Submitted',
                // Sets the initial order status to Submitted.

                Order_Date__c = System.now(),
                // Stores the current date and time.

                Sales_Executive__c = UserInfo.getUserId(),
                // Associates the order with the Salesforce user making the request.

                Total_Amount__c = 0
                // Initializes the order total before calculating it.
            );

            insert newOrder;
            // Saves the order header in Salesforce.
            // Salesforce generates the record ID after insertion.

            List<Order_Line__c> linesToInsert =
                new List<Order_Line__c>();
            // Stores the product line records that will be created.

            Map<Id, Decimal> invReservedStockMap =
                new Map<Id, Decimal>();
            // Stores the new reserved-stock value for each inventory record.
            // The inventory record ID is the key and the new quantity is the value.

            List<Inventory_Ledger__c> ledgersToInsert =
                new List<Inventory_Ledger__c>();
            // Stores stock reservation history records to insert later.

            Decimal orderTotal = 0;
            // Initializes the total order amount.

            // STEP 5: Allocate stock for every requested product.
            // The primary distributor is checked first.
            // If its stock is insufficient, the backup distributor is checked.
            for (OrderRequestItem item : req.items) {

                String primaryKey =
                    (primaryWhId != null)
                    ? primaryWhId + '_' + item.productId
                    : null;
                // Builds the primary warehouse/product lookup key.
                // If there is no primary warehouse, the key is null.

                Inventory__c primaryInv =
                    (primaryKey != null) ? invMap.get(primaryKey) : null;
                // Retrieves the primary warehouse inventory record from the Map.
                // If the key is null or no record matches, primaryInv is null.

                Decimal requested = item.quantity;
                // Stores the quantity requested for this product.

                Decimal allocatedFromPrimary = 0;
                // Initializes the quantity allocated from the primary distributor.

                Decimal allocatedFromBackup = 0;
                // Initializes the quantity allocated from the backup distributor.

                Decimal unfulfilled = requested;
                // Initially, the entire requested quantity remains unfulfilled.

                AllocationDetail detail = new AllocationDetail();
                // Creates an object to describe the allocation result.

                detail.productId = item.productId;
                // Stores the product ID in the allocation result.

                detail.requestedQty = requested;
                // Stores the original requested quantity.

                // Check stock available at the primary distributor.
                if (primaryInv != null &&
                    primaryInv.Available_Stock__c > 0) {
                    // Continues only when primary inventory exists
                    // and its available-stock field is greater than zero.

                    allocatedFromPrimary = Math.min(
                        primaryInv.Available_Stock__c,
                        unfulfilled
                    );
                    // Allocates whichever is smaller:
                    // the available stock or the remaining requested quantity.

                    Decimal currentReserved =
                        invReservedStockMap.containsKey(primaryInv.Id)
                        ? invReservedStockMap.get(primaryInv.Id)
                        : (primaryInv.Reserved_Stock__c != null
                            ? primaryInv.Reserved_Stock__c
                            : 0);
                    // Gets the latest reserved quantity tracked in this transaction.
                    // If no updated value exists in the Map, uses the inventory
                    // record's existing reserved quantity, or zero if null.

                    Decimal newReserved =
                        currentReserved + allocatedFromPrimary;
                    // Calculates the new reserved quantity after allocation.

                    invReservedStockMap.put(primaryInv.Id, newReserved);
                    // Stores the updated reserved quantity for this inventory record.

                    unfulfilled -= allocatedFromPrimary;
                    // Reduces the remaining quantity by the primary allocation.

                    ledgersToInsert.add(new Inventory_Ledger__c(
                        Inventory__c = primaryInv.Id,
                        // Links the ledger entry to the inventory record.

                        Type__c = 'Order_Reservation',
                        // Identifies this stock movement as an order reservation.

                        Quantity_Delta__c = allocatedFromPrimary,
                        // Records the positive quantity reserved.

                        Reference_Record_Id__c = newOrder.Id,
                        // Links the ledger entry to the order.

                        Notes__c = 'Order Reservation - Primary Distributor',
                        // Explains that the primary distributor reserved the stock.

                        Timestamp__c = System.now()
                        // Records when the reservation was created.
                    ));
                    // Adds the ledger entry to the list for later insertion.
                }

                // STEP 6: Check the backup distributor if stock is still needed.
                if (unfulfilled > 0 && backupWhId != null) {
                    // Runs only when some quantity remains unfulfilled
                    // and a backup warehouse is available.

                    String backupKey =
                        backupWhId + '_' + item.productId;
                    // Builds the backup warehouse/product lookup key.

                    Inventory__c backupInv = invMap.get(backupKey);
                    // Retrieves the backup inventory record from the Map.

                    if (backupInv != null &&
                        backupInv.Available_Stock__c > 0) {
                        // Continues only if backup inventory exists
                        // and available stock is greater than zero.

                        allocatedFromBackup = Math.min(
                            backupInv.Available_Stock__c,
                            unfulfilled
                        );
                        // Allocates the smaller of backup stock and the
                        // quantity still required.

                        Decimal currentReserved =
                            invReservedStockMap.containsKey(backupInv.Id)
                            ? invReservedStockMap.get(backupInv.Id)
                            : (backupInv.Reserved_Stock__c != null
                                ? backupInv.Reserved_Stock__c
                                : 0);
                        // Gets the latest reserved quantity for backup inventory,
                        // or uses the existing reserved quantity, or zero.

                        Decimal newReserved =
                            currentReserved + allocatedFromBackup;
                        // Calculates the new reserved quantity after backup allocation.

                        invReservedStockMap.put(backupInv.Id, newReserved);
                        // Stores the updated reserved quantity in the Map.

                        unfulfilled -= allocatedFromBackup;
                        // Reduces the remaining quantity by the backup allocation.

                        ledgersToInsert.add(new Inventory_Ledger__c(
                            Inventory__c = backupInv.Id,
                            // Links the ledger entry to the backup inventory record.

                            Type__c = 'Order_Reservation',
                            // Identifies this movement as a reservation.

                            Quantity_Delta__c = allocatedFromBackup,
                            // Records the quantity reserved from backup stock.

                            Reference_Record_Id__c = newOrder.Id,
                            // Links the reservation to the order.

                            Notes__c = 'Order Reservation - Backup Distributor',
                            // Explains that the backup distributor reserved the stock.

                            Timestamp__c = System.now()
                            // Records the reservation timestamp.
                        ));
                        // Adds the backup reservation ledger entry to the list.
                    }
                }

                // STEP 7: Create an order line for the quantity allocated by primary.
                if (allocatedFromPrimary > 0) {

                    linesToInsert.add(new Order_Line__c(
                        Order__c = newOrder.Id,
                        // Links this order line to the order header.

                        Product__c = item.productId,
                        // Specifies the product being ordered.

                        Quantity__c = allocatedFromPrimary,
                        // Stores the quantity allocated from primary stock.

                        Unit_Price__c = item.unitPrice,
                        // Stores the unit price supplied in the request.

                        Fulfilling_Distributor__c =
                            retailer.Primary_Distributor__c,
                        // Assigns the primary distributor to fulfill this line.

                        Fulfillment_Status__c = 'Allocated_Primary'
                        // Identifies the line as allocated from primary stock.
                    ));

                    orderTotal += (
                        allocatedFromPrimary *
                        (item.unitPrice != null ? item.unitPrice : 0)
                    );
                    // Adds the primary allocated quantity multiplied by its unit
                    // price to the order total. A null price is treated as zero.
                }

                // Create an order line for the quantity allocated by backup.
                if (allocatedFromBackup > 0) {

                    linesToInsert.add(new Order_Line__c(
                        Order__c = newOrder.Id,
                        // Links the line to the order header.

                        Product__c = item.productId,
                        // Specifies the product.

                        Quantity__c = allocatedFromBackup,
                        // Stores the quantity allocated from backup stock.

                        Unit_Price__c = item.unitPrice,
                        // Stores the unit price.

                        Fulfilling_Distributor__c =
                            retailer.Backup_Distributor__c,
                        // Assigns the backup distributor to this line.

                        Fulfillment_Status__c = 'Allocated_Backup'
                        // Identifies the line as allocated from backup stock.
                    ));

                    orderTotal += (
                        allocatedFromBackup *
                        (item.unitPrice != null ? item.unitPrice : 0)
                    );
                    // Adds the backup allocation value to the order total.
                }

                // Create an order line for any quantity that could not be allocated.
                if (unfulfilled > 0) {

                    linesToInsert.add(new Order_Line__c(
                        Order__c = newOrder.Id,
                        // Links the backordered line to the order header.

                        Product__c = item.productId,
                        // Specifies the product that is still required.

                        Quantity__c = unfulfilled,
                        // Stores the quantity that could not be allocated.

                        Unit_Price__c = item.unitPrice,
                        // Stores the supplied unit price.

                        Fulfilling_Distributor__c =
                            retailer.Primary_Distributor__c,
                        // Assigns the primary distributor ID to the backordered line.
                        // This does not itself guarantee that the distributor
                        // has stock available.

                        Fulfillment_Status__c = 'Backordered'
                        // Marks the order line as waiting for stock.
                    ));

                    orderTotal += (
                        unfulfilled *
                        (item.unitPrice != null ? item.unitPrice : 0)
                    );
                    // Adds the backordered quantity's value to the order total.
                }

                detail.allocatedQty =
                    allocatedFromPrimary + allocatedFromBackup;
                // Calculates the total quantity allocated across both distributors.

                detail.backorderQty = unfulfilled;
                // Stores the remaining quantity that could not be allocated.

                detail.fulfillmentType = (unfulfilled == 0)
                    ? (allocatedFromBackup > 0
                        ? 'SPLIT_PRIMARY_BACKUP'
                        : 'PRIMARY')
                    : 'PARTIAL_BACKORDER';
                // Determines the overall allocation result.
                // PRIMARY: fulfilled entirely from primary stock.
                // SPLIT_PRIMARY_BACKUP: fulfilled using primary and backup stock.
                // PARTIAL_BACKORDER: some requested quantity remains unallocated.

                response.allocations.add(detail);
                // Adds this product's allocation result to the response.
            }

            // STEP 8: Insert all order lines in one operation.
            if (!linesToInsert.isEmpty()) {
                insert linesToInsert;
                // Saves the allocated and backordered product lines.
                // Bulk DML is more efficient than inserting each line individually.
            }

            // STEP 9: Update the reserved stock quantities.
            if (!invReservedStockMap.isEmpty()) {

                List<Inventory__c> cleanUpdates =
                    new List<Inventory__c>();
                // Creates a list of inventory updates.

                for (Id invId : invReservedStockMap.keySet()) {
                    // Iterates through each inventory record that needs updating.

                    cleanUpdates.add(new Inventory__c(
                        Id = invId,
                        // Identifies the existing inventory record to update.

                        Reserved_Stock__c = invReservedStockMap.get(invId)
                        // Sets its new reserved-stock quantity.
                    ));
                    // Adds the partial inventory record to the update list.
                }

                update cleanUpdates;
                // Saves all reserved-stock changes in one DML operation.
            }

            // STEP 10: Insert inventory ledger records.
            if (!ledgersToInsert.isEmpty()) {
                insert ledgersToInsert;
                // Saves the reservation history for primary and backup inventory.
            }

            // STEP 11: Save the calculated order amount.
            newOrder.Total_Amount__c = orderTotal;
            // Assigns the calculated total to the order header.

            update newOrder;
            // Saves the updated order total in Salesforce.

            // STEP 12: Prepare the successful response.
            response.success = true;
            // Indicates that order processing succeeded.

            response.orderId = newOrder.Id;
            // Returns the ID of the newly created order.

            response.status = 'Submitted';
            // Returns the initial status assigned to the order.

            response.message =
                'Order processed and inventory reserved successfully.';
            // Provides a success message to the caller.

            return response;
            // Returns the order ID, allocation results and success information.

        } catch (Exception ex) {
            // Handles unexpected errors during order processing.

            Database.rollback(sp);
            // Reverts database changes made after the savepoint.
            // This helps prevent a partially created order or reservation.

            response.success = false;
            // Marks the operation as unsuccessful.

            response.message =
                'Order reservation failed: ' + ex.getMessage();
            // Returns the reason for the failure.

            return response;
            // Returns the failure response to the caller.
        }
    }
}
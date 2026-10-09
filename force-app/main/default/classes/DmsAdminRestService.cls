@RestResource(urlMapping='/api/v1/dms/*')
global inherited sharing class DmsAdminRestService {

    global class OverviewStats {
        public Integer distributorCount;
        public Integer warehouseCount;
        public Integer retailerCount;
        public Integer productCount;
        public Decimal totalInventoryUnits;
        public Decimal totalReservedUnits;
        public Decimal totalAvailableUnits;
        public Integer totalOrderCount;
        public Integer pendingFulfillmentCount;
        public List<OrderDTO> recentOrders;
    }

    global class OrderLineDTO {
        public String id;
        public String productId;
        public String productName;
        public String productCode;
        public Decimal quantity;
        public Decimal unitPrice;
        public Decimal lineTotal;
        public String fulfillingDistributorId;
        public String fulfillingDistributorName;
        public String fulfillmentStatus;
    }

    global class OrderDTO {
        public String id;
        public String orderNumber;
        public String retailerId;
        public String retailerName;
        public String retailerShopName;
        public String primaryDistributorId;
        public String primaryDistributorName;
        public String salesExecutiveId;
        public String salesExecutiveName;
        public String status;
        public Decimal totalAmount;
        public String idempotencyKey;
        public Datetime orderDate;
        public List<OrderLineDTO> items;
    }

    global class DistributorDTO {
        public String id;
        public String name;
        public String code;
        public String status;
        public Decimal creditLimit;
        public Decimal currentOutstanding;
        public String defaultWarehouseId;
        public String defaultWarehouseName;
        public String gstin;
    }

    global class WarehouseDTO {
        public String id;
        public String name;
        public String code;
        public String distributorId;
        public String distributorName;
        public String address;
        public Boolean isActive;
    }

    global class RetailerDTO {
        public String id;
        public String name;
        public String code;
        public String shopName;
        public String ownerPhone;
        public String primaryDistributorId;
        public String primaryDistributorName;
        public String backupDistributorId;
        public String backupDistributorName;
        public Boolean allowBackupFulfillment;
        public Decimal creditLimit;
        public Decimal outstandingBalance;
        public Boolean creditHold;
        public Decimal latitude;
        public Decimal longitude;
    }

    global class InventoryDTO {
        public String id;
        public String warehouseId;
        public String warehouseName;
        public String productId;
        public String productName;
        public String productCode;
        public Decimal physicalStock;
        public Decimal reservedStock;
        public Decimal blockedStock;
        public Decimal damagedStock;
        public Decimal expiredStock;
        public Decimal availableStock;
    }

    global class ApiResponse {
        public Boolean success;
        public String message;
        public Object data;
    }

    global class FulfillOrderRequest {
        public String orderId;
    }

    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        if (res == null) res = new RestResponse();
        res.addHeader('Content-Type', 'application/json');

        String uri = (req != null && req.requestURI != null) ? req.requestURI : '';
        ApiResponse apiResp = new ApiResponse();

        try {
            if (uri.endsWith('/overview')) {
                apiResp.data = getOverview();
                apiResp.success = true;
            } else if (uri.endsWith('/distributors')) {
                apiResp.data = getDistributors();
                apiResp.success = true;
            } else if (uri.endsWith('/warehouses')) {
                apiResp.data = getWarehouses();
                apiResp.success = true;
            } else if (uri.endsWith('/retailers')) {
                apiResp.data = getRetailers();
                apiResp.success = true;
            } else if (uri.endsWith('/inventory')) {
                apiResp.data = getInventory();
                apiResp.success = true;
            } else if (uri.endsWith('/orders')) {
                apiResp.data = getOrders();
                apiResp.success = true;
            } else {
                apiResp.success = false;
                apiResp.message = 'Unknown DMS endpoint: ' + uri;
                res.statusCode = 404;
            }
        } catch (Exception ex) {
            apiResp.success = false;
            apiResp.message = 'Error in DMS service: ' + ex.getMessage();
            res.statusCode = 500;
        }

        res.responseBody = Blob.valueOf(JSON.serialize(apiResp));
    }

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        if (res == null) res = new RestResponse();
        res.addHeader('Content-Type', 'application/json');

        String uri = (req != null && req.requestURI != null) ? req.requestURI : '';
        ApiResponse apiResp = new ApiResponse();

        try {
            String jsonBody = (req != null && req.requestBody != null) ? req.requestBody.toString() : '{}';
            if (uri.endsWith('/orders/fulfill')) {
                FulfillOrderRequest fReq = (FulfillOrderRequest) JSON.deserialize(jsonBody, FulfillOrderRequest.class);
                apiResp.data = fulfillOrder(fReq.orderId);
                apiResp.success = true;
                apiResp.message = 'Order successfully dispatched and invoiced.';
            } else {
                apiResp.success = false;
                apiResp.message = 'Unknown action endpoint: ' + uri;
                res.statusCode = 404;
            }
        } catch (Exception ex) {
            apiResp.success = false;
            apiResp.message = 'Fulfillment error: ' + ex.getMessage();
            res.statusCode = 500;
        }

        res.responseBody = Blob.valueOf(JSON.serialize(apiResp));
    }

    public static OverviewStats getOverview() {
        OverviewStats stats = new OverviewStats();
        stats.distributorCount = [SELECT count() FROM Distributor__c];
        stats.warehouseCount = [SELECT count() FROM Warehouse__c];
        stats.retailerCount = [SELECT count() FROM Retailer__c];
        stats.productCount = [SELECT count() FROM Product2 WHERE IsActive = TRUE];
        stats.totalOrderCount = [SELECT count() FROM Order__c];
        stats.pendingFulfillmentCount = [SELECT count() FROM Order__c WHERE Status__c IN ('Submitted', 'Draft', 'Approved')];

        AggregateResult[] stockSums = [
            SELECT SUM(Physical_Stock__c) physicalTotal, SUM(Reserved_Stock__c) reservedTotal, SUM(Available_Stock__c) availableTotal 
            FROM Inventory__c
        ];
        if (!stockSums.isEmpty()) {
            stats.totalInventoryUnits = (Decimal) stockSums[0].get('physicalTotal');
            stats.totalReservedUnits = (Decimal) stockSums[0].get('reservedTotal');
            stats.totalAvailableUnits = (Decimal) stockSums[0].get('availableTotal');
        } else {
            stats.totalInventoryUnits = 0;
            stats.totalReservedUnits = 0;
            stats.totalAvailableUnits = 0;
        }
        stats.recentOrders = getOrders();
        return stats;
    }

    public static List<DistributorDTO> getDistributors() {
        List<DistributorDTO> listDist = new List<DistributorDTO>();
        for (Distributor__c d : [
            SELECT Id, Name, Distributor_Code__c, Status__c, Credit_Limit__c, Current_Outstanding__c,
                   Default_Warehouse__c, Default_Warehouse__r.Name, GSTIN__c
            FROM Distributor__c
            ORDER BY Name ASC
        ]) {
            DistributorDTO dto = new DistributorDTO();
            dto.id = d.Id;
            dto.name = d.Name;
            dto.code = d.Distributor_Code__c;
            dto.status = d.Status__c;
            dto.creditLimit = d.Credit_Limit__c;
            dto.currentOutstanding = d.Current_Outstanding__c;
            dto.defaultWarehouseId = d.Default_Warehouse__c;
            dto.defaultWarehouseName = d.Default_Warehouse__r != null ? d.Default_Warehouse__r.Name : '';
            dto.gstin = d.GSTIN__c;
            listDist.add(dto);
        }
        return listDist;
    }

    public static List<WarehouseDTO> getWarehouses() {
        List<WarehouseDTO> listWh = new List<WarehouseDTO>();
        for (Warehouse__c w : [
            SELECT Id, Name, Warehouse_Code__c, Distributor__c, Distributor__r.Name, Address__c, Is_Active__c
            FROM Warehouse__c
            ORDER BY Name ASC
        ]) {
            WarehouseDTO dto = new WarehouseDTO();
            dto.id = w.Id;
            dto.name = w.Name;
            dto.code = w.Warehouse_Code__c;
            dto.distributorId = w.Distributor__c;
            dto.distributorName = w.Distributor__r != null ? w.Distributor__r.Name : '';
            dto.address = w.Address__c;
            dto.isActive = w.Is_Active__c;
            listWh.add(dto);
        }
        return listWh;
    }

    public static List<RetailerDTO> getRetailers() {
        List<RetailerDTO> listRet = new List<RetailerDTO>();
        for (Retailer__c r : [
            SELECT Id, Name, Retailer_Code__c, Shop_Name__c, Owner_Phone__c,
                   Primary_Distributor__c, Primary_Distributor__r.Name,
                   Backup_Distributor__c, Backup_Distributor__r.Name,
                   Allow_Backup_Fulfillment__c, Credit_Limit__c, Outstanding_Balance__c, Credit_Hold__c,
                   Geolocation__Latitude__s, Geolocation__Longitude__s
            FROM Retailer__c
            ORDER BY Name ASC
        ]) {
            RetailerDTO dto = new RetailerDTO();
            dto.id = r.Id;
            dto.name = r.Name;
            dto.code = r.Retailer_Code__c;
            dto.shopName = r.Shop_Name__c;
            dto.ownerPhone = r.Owner_Phone__c;
            dto.primaryDistributorId = r.Primary_Distributor__c;
            dto.primaryDistributorName = r.Primary_Distributor__r != null ? r.Primary_Distributor__r.Name : '';
            dto.backupDistributorId = r.Backup_Distributor__c;
            dto.backupDistributorName = r.Backup_Distributor__r != null ? r.Backup_Distributor__r.Name : '';
            dto.allowBackupFulfillment = r.Allow_Backup_Fulfillment__c;
            dto.creditLimit = r.Credit_Limit__c;
            dto.outstandingBalance = r.Outstanding_Balance__c;
            dto.creditHold = r.Credit_Hold__c;
            dto.latitude = r.Geolocation__Latitude__s;
            dto.longitude = r.Geolocation__Longitude__s;
            listRet.add(dto);
        }
        return listRet;
    }

    public static List<InventoryDTO> getInventory() {
        List<InventoryDTO> listInv = new List<InventoryDTO>();
        for (Inventory__c i : [
            SELECT Id, Warehouse__c, Warehouse__r.Name, Product__c, Product__r.Name, Product__r.ProductCode,
                   Physical_Stock__c, Reserved_Stock__c, Blocked_Stock__c, Damaged_Stock__c, Expired_Stock__c, Available_Stock__c
            FROM Inventory__c
            ORDER BY Warehouse__r.Name, Product__r.Name
        ]) {
            InventoryDTO dto = new InventoryDTO();
            dto.id = i.Id;
            dto.warehouseId = i.Warehouse__c;
            dto.warehouseName = i.Warehouse__r != null ? i.Warehouse__r.Name : '';
            dto.productId = i.Product__c;
            dto.productName = i.Product__r != null ? i.Product__r.Name : '';
            dto.productCode = i.Product__r != null ? i.Product__r.ProductCode : '';
            dto.physicalStock = i.Physical_Stock__c;
            dto.reservedStock = i.Reserved_Stock__c;
            dto.blockedStock = i.Blocked_Stock__c;
            dto.damagedStock = i.Damaged_Stock__c;
            dto.expiredStock = i.Expired_Stock__c;
            dto.availableStock = i.Available_Stock__c;
            listInv.add(dto);
        }
        return listInv;
    }

    public static List<OrderDTO> getOrders() {
        List<OrderDTO> listOrd = new List<OrderDTO>();
        List<Order__c> ords = [
            SELECT Id, Name, Order_Date__c, Retailer__c, Retailer__r.Name, Retailer__r.Shop_Name__c,
                   Primary_Distributor__c, Primary_Distributor__r.Name, Sales_Executive__c, Sales_Executive__r.Name,
                   Status__c, Total_Amount__c, Idempotency_Key__c,
                   (SELECT Id, Product__c, Product__r.Name, Product__r.ProductCode, Quantity__c, Unit_Price__c, Line_Total__c,
                           Fulfilling_Distributor__c, Fulfilling_Distributor__r.Name, Fulfillment_Status__c
                    FROM Order_Lines__r)
            FROM Order__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        for (Order__c o : ords) {
            OrderDTO dto = new OrderDTO();
            dto.id = o.Id;
            dto.orderNumber = o.Name;
            dto.retailerId = o.Retailer__c;
            dto.retailerName = o.Retailer__r != null ? o.Retailer__r.Name : '';
            dto.retailerShopName = o.Retailer__r != null ? o.Retailer__r.Shop_Name__c : '';
            dto.primaryDistributorId = o.Primary_Distributor__c;
            dto.primaryDistributorName = o.Primary_Distributor__r != null ? o.Primary_Distributor__r.Name : '';
            dto.salesExecutiveId = o.Sales_Executive__c;
            dto.salesExecutiveName = o.Sales_Executive__r != null ? o.Sales_Executive__r.Name : 'Executive';
            dto.status = o.Status__c;
            dto.totalAmount = o.Total_Amount__c;
            dto.idempotencyKey = o.Idempotency_Key__c;
            dto.orderDate = o.Order_Date__c;
            dto.items = new List<OrderLineDTO>();

            if (o.Order_Lines__r != null) {
                for (Order_Line__c l : o.Order_Lines__r) {
                    OrderLineDTO lDto = new OrderLineDTO();
                    lDto.id = l.Id;
                    lDto.productId = l.Product__c;
                    lDto.productName = l.Product__r != null ? l.Product__r.Name : '';
                    lDto.productCode = l.Product__r != null ? l.Product__r.ProductCode : '';
                    lDto.quantity = l.Quantity__c;
                    lDto.unitPrice = l.Unit_Price__c;
                    lDto.lineTotal = l.Line_Total__c;
                    lDto.fulfillingDistributorId = l.Fulfilling_Distributor__c;
                    lDto.fulfillingDistributorName = l.Fulfilling_Distributor__r != null ? l.Fulfilling_Distributor__r.Name : '';
                    lDto.fulfillmentStatus = l.Fulfillment_Status__c;
                    dto.items.add(lDto);
                }
            }
            listOrd.add(dto);
        }
        return listOrd;
    }

    public static Object fulfillOrder(String orderId) {
        Order__c ord = [
            SELECT Id, Name, Status__c, Total_Amount__c, Retailer__c,
                   (SELECT Id, Product__c, Quantity__c, Unit_Price__c, Fulfilling_Distributor__c, Fulfillment_Status__c 
                    FROM Order_Lines__r)
            FROM Order__c
            WHERE Id = :orderId
            LIMIT 1
        ];

        // 1. Deduct Reserved & Physical Stock from respective Warehouses
        Set<Id> distIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        for (Order_Line__c line : ord.Order_Lines__r) {
            if (line.Fulfilling_Distributor__c != null) distIds.add(line.Fulfilling_Distributor__c);
            prodIds.add(line.Product__c);
        }

        Map<Id, Distributor__c> distMap = new Map<Id, Distributor__c>([
            SELECT Id, Default_Warehouse__c FROM Distributor__c WHERE Id IN :distIds
        ]);

        Set<Id> whIds = new Set<Id>();
        for (Distributor__c d : distMap.values()) {
            if (d.Default_Warehouse__c != null) whIds.add(d.Default_Warehouse__c);
        }

        List<Inventory__c> invs = [
            SELECT Id, Warehouse__c, Product__c, Physical_Stock__c, Reserved_Stock__c, Blocked_Stock__c, Damaged_Stock__c, Expired_Stock__c
            FROM Inventory__c
            WHERE Warehouse__c IN :whIds AND Product__c IN :prodIds
            FOR UPDATE
        ];

        Map<String, Inventory__c> invMap = new Map<String, Inventory__c>();
        for (Inventory__c i : invs) {
            invMap.put(i.Warehouse__c + '_' + i.Product__c, i);
        }

        List<Inventory__c> invsToUpdate = new List<Inventory__c>();
        List<Inventory_Ledger__c> ledgers = new List<Inventory_Ledger__c>();

        for (Order_Line__c line : ord.Order_Lines__r) {
            if (line.Fulfilling_Distributor__c != null && distMap.containsKey(line.Fulfilling_Distributor__c)) {
                Id whId = distMap.get(line.Fulfilling_Distributor__c).Default_Warehouse__c;
                String key = whId + '_' + line.Product__c;
                if (invMap.containsKey(key)) {
                    Inventory__c inv = invMap.get(key);
                    Decimal qty = line.Quantity__c != null ? line.Quantity__c : 0;
                    inv.Reserved_Stock__c = Math.max(0, (inv.Reserved_Stock__c != null ? inv.Reserved_Stock__c : 0) - qty);
                    inv.Physical_Stock__c = Math.max(0, (inv.Physical_Stock__c != null ? inv.Physical_Stock__c : 0) - qty);
                    invsToUpdate.add(inv);

                    Inventory_Ledger__c led = new Inventory_Ledger__c(
                        Inventory__c = inv.Id,
                        Type__c = 'Order_Dispatch',
                        Quantity_Delta__c = -qty,
                        Reference_Record_Id__c = ord.Id,
                        Timestamp__c = System.now(),
                        Notes__c = 'Dispatched for Order ' + ord.Name
                    );
                    ledgers.add(led);
                }
            }
        }

        if (!invsToUpdate.isEmpty()) {
            update invsToUpdate;
        }
        if (!ledgers.isEmpty()) {
            insert ledgers;
        }

        // 2. Generate Invoice
        Invoice__c invRecord = new Invoice__c(
            Order__c = ord.Id,
            Invoice_Amount__c = ord.Total_Amount__c,
            Invoice_Date__c = Date.today(),
            Invoice_Number__c = 'INV-' + ord.Name,
            Status__c = 'Paid'
        );
        insert invRecord;

        // 3. Update Order Status to Dispatched
        ord.Status__c = 'Dispatched';
        update ord;

        return new Map<String, Object>{
            'orderId' => ord.Id,
            'status' => ord.Status__c,
            'invoiceId' => invRecord.Id,
            'invoiceNumber' => invRecord.Invoice_Number__c
        };
    }
}

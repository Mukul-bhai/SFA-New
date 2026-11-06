@RestResource(urlMapping='/api/v1/dms/*')
// Exposes this Apex class as a REST API.
// The * allows different endpoints, such as /overview, /orders and /inventory.
global inherited sharing class DmsAdminRestService {

    // DTO means Data Transfer Object.
    // This class defines the dashboard statistics returned to the React admin website.
    global class OverviewStats {
        public Integer distributorCount;       // Total number of distributors.
        public Integer warehouseCount;         // Total number of warehouses.
        public Integer retailerCount;          // Total number of retailers.
        public Integer productCount;           // Total number of active products.
        public Decimal totalInventoryUnits;    // Total physical stock across inventory.
        public Decimal totalReservedUnits;     // Total stock reserved for orders.
        public Decimal totalAvailableUnits;    // Total available stock.
        public Integer totalOrderCount;        // Total number of orders.
        public Integer pendingFulfillmentCount;// Orders waiting for fulfillment.
        public List<OrderDTO> recentOrders;    // List of recent orders shown on the dashboard.
    }

    // Holds the details of one product line inside an order.
    global class OrderLineDTO {
        public String id;                      // Salesforce Order Line record ID.
        public String productId;               // ID of the product.
        public String productName;             // Name of the product.
        public String productCode;             // Product code.
        public Decimal quantity;               // Quantity ordered.
        public Decimal unitPrice;              // Price of one unit.
        public Decimal lineTotal;              // Total price for this order line.
        public String fulfillingDistributorId;  // Distributor responsible for fulfilling this line.
        public String fulfillingDistributorName;// Name of that distributor.
        public String fulfillmentStatus;        // Current fulfillment status of this line.
    }

    // Holds the complete order information, including its products.
    global class OrderDTO {
        public String id;                      // Salesforce Order record ID.
        public String orderNumber;              // Order number.
        public String retailerId;               // ID of the retailer who placed the order.
        public String retailerName;             // Retailer's name.
        public String retailerShopName;         // Retailer's shop name.
        public String primaryDistributorId;     // ID of the primary distributor.
        public String primaryDistributorName;   // Name of the primary distributor.
        public String salesExecutiveId;         // ID of the sales executive.
        public String salesExecutiveName;       // Name of the sales executive.
        public String status;                   // Current order status.
        public Decimal totalAmount;              // Total order amount.
        public String idempotencyKey;            // Key used to identify a repeated request/order.
        public Datetime orderDate;               // Date and time associated with the order.
        public List<OrderLineDTO> items;         // Products included in the order.
    }

    // Defines the distributor information sent to the frontend.
    global class DistributorDTO {
        public String id;                       // Distributor record ID.
        public String name;                     // Distributor name.
        public String code;                     // Distributor code.
        public String status;                   // Active/inactive or configured status.
        public Decimal creditLimit;              // Maximum permitted credit.
        public Decimal currentOutstanding;       // Current outstanding amount.
        public String defaultWarehouseId;        // ID of the default warehouse.
        public String defaultWarehouseName;      // Name of the default warehouse.
        public String gstin;                     // Distributor GSTIN.
    }

    // Defines the warehouse information sent to the frontend.
    global class WarehouseDTO {
        public String id;                       // Warehouse record ID.
        public String name;                     // Warehouse name.
        public String code;                     // Warehouse code.
        public String distributorId;             // ID of the associated distributor.
        public String distributorName;           // Name of the associated distributor.
        public String address;                   // Warehouse address.
        public Boolean isActive;                 // Whether the warehouse is active.
    }

    // Defines the retailer information sent to the frontend.
    global class RetailerDTO {
        public String id;                       // Retailer record ID.
        public String name;                     // Retailer name.
        public String code;                     // Retailer code.
        public String shopName;                 // Name of the retailer's shop.
        public String ownerPhone;               // Shop owner's phone number.
        public String primaryDistributorId;      // Primary distributor's ID.
        public String primaryDistributorName;    // Primary distributor's name.
        public String backupDistributorId;       // Backup distributor's ID.
        public String backupDistributorName;     // Backup distributor's name.
        public Boolean allowBackupFulfillment;   // Whether backup fulfillment is allowed.
        public Decimal creditLimit;              // Retailer's credit limit.
        public Decimal outstandingBalance;       // Retailer's outstanding balance.
        public Boolean creditHold;               // Whether the retailer is on credit hold.
        public Decimal latitude;                 // Retailer's geographical latitude.
        public Decimal longitude;                // Retailer's geographical longitude.
    }

    // Defines inventory information for a product in a warehouse.
    global class InventoryDTO {
        public String id;                       // Inventory record ID.
        public String warehouseId;               // Warehouse ID.
        public String warehouseName;             // Warehouse name.
        public String productId;                 // Product ID.
        public String productName;               // Product name.
        public String productCode;               // Product code.
        public Decimal physicalStock;            // Physical stock quantity.
        public Decimal reservedStock;            // Stock reserved for orders.
        public Decimal blockedStock;             // Stock blocked from normal use.
        public Decimal damagedStock;             // Damaged stock quantity.
        public Decimal expiredStock;             // Expired stock quantity.
        public Decimal availableStock;            // Available stock quantity.
    }

    // Standard response structure used by the REST API.
    // The frontend receives success, message and data in the JSON response.
    global class ApiResponse {
        public Boolean success;                 // Indicates whether the request succeeded.
        public String message;                  // Response or error message.
        public Object data;                     // Actual result returned by the endpoint.
    }

    // Defines the JSON body expected when requesting order fulfillment.
    global class FulfillOrderRequest {
        public String orderId;                  // ID of the order to fulfill.
    }

    // Handles HTTP GET requests.
    // GET is used to retrieve information without intentionally changing records.
    @HttpGet
    global static void doGet() {

        RestRequest req = RestContext.request;  // Gets the incoming HTTP request.
        RestResponse res = RestContext.response;// Gets the outgoing HTTP response.

        if (res == null) {
            res = new RestResponse();           // Creates a response if one is unavailable.
        }

        res.addHeader('Content-Type', 'application/json');
        // Tells the client that the response body contains JSON.

        String uri = (req != null && req.requestURI != null)
            ? req.requestURI
            : '';
        // Gets the requested URL. If it is missing, uses an empty string.

        ApiResponse apiResp = new ApiResponse();
        // Creates the common response object.

        try {
            // Selects the method to execute according to the requested endpoint.

            if (uri.endsWith('/overview')) {
                apiResp.data = getOverview();       // Gets dashboard statistics.
                apiResp.success = true;

            } else if (uri.endsWith('/distributors')) {
                apiResp.data = getDistributors();   // Gets distributor records.
                apiResp.success = true;

            } else if (uri.endsWith('/warehouses')) {
                apiResp.data = getWarehouses();     // Gets warehouse records.
                apiResp.success = true;

            } else if (uri.endsWith('/retailers')) {
                apiResp.data = getRetailers();      // Gets retailer records.
                apiResp.success = true;

            } else if (uri.endsWith('/inventory')) {
                apiResp.data = getInventory();      // Gets inventory records.
                apiResp.success = true;

            } else if (uri.endsWith('/orders')) {
                apiResp.data = getOrders();         // Gets order records.
                apiResp.success = true;

            } else {
                // This block runs when the URL does not match a supported endpoint.
                apiResp.success = false;
                apiResp.message = 'Unknown DMS endpoint: ' + uri;
                res.statusCode = 404;               // HTTP 404 means endpoint not found.
            }

        } catch (Exception ex) {
            // Handles unexpected errors raised while processing the request.
            apiResp.success = false;
            apiResp.message = 'Error in DMS service: ' + ex.getMessage();
            res.statusCode = 500;                   // HTTP 500 means server-side error.
        }

        res.responseBody = Blob.valueOf(JSON.serialize(apiResp));
        // Converts the response object to JSON and writes it to the HTTP response.
    }

    // Handles HTTP POST requests.
    // POST is used here to perform the order fulfillment action.
    @HttpPost
    global static void doPost() {

        RestRequest req = RestContext.request;      // Gets the incoming request.
        RestResponse res = RestContext.response;    // Gets the outgoing response.

        if (res == null) {
            res = new RestResponse();               // Creates a response if needed.
        }

        res.addHeader('Content-Type', 'application/json');
        // Specifies that the response will be JSON.

        String uri = (req != null && req.requestURI != null)
            ? req.requestURI
            : '';
        // Gets the requested endpoint URL.

        ApiResponse apiResp = new ApiResponse();
        // Creates the standard API response object.

        try {
            String jsonBody = (req != null && req.requestBody != null)
                ? req.requestBody.toString()
                : '{}';
            // Reads the incoming JSON body. Uses an empty JSON object if absent.

            if (uri.endsWith('/orders/fulfill')) {
                // Processes the request only when the fulfillment endpoint is called.

                FulfillOrderRequest fReq =
                    (FulfillOrderRequest) JSON.deserialize(
                        jsonBody,
                        FulfillOrderRequest.class
                    );
                // Converts the JSON request body into an Apex object.
                // Example request: {"orderId":"a01XXXXXXXXXXXXXXX"}.

                apiResp.data = fulfillOrder(fReq.orderId);
                // Calls the fulfillment method using the supplied order ID.

                apiResp.success = true;
                apiResp.message = 'Order successfully dispatched and invoiced.';

            } else {
                // Handles unsupported POST endpoints.
                apiResp.success = false;
                apiResp.message = 'Unknown action endpoint: ' + uri;
                res.statusCode = 404;
            }

        } catch (Exception ex) {
            // Returns an error response if fulfillment or JSON processing fails.
            apiResp.success = false;
            apiResp.message = 'Fulfillment error: ' + ex.getMessage();
            res.statusCode = 500;
        }

        res.responseBody = Blob.valueOf(JSON.serialize(apiResp));
        // Serializes the response object into JSON for the client.
    }

    // Creates the summary data displayed on the DMS admin dashboard.
    public static OverviewStats getOverview() {

        OverviewStats stats = new OverviewStats();
        // Creates an object that will hold the dashboard statistics.

        stats.distributorCount = [SELECT count() FROM Distributor__c];
        // Counts all Distributor__c records.

        stats.warehouseCount = [SELECT count() FROM Warehouse__c];
        // Counts all Warehouse__c records.

        stats.retailerCount = [SELECT count() FROM Retailer__c];
        // Counts all Retailer__c records.

        stats.productCount = [
            SELECT count()
            FROM Product2
            WHERE IsActive = TRUE
        ];
        // Counts only active products from the standard Salesforce Product2 object.

        stats.totalOrderCount = [SELECT count() FROM Order__c];
        // Counts all DMS order records.

        stats.pendingFulfillmentCount = [
            SELECT count()
            FROM Order__c
            WHERE Status__c IN ('Submitted', 'Draft', 'Approved')
        ];
        // Counts orders whose status is Draft, Submitted or Approved.

        AggregateResult[] stockSums = [
            SELECT
                SUM(Physical_Stock__c) physicalTotal,
                SUM(Reserved_Stock__c) reservedTotal,
                SUM(Available_Stock__c) availableTotal
            FROM Inventory__c
        ];
        // Aggregate queries calculate totals without retrieving every inventory record.
        // Each SUM result is returned in an AggregateResult object.

        if (!stockSums.isEmpty()) {
            // Reads the aggregate totals when a result is available.
            stats.totalInventoryUnits =
                (Decimal) stockSums[0].get('physicalTotal');

            stats.totalReservedUnits =
                (Decimal) stockSums[0].get('reservedTotal');

            stats.totalAvailableUnits =
                (Decimal) stockSums[0].get('availableTotal');

        } else {
            // Uses zero as the default when no aggregate result is available.
            stats.totalInventoryUnits = 0;
            stats.totalReservedUnits = 0;
            stats.totalAvailableUnits = 0;
        }

        stats.recentOrders = getOrders();
        // Adds the recent orders returned by getOrders() to the dashboard data.

        return stats;
        // Returns all dashboard statistics to the caller.
    }

    // Retrieves distributors and converts Salesforce records into DistributorDTO objects.
    public static List<DistributorDTO> getDistributors() {

        List<DistributorDTO> listDist = new List<DistributorDTO>();
        // Creates an empty list for the distributor response.

        for (Distributor__c d : [
            SELECT Id, Name, Distributor_Code__c, Status__c,
                   Credit_Limit__c, Current_Outstanding__c,
                   Default_Warehouse__c, Default_Warehouse__r.Name, GSTIN__c
            FROM Distributor__c
            ORDER BY Name ASC
        ]) {
            // Queries distributor records and processes them one by one.
            // ORDER BY Name ASC sorts the results alphabetically.

            DistributorDTO dto = new DistributorDTO();
            // Creates the response object for the current distributor.

            dto.id = d.Id;                         // Copies the record ID.
            dto.name = d.Name;                     // Copies the distributor name.
            dto.code = d.Distributor_Code__c;      // Copies the distributor code.
            dto.status = d.Status__c;              // Copies the distributor status.
            dto.creditLimit = d.Credit_Limit__c;   // Copies the credit limit.
            dto.currentOutstanding = d.Current_Outstanding__c;
            // Copies the current outstanding balance.

            dto.defaultWarehouseId = d.Default_Warehouse__c;
            // Copies the related warehouse ID.

            dto.defaultWarehouseName =
                d.Default_Warehouse__r != null
                ? d.Default_Warehouse__r.Name
                : '';
            // Reads the warehouse name if the relationship exists.
            // The ternary operator prevents a null relationship access.

            dto.gstin = d.GSTIN__c;                // Copies the GSTIN.

            listDist.add(dto);
            // Adds the converted distributor to the response list.
        }

        return listDist;
        // Returns the complete list of distributors.
    }

    // Retrieves warehouses and converts them into WarehouseDTO objects.
    public static List<WarehouseDTO> getWarehouses() {

        List<WarehouseDTO> listWh = new List<WarehouseDTO>();
        // Creates an empty list to hold warehouse response objects.

        for (Warehouse__c w : [
            SELECT Id, Name, Warehouse_Code__c, Distributor__c,
                   Distributor__r.Name, Address__c, Is_Active__c
            FROM Warehouse__c
            ORDER BY Name ASC
        ]) {
            // Retrieves warehouses, including the related distributor's name.

            WarehouseDTO dto = new WarehouseDTO();
            // Creates a DTO for the current warehouse.

            dto.id = w.Id;                         // Warehouse record ID.
            dto.name = w.Name;                     // Warehouse name.
            dto.code = w.Warehouse_Code__c;        // Warehouse code.
            dto.distributorId = w.Distributor__c;  // Related distributor ID.

            dto.distributorName =
                w.Distributor__r != null
                ? w.Distributor__r.Name
                : '';
            // Returns the distributor name when the relationship is populated.

            dto.address = w.Address__c;            // Warehouse address.
            dto.isActive = w.Is_Active__c;          // Active/inactive indicator.

            listWh.add(dto);
            // Adds this warehouse to the response list.
        }

        return listWh;
        // Returns all queried warehouses.
    }

    // Retrieves retailers with their distributor, credit and location details.
    public static List<RetailerDTO> getRetailers() {

        List<RetailerDTO> listRet = new List<RetailerDTO>();
        // Creates an empty list for retailer response objects.

        for (Retailer__c r : [
            SELECT Id, Name, Retailer_Code__c, Shop_Name__c, Owner_Phone__c,
                   Primary_Distributor__c, Primary_Distributor__r.Name,
                   Backup_Distributor__c, Backup_Distributor__r.Name,
                   Allow_Backup_Fulfillment__c, Credit_Limit__c,
                   Outstanding_Balance__c, Credit_Hold__c,
                   Geolocation__Latitude__s, Geolocation__Longitude__s
            FROM Retailer__c
            ORDER BY Name ASC
        ]) {
            // Queries retailer fields, including geolocation coordinates.

            RetailerDTO dto = new RetailerDTO();
            // Creates a DTO to hold the current retailer's details.

            dto.id = r.Id;                         // Retailer record ID.
            dto.name = r.Name;                     // Retailer name.
            dto.code = r.Retailer_Code__c;         // Retailer code.
            dto.shopName = r.Shop_Name__c;         // Shop name.
            dto.ownerPhone = r.Owner_Phone__c;     // Owner's phone number.

            dto.primaryDistributorId = r.Primary_Distributor__c;
            // Stores the primary distributor's record ID.

            dto.primaryDistributorName =
                r.Primary_Distributor__r != null
                ? r.Primary_Distributor__r.Name
                : '';
            // Stores the primary distributor name when available.

            dto.backupDistributorId = r.Backup_Distributor__c;
            // Stores the backup distributor's record ID.

            dto.backupDistributorName =
                r.Backup_Distributor__r != null
                ? r.Backup_Distributor__r.Name
                : '';
            // Stores the backup distributor name when available.

            dto.allowBackupFulfillment = r.Allow_Backup_Fulfillment__c;
            // Indicates whether orders can be fulfilled by a backup distributor.

            dto.creditLimit = r.Credit_Limit__c;   // Retailer's credit limit.
            dto.outstandingBalance = r.Outstanding_Balance__c;
            // Retailer's outstanding balance.

            dto.creditHold = r.Credit_Hold__c;
            // Indicates whether the retailer is on credit hold.

            dto.latitude = r.Geolocation__Latitude__s;
            // Copies the retailer's latitude.

            dto.longitude = r.Geolocation__Longitude__s;
            // Copies the retailer's longitude.

            listRet.add(dto);
            // Adds the current retailer to the response list.
        }

        return listRet;
        // Returns all retailer DTOs.
    }

    // Retrieves inventory records with their product and warehouse details.
    public static List<InventoryDTO> getInventory() {

        List<InventoryDTO> listInv = new List<InventoryDTO>();
        // Creates an empty list for inventory response objects.

        for (Inventory__c i : [
            SELECT Id, Warehouse__c, Warehouse__r.Name,
                   Product__c, Product__r.Name, Product__r.ProductCode,
                   Physical_Stock__c, Reserved_Stock__c, Blocked_Stock__c,
                   Damaged_Stock__c, Expired_Stock__c, Available_Stock__c
            FROM Inventory__c
            ORDER BY Warehouse__r.Name, Product__r.Name
        ]) {
            // Retrieves inventory records and sorts them by warehouse and product.

            InventoryDTO dto = new InventoryDTO();
            // Creates a DTO for the current inventory record.

            dto.id = i.Id;                         // Inventory record ID.
            dto.warehouseId = i.Warehouse__c;      // Warehouse ID.

            dto.warehouseName =
                i.Warehouse__r != null
                ? i.Warehouse__r.Name
                : '';
            // Gets the warehouse name if the relationship exists.

            dto.productId = i.Product__c;          // Product ID.

            dto.productName =
                i.Product__r != null
                ? i.Product__r.Name
                : '';
            // Gets the product name if the relationship exists.

            dto.productCode =
                i.Product__r != null
                ? i.Product__r.ProductCode
                : '';
            // Gets the product code if the relationship exists.

            dto.physicalStock = i.Physical_Stock__c;
            // Copies the total physical stock.

            dto.reservedStock = i.Reserved_Stock__c;
            // Copies the stock reserved for orders.

            dto.blockedStock = i.Blocked_Stock__c;
            // Copies the stock blocked from normal availability.

            dto.damagedStock = i.Damaged_Stock__c;
            // Copies the damaged stock quantity.

            dto.expiredStock = i.Expired_Stock__c;
            // Copies the expired stock quantity.

            dto.availableStock = i.Available_Stock__c;
            // Copies the available stock quantity.

            listInv.add(dto);
            // Adds the current inventory DTO to the response list.
        }

        return listInv;
        // Returns all inventory records.
    }

    // Retrieves the latest 50 orders and includes their order-line details.
    public static List<OrderDTO> getOrders() {

        List<OrderDTO> listOrd = new List<OrderDTO>();
        // Creates an empty list for the order response.

        List<Order__c> ords = [
            SELECT Id, Name, Order_Date__c,
                   Retailer__c, Retailer__r.Name, Retailer__r.Shop_Name__c,
                   Primary_Distributor__c, Primary_Distributor__r.Name,
                   Sales_Executive__c, Sales_Executive__r.Name,
                   Status__c, Total_Amount__c, Idempotency_Key__c,
                   (
                       SELECT Id, Product__c, Product__r.Name,
                              Product__r.ProductCode, Quantity__c,
                              Unit_Price__c, Line_Total__c,
                              Fulfilling_Distributor__c,
                              Fulfilling_Distributor__r.Name,
                              Fulfillment_Status__c
                       FROM Order_Lines__r
                   )
            FROM Order__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
        // The subquery retrieves related order lines for each order.
        // CreatedDate DESC puts the newest orders first.
        // LIMIT 50 restricts the result to the latest 50 orders.

        for (Order__c o : ords) {
            // Converts each Salesforce order record into an OrderDTO.

            OrderDTO dto = new OrderDTO();
            // Creates the response object for the current order.

            dto.id = o.Id;                         // Order record ID.
            dto.orderNumber = o.Name;              // Order number.
            dto.retailerId = o.Retailer__c;        // Retailer ID.

            dto.retailerName =
                o.Retailer__r != null ? o.Retailer__r.Name : '';
            // Gets the retailer name when the relationship exists.

            dto.retailerShopName =
                o.Retailer__r != null ? o.Retailer__r.Shop_Name__c : '';
            // Gets the retailer's shop name when available.

            dto.primaryDistributorId = o.Primary_Distributor__c;
            // Stores the primary distributor ID.

            dto.primaryDistributorName =
                o.Primary_Distributor__r != null
                ? o.Primary_Distributor__r.Name
                : '';
            // Gets the primary distributor's name.

            dto.salesExecutiveId = o.Sales_Executive__c;
            // Stores the sales executive's ID.

            dto.salesExecutiveName =
                o.Sales_Executive__r != null
                ? o.Sales_Executive__r.Name
                : 'Executive';
            // Uses the related executive's name or a fallback label.

            dto.status = o.Status__c;              // Order status.
            dto.totalAmount = o.Total_Amount__c;   // Total order amount.
            dto.idempotencyKey = o.Idempotency_Key__c;
            // Copies the key associated with the order.

            dto.orderDate = o.Order_Date__c;       // Order date.

            dto.items = new List<OrderLineDTO>();
            // Initializes the list that will contain this order's products.

            if (o.Order_Lines__r != null) {
                // Checks whether related order lines are available.

                for (Order_Line__c l : o.Order_Lines__r) {
                    // Processes each product line belonging to this order.

                    OrderLineDTO lDto = new OrderLineDTO();
                    // Creates a response object for the current order line.

                    lDto.id = l.Id;                 // Order-line record ID.
                    lDto.productId = l.Product__c;  // Product ID.

                    lDto.productName =
                        l.Product__r != null ? l.Product__r.Name : '';
                    // Gets the product name when available.

                    lDto.productCode =
                        l.Product__r != null ? l.Product__r.ProductCode : '';
                    // Gets the product code when available.

                    lDto.quantity = l.Quantity__c;  // Ordered quantity.
                    lDto.unitPrice = l.Unit_Price__c;
                    // Price of one unit.

                    lDto.lineTotal = l.Line_Total__c;
                    // Total amount for this order line.

                    lDto.fulfillingDistributorId = l.Fulfilling_Distributor__c;
                    // Distributor assigned to fulfill this line.

                    lDto.fulfillingDistributorName =
                        l.Fulfilling_Distributor__r != null
                        ? l.Fulfilling_Distributor__r.Name
                        : '';
                    // Gets the assigned distributor's name.

                    lDto.fulfillmentStatus = l.Fulfillment_Status__c;
                    // Copies the order-line fulfillment status.

                    dto.items.add(lDto);
                    // Adds the current product line to this order's items.
                }
            }

            listOrd.add(dto);
            // Adds the completed order DTO to the final list.
        }

        return listOrd;
        // Returns the orders and their associated product lines.
    }

    // Processes an order fulfillment request.
    // This method deducts stock, creates inventory ledger entries,
    // creates an invoice, and changes the order status.
    public static Object fulfillOrder(String orderId) {

        Order__c ord = [
            SELECT Id, Name, Status__c, Total_Amount__c, Retailer__c,
                   (
                       SELECT Id, Product__c, Quantity__c, Unit_Price__c,
                              Fulfilling_Distributor__c, Fulfillment_Status__c
                       FROM Order_Lines__r
                   )
            FROM Order__c
            WHERE Id = :orderId
            LIMIT 1
        ];
        // Finds the order matching the supplied ID and retrieves its order lines.
        // If no matching order exists, this query can throw an exception.

        // STEP 1: Collect the distributor IDs and product IDs used by the order.
        Set<Id> distIds = new Set<Id>();
        // A Set stores unique distributor IDs, avoiding duplicates.

        Set<Id> prodIds = new Set<Id>();
        // Stores unique product IDs included in the order.

        for (Order_Line__c line : ord.Order_Lines__r) {
            // Goes through every order line.

            if (line.Fulfilling_Distributor__c != null) {
                distIds.add(line.Fulfilling_Distributor__c);
                // Adds the assigned distributor ID when it is not null.
            }

            prodIds.add(line.Product__c);
            // Adds the product ID for inventory lookup.
        }

        Map<Id, Distributor__c> distMap = new Map<Id, Distributor__c>([
            SELECT Id, Default_Warehouse__c
            FROM Distributor__c
            WHERE Id IN :distIds
        ]);
        // Retrieves distributors and their default warehouses.
        // The Map lets the code find a distributor quickly using its ID.

        Set<Id> whIds = new Set<Id>();
        // Creates a set to store warehouse IDs.

        for (Distributor__c d : distMap.values()) {
            // Iterates through the distributors retrieved above.

            if (d.Default_Warehouse__c != null) {
                whIds.add(d.Default_Warehouse__c);
                // Adds the default warehouse ID when it exists.
            }
        }

        List<Inventory__c> invs = [
            SELECT Id, Warehouse__c, Product__c,
                   Physical_Stock__c, Reserved_Stock__c,
                   Blocked_Stock__c, Damaged_Stock__c, Expired_Stock__c
            FROM Inventory__c
            WHERE Warehouse__c IN :whIds
              AND Product__c IN :prodIds
            FOR UPDATE
        ];
        // Retrieves inventory records for the relevant warehouses and products.
        // FOR UPDATE locks the selected records while the transaction processes them,
        // helping prevent concurrent transactions from modifying the same inventory.

        Map<String, Inventory__c> invMap = new Map<String, Inventory__c>();
        // Creates a map to find inventory using a combined warehouse/product key.

        for (Inventory__c i : invs) {
            // Processes each matching inventory record.

            invMap.put(i.Warehouse__c + '_' + i.Product__c, i);
            // Example key: warehouseId_productId.
            // This identifies inventory for a specific product in a specific warehouse.
        }

        List<Inventory__c> invsToUpdate = new List<Inventory__c>();
        // Stores changed inventory records for one bulk update.

        List<Inventory_Ledger__c> ledgers = new List<Inventory_Ledger__c>();
        // Stores inventory history records for one bulk insert.

        for (Order_Line__c line : ord.Order_Lines__r) {
            // Processes every product line to deduct its stock.

            if (line.Fulfilling_Distributor__c != null
                && distMap.containsKey(line.Fulfilling_Distributor__c)) {
                // Continues only if the order line has a distributor found in the map.

                Id whId =
                    distMap.get(line.Fulfilling_Distributor__c).Default_Warehouse__c;
                // Gets that distributor's default warehouse ID.

                String key = whId + '_' + line.Product__c;
                // Builds the key used to find the matching inventory record.

                if (invMap.containsKey(key)) {
                    // Checks whether inventory exists for this warehouse and product.

                    Inventory__c inv = invMap.get(key);
                    // Gets the inventory record that must be updated.

                    Decimal qty = line.Quantity__c != null
                        ? line.Quantity__c
                        : 0;
                    // Uses the order quantity, or zero if the quantity is null.

                    inv.Reserved_Stock__c = Math.max(
                        0,
                        (inv.Reserved_Stock__c != null
                            ? inv.Reserved_Stock__c
                            : 0) - qty
                    );
                    // Subtracts the order quantity from reserved stock.
                    // Math.max prevents the resulting value from going below zero.

                    inv.Physical_Stock__c = Math.max(
                        0,
                        (inv.Physical_Stock__c != null
                            ? inv.Physical_Stock__c
                            : 0) - qty
                    );
                    // Subtracts the order quantity from physical stock.
                    // This also prevents the stored result from going below zero.

                    invsToUpdate.add(inv);
                    // Adds the modified inventory record to the update list.

                    Inventory_Ledger__c led = new Inventory_Ledger__c(
                        Inventory__c = inv.Id,
                        Type__c = 'Order_Dispatch',
                        Quantity_Delta__c = -qty,
                        Reference_Record_Id__c = ord.Id,
                        Timestamp__c = System.now(),
                        Notes__c = 'Dispatched for Order ' + ord.Name
                    );
                    // Creates an inventory ledger entry to record the stock movement.
                    // A negative Quantity_Delta__c represents stock leaving inventory.
                    // Reference_Record_Id__c connects the entry to this order.

                    ledgers.add(led);
                    // Adds the ledger entry to the list for bulk insertion.
                }
            }
        }

        if (!invsToUpdate.isEmpty()) {
            update invsToUpdate;
            // Saves all inventory changes in one DML update.
        }

        if (!ledgers.isEmpty()) {
            insert ledgers;
            // Inserts all inventory ledger entries in one DML operation.
        }

        // STEP 2: Create an invoice for the order.
        Invoice__c invRecord = new Invoice__c(
            Order__c = ord.Id,
            Invoice_Amount__c = ord.Total_Amount__c,
            Invoice_Date__c = Date.today(),
            Invoice_Number__c = 'INV-' + ord.Name,
            Status__c = 'Paid'
        );
        // Populates the invoice with the order, amount, date, number and status.
        // Note: this code sets the invoice status to Paid directly.

        insert invRecord;
        // Saves the invoice in Salesforce and generates its record ID.

        // STEP 3: Update the order status after fulfillment.
        ord.Status__c = 'Dispatched';
        // Changes the order's status to Dispatched.

        update ord;
        // Saves the status change to Salesforce.

        return new Map<String, Object>{
            'orderId' => ord.Id,
            'status' => ord.Status__c,
            'invoiceId' => invRecord.Id,
            'invoiceNumber' => invRecord.Invoice_Number__c
        };
        // Returns the order ID, updated status and invoice details to the API caller.
    }
}
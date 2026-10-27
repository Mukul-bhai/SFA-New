public with sharing class DmsPortalController {

    public class PrimaryOrderItem {
        @AuraEnabled public String productId { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public String productCode { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Decimal mrp { get; set; }
    }

    public class PortalInitData {
        @AuraEnabled public Distributor__c activeDistributor { get; set; }
        @AuraEnabled public List<Distributor__c> allDistributors { get; set; }
        @AuraEnabled public List<ProductDTO> products { get; set; }
        @AuraEnabled public List<OrderDTO> primaryOrders { get; set; }
        @AuraEnabled public List<OrderDTO> secondaryOrders { get; set; }
        @AuraEnabled public Map<String, Decimal> kpis { get; set; }
    }

    public class ProductDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String code { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String brand { get; set; }
        @AuraEnabled public String subBrand { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String packSize { get; set; }
        @AuraEnabled public Decimal mrp { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Decimal availableStock { get; set; }
    }

    public class OrderDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Date orderDate { get; set; }
        @AuraEnabled public String orderType { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }
        @AuraEnabled public Decimal totalQuantity { get; set; }
        @AuraEnabled public Integer itemsCount { get; set; }
        @AuraEnabled public String distributorName { get; set; }
        @AuraEnabled public String customerName { get; set; }
        @AuraEnabled public String beatName { get; set; }
        @AuraEnabled public String poNumber { get; set; }
        @AuraEnabled public String remarks { get; set; }
        @AuraEnabled public List<OrderLineDTO> lines { get; set; }
    }

    public class OrderLineDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public String productCode { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal freeQuantity { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Decimal lineTotal { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static PortalInitData getPortalInitData(Id selectedDistributorId) {
        PortalInitData data = new PortalInitData();
        
        // 1. Fetch Distributors
        data.allDistributors = [
            SELECT Id, Name, Distributor_Code__c, Contact_Person__c, Credit_Limit__c, Current_Outstanding__c, GSTIN__c, Status__c
            FROM Distributor__c
            ORDER BY Name ASC
            LIMIT 50
        ];

        if (!data.allDistributors.isEmpty()) {
            if (selectedDistributorId != null) {
                for (Distributor__c d : data.allDistributors) {
                    if (d.Id == selectedDistributorId) {
                        data.activeDistributor = d;
                        break;
                    }
                }
            }
            if (data.activeDistributor == null) {
                data.activeDistributor = data.allDistributors[0];
            }
        }

        Id distId = data.activeDistributor != null ? data.activeDistributor.Id : null;

        // 2. Fetch Products
        data.products = fetchProducts();

        // 3. Fetch Primary and Secondary Orders
        data.primaryOrders = fetchOrders(distId, 'Primary');
        data.secondaryOrders = fetchOrders(distId, 'Secondary');

        // 4. Calculate KPIs
        data.kpis = new Map<String, Decimal>();
        Decimal primaryTotal = 0;
        Decimal secondaryTotal = 0;
        Integer pendingPrimary = 0;
        Integer pendingSecondary = 0;

        for (OrderDTO o : data.primaryOrders) {
            primaryTotal += (o.totalAmount != null ? o.totalAmount : 0);
            if (o.status == 'Submitted' || o.status == 'Draft' || o.status == 'Processing') {
                pendingPrimary++;
            }
        }

        for (OrderDTO o : data.secondaryOrders) {
            secondaryTotal += (o.totalAmount != null ? o.totalAmount : 0);
            if (o.status == 'Draft' || o.status == 'Submitted') {
                pendingSecondary++;
            }
        }

        Decimal creditLimit = data.activeDistributor != null && data.activeDistributor.Credit_Limit__c != null ? data.activeDistributor.Credit_Limit__c : 0;
        Decimal outstanding = data.activeDistributor != null && data.activeDistributor.Current_Outstanding__c != null ? data.activeDistributor.Current_Outstanding__c : 0;
        Decimal availableCredit = creditLimit - outstanding;

        data.kpis.put('primaryTotal', primaryTotal);
        data.kpis.put('secondaryTotal', secondaryTotal);
        data.kpis.put('pendingPrimary', pendingPrimary);
        data.kpis.put('pendingSecondary', pendingSecondary);
        data.kpis.put('creditLimit', creditLimit);
        data.kpis.put('currentOutstanding', outstanding);
        data.kpis.put('availableCredit', availableCredit > 0 ? availableCredit : 0);

        return data;
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductDTO> fetchProducts() {
        List<ProductDTO> listDTO = new List<ProductDTO>();
        
        // Query Product__c first
        List<Product__c> prods = [
            SELECT Id, Name, Product_Code__c, Brand__c, Sub_Brand__c, Category__c, Package_Type__c, 
                   MRP__c, RBP__c, Unit_Conversion__c, Available_Stock__c, SKU__c
            FROM Product__c
            WHERE Is_Active__c = true OR Is_Active__c = null
            ORDER BY Name ASC
            LIMIT 100
        ];

        for (Product__c p : prods) {
            ProductDTO dto = new ProductDTO();
            dto.id = p.Id;
            dto.code = String.isNotBlank(p.Product_Code__c) ? p.Product_Code__c : p.SKU__c;
            dto.name = p.Name;
            dto.brand = p.Brand__c;
            dto.subBrand = p.Sub_Brand__c;
            dto.category = p.Category__c;
            dto.packSize = p.Package_Type__c != null ? p.Package_Type__c : (p.Unit_Conversion__c != null ? String.valueOf(p.Unit_Conversion__c.intValue()) : 'Standard');
            dto.mrp = p.MRP__c != null ? p.MRP__c : 0;
            dto.unitPrice = p.RBP__c != null ? p.RBP__c : (p.MRP__c != null ? p.MRP__c * 0.85 : 50);
            dto.availableStock = p.Available_Stock__c != null ? p.Available_Stock__c : 250;
            listDTO.add(dto);
        }

        // If Product__c is empty, check standard Product2
        if (listDTO.isEmpty()) {
            for (Product2 p2 : [
                SELECT Id, Name, ProductCode, Brand__c, Category__c, Pack_Size__c, MRP__c, Base_Price__c 
                FROM Product2 
                WHERE IsActive = true 
                LIMIT 50
            ]) {
                ProductDTO dto = new ProductDTO();
                dto.id = p2.Id;
                dto.code = p2.ProductCode;
                dto.name = p2.Name;
                dto.brand = p2.Brand__c;
                dto.category = p2.Category__c;
                dto.packSize = p2.Pack_Size__c != null ? p2.Pack_Size__c : 'Standard';
                dto.mrp = p2.MRP__c != null ? p2.MRP__c : 0;
                dto.unitPrice = p2.Base_Price__c != null ? p2.Base_Price__c : 50;
                dto.availableStock = 300;
                listDTO.add(dto);
            }
        }

        return listDTO;
    }

    @AuraEnabled
    public static List<OrderDTO> fetchOrders(Id distributorId, String orderTypeFilter) {
        List<OrderDTO> result = new List<OrderDTO>();

        String soql = 'SELECT Id, Name, Order_Date__c, Order_Type__c, Status__c, Total_Amount__c, Total_Quantity__c, ' +
                     'Total_Products_Count__c, Distributor_PO_Number__c, Remarks__c, Primary_Distributor__r.Name, ' +
                     'Retailer__r.Name, Outlet__r.Name, Beat__r.Name, Sales_Executive__r.Name, ' +
                     '(SELECT Id, Product_Custom__r.Name, Product_Name__c, SKU__c, Quantity__c, Unit_Price__c, Line_Total__c, Free_Goods_Quantity__c FROM Order_Lines__r) ' +
                     'FROM Order__c WHERE Id != null ';

        if (distributorId != null) {
            soql += 'AND (Primary_Distributor__c = :distributorId OR Primary_Distributor__c = null) ';
        }

        if (orderTypeFilter == 'Primary') {
            soql += 'AND (Order_Type__c = \'Primary\' OR (Retailer__c = null AND Outlet__c = null)) ';
        } else if (orderTypeFilter == 'Secondary') {
            soql += 'AND (Order_Type__c = \'Secondary\' OR Retailer__c != null OR Outlet__c != null) ';
        }

        soql += 'ORDER BY CreatedDate DESC LIMIT 100';

        List<Order__c> orders = Database.query(soql);

        for (Order__c ord : orders) {
            OrderDTO dto = new OrderDTO();
            dto.id = ord.Id;
            dto.name = ord.Name;
            dto.orderDate = ord.Order_Date__c != null ? ord.Order_Date__c.date() : Date.today();
            dto.orderType = ord.Order_Type__c != null ? ord.Order_Type__c : (ord.Retailer__c != null || ord.Outlet__c != null ? 'Secondary' : 'Primary');
            dto.status = ord.Status__c != null ? ord.Status__c : 'Draft';
            dto.totalAmount = ord.Total_Amount__c != null ? ord.Total_Amount__c : 0;
            dto.totalQuantity = ord.Total_Quantity__c != null ? ord.Total_Quantity__c : 0;
            dto.distributorName = ord.Primary_Distributor__r != null ? ord.Primary_Distributor__r.Name : 'Self';
            dto.poNumber = ord.Distributor_PO_Number__c;
            dto.remarks = ord.Remarks__c;

            if (ord.Retailer__r != null) {
                dto.customerName = ord.Retailer__r.Name;
            } else if (ord.Outlet__r != null) {
                dto.customerName = ord.Outlet__r.Name;
            } else {
                dto.customerName = 'Central Warehouse Depot';
            }

            dto.beatName = ord.Beat__r != null ? ord.Beat__r.Name : 'Direct';

            dto.lines = new List<OrderLineDTO>();
            if (ord.Order_Lines__r != null) {
                dto.itemsCount = ord.Order_Lines__r.size();
                for (Order_Line__c ol : ord.Order_Lines__r) {
                    OrderLineDTO lineDTO = new OrderLineDTO();
                    lineDTO.id = ol.Id;
                    lineDTO.productName = ol.Product_Custom__r != null ? ol.Product_Custom__r.Name : ol.Product_Name__c;
                    lineDTO.productCode = ol.SKU__c;
                    lineDTO.quantity = ol.Quantity__c;
                    lineDTO.freeQuantity = ol.Free_Goods_Quantity__c;
                    lineDTO.unitPrice = ol.Unit_Price__c;
                    lineDTO.lineTotal = ol.Line_Total__c;
                    dto.lines.add(lineDTO);
                }
            } else {
                dto.itemsCount = 0;
            }

            result.add(dto);
        }

        return result;
    }

    /**
     * Bulk Multi-Product Primary Order Placement
     * "there should be single time multiple order for primary order"
     */
    @AuraEnabled
    public static Map<String, Object> createBulkPrimaryOrder(Id distributorId, String poNumber, String remarks, String itemsJson) {
        Map<String, Object> result = new Map<String, Object>();
        Savepoint sp = Database.setSavepoint();

        try {
            if (distributorId == null) {
                List<Distributor__c> dists = [SELECT Id FROM Distributor__c LIMIT 1];
                if (!dists.isEmpty()) distributorId = dists[0].Id;
            }

            List<PrimaryOrderItem> items = (List<PrimaryOrderItem>) JSON.deserialize(itemsJson, List<PrimaryOrderItem>.class);
            if (items == null || items.isEmpty()) {
                result.put('success', false);
                result.put('message', 'Please select at least one product with quantity greater than zero.');
                return result;
            }

            Decimal grandSubtotal = 0;
            Decimal grandQuantity = 0;
            List<PrimaryOrderItem> validItems = new List<PrimaryOrderItem>();

            for (PrimaryOrderItem itm : items) {
                if (itm.quantity != null && itm.quantity > 0) {
                    validItems.add(itm);
                    grandSubtotal += (itm.quantity * itm.unitPrice);
                    grandQuantity += itm.quantity;
                }
            }

            if (validItems.isEmpty()) {
                result.put('success', false);
                result.put('message', 'Please specify a quantity greater than zero for at least one item.');
                return result;
            }

            Decimal taxRate = 0.18; // 18% GST
            Decimal taxAmount = grandSubtotal * taxRate;
            Decimal grandTotal = grandSubtotal + taxAmount;

            // 1. Create Order__c Header
            Order__c ord = new Order__c();
            ord.Primary_Distributor__c = distributorId;
            ord.Order_Type__c = 'Primary';
            ord.Status__c = 'Submitted';
            ord.Order_Date__c = System.now();
            ord.Distributor_PO_Number__c = String.isNotBlank(poNumber) ? poNumber : 'PO-PRM-' + System.currentTimeMillis();
            ord.Remarks__c = remarks;
            ord.Total_Amount__c = grandTotal;
            ord.Gross_Amount__c = grandSubtotal;
            ord.Tax_Amount__c = taxAmount;
            ord.Total_Quantity__c = grandQuantity;
            ord.Total_Products_Count__c = validItems.size();
            insert ord;

            // 2. Create Order_Line__c Child Records for all products
            List<Order_Line__c> linesToInsert = new List<Order_Line__c>();
            for (PrimaryOrderItem itm : validItems) {
                Order_Line__c ol = new Order_Line__c();
                ol.Order__c = ord.Id;
                if (itm.productId != null && itm.productId.startsWith('a0X')) {
                    ol.Product_Custom__c = itm.productId;
                } else if (itm.productId != null && itm.productId.startsWith('01t')) {
                    ol.Product__c = itm.productId;
                }
                ol.Product_Name__c = itm.productName;
                ol.SKU__c = itm.productCode;
                ol.Quantity__c = itm.quantity;
                ol.Unit_Price__c = itm.unitPrice;
                ol.Gross_Amount__c = itm.quantity * itm.unitPrice;
                ol.Tax_Amount__c = (itm.quantity * itm.unitPrice) * 0.18;
                ol.Fulfillment_Status__c = 'Pending_Allocation';
                linesToInsert.add(ol);
            }
            insert linesToInsert;

            // Query created order for confirmation
            Order__c createdOrd = [SELECT Id, Name, Order_Date__c, Total_Amount__c, Status__c FROM Order__c WHERE Id = :ord.Id];

            result.put('success', true);
            result.put('orderId', createdOrd.Id);
            result.put('orderNumber', createdOrd.Name);
            result.put('totalAmount', createdOrd.Total_Amount__c);
            result.put('itemCount', validItems.size());
            result.put('message', 'Primary Order ' + createdOrd.Name + ' placed successfully with ' + validItems.size() + ' products!');
            return result;

        } catch (Exception e) {
            Database.rollback(sp);
            result.put('success', false);
            result.put('message', 'Failed to place primary order: ' + e.getMessage());
            return result;
        }
    }

    /**
     * Update Secondary Order Status (Approve / Dispatch)
     */
    @AuraEnabled
    public static Map<String, Object> updateOrderStatus(Id orderId, String newStatus) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Order__c ord = [SELECT Id, Name, Status__c FROM Order__c WHERE Id = :orderId LIMIT 1];
            ord.Status__c = newStatus;
            update ord;

            result.put('success', true);
            result.put('message', 'Order ' + ord.Name + ' status updated to ' + newStatus);
            return result;
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', 'Error updating status: ' + e.getMessage());
            return result;
        }
    }

    /**
     * Fetch Invoices for Distributor
     */
    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getInvoices(Id distributorId) {
        if (distributorId != null) {
            return [
                SELECT Id, Name, Invoice_Number__c, Invoice_Date__c, Invoice_Amount__c, Status__c, Order__r.Name
                FROM Invoice__c
                WHERE Order__r.Primary_Distributor__c = :distributorId
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];
        }
        return [
            SELECT Id, Name, Invoice_Number__c, Invoice_Date__c, Invoice_Amount__c, Status__c, Order__r.Name
            FROM Invoice__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }

    /**
     * Fetch Inventory for Distributor
     */
    @AuraEnabled(cacheable=true)
    public static List<Inventory__c> getInventory(Id distributorId) {
        return [
            SELECT Id, Name, Product__r.Name, Available_Stock__c, Physical_Stock__c, Reserved_Stock__c, Warehouse__r.Name
            FROM Inventory__c
            LIMIT 50
        ];
    }
}

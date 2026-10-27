@isTest
private class DmsPortalControllerTest {

    @TestSetup
    static void setupData() {
        // 1. Distributor
        Distributor__c dist = new Distributor__c(
            Name = 'Test Super Distributor',
            Distributor_Code__c = 'DIST-TEST-001',
            Credit_Limit__c = 100000,
            Current_Outstanding__c = 15000,
            Status__c = 'Active'
        );
        insert dist;

        // 2. Product
        Product__c p = new Product__c(
            Name = 'Choki Choki Choco Paste',
            Product_Code__c = '310309',
            Brand__c = 'Choki Choki',
            MRP__c = 89,
            RBP__c = 77,
            Available_Stock__c = 500,
            Is_Active__c = true
        );
        insert p;

        // 3. Primary Order
        Order__c pOrd = new Order__c(
            Primary_Distributor__c = dist.Id,
            Order_Type__c = 'Primary',
            Status__c = 'Submitted',
            Order_Date__c = System.now(),
            Total_Amount__c = 1540
        );
        insert pOrd;

        Order_Line__c pol = new Order_Line__c(
            Order__c = pOrd.Id,
            Product_Custom__c = p.Id,
            Product_Name__c = p.Name,
            Quantity__c = 20,
            Unit_Price__c = 77
        );
        insert pol;

        // 4. Secondary Order
        Order__c sOrd = new Order__c(
            Primary_Distributor__c = dist.Id,
            Order_Type__c = 'Secondary',
            Status__c = 'Draft',
            Order_Date__c = System.now(),
            Total_Amount__c = 770
        );
        insert sOrd;
    }

    @isTest
    static void testGetPortalInitData() {
        Distributor__c dist = [SELECT Id FROM Distributor__c LIMIT 1];
        Test.startTest();
        DmsPortalController.PortalInitData data = DmsPortalController.getPortalInitData(dist.Id);
        Test.stopTest();

        System.assertNotEquals(null, data);
        System.assertEquals(dist.Id, data.activeDistributor.Id);
        System.assertNotEquals(0, data.products.size());
    }

    @isTest
    static void testCreateBulkPrimaryOrder() {
        Distributor__c dist = [SELECT Id FROM Distributor__c LIMIT 1];
        Product__c prod = [SELECT Id, Name, Product_Code__c, RBP__c, MRP__c FROM Product__c LIMIT 1];

        List<DmsPortalController.PrimaryOrderItem> items = new List<DmsPortalController.PrimaryOrderItem>();
        DmsPortalController.PrimaryOrderItem item1 = new DmsPortalController.PrimaryOrderItem();
        item1.productId = prod.Id;
        item1.productName = prod.Name;
        item1.productCode = prod.Product_Code__c;
        item1.quantity = 10;
        item1.unitPrice = prod.RBP__c;
        item1.mrp = prod.MRP__c;
        items.add(item1);

        String itemsJson = JSON.serialize(items);

        Test.startTest();
        Map<String, Object> res = DmsPortalController.createBulkPrimaryOrder(dist.Id, 'PO-TEST-123', 'Rush Delivery', itemsJson);
        Test.stopTest();

        System.assertEquals(true, res.get('success'));
        System.assertNotEquals(null, res.get('orderId'));
    }

    @isTest
    static void testUpdateOrderStatus() {
        Order__c ord = [SELECT Id FROM Order__c WHERE Order_Type__c = 'Secondary' LIMIT 1];
        Test.startTest();
        Map<String, Object> res = DmsPortalController.updateOrderStatus(ord.Id, 'Approved');
        Test.stopTest();

        System.assertEquals(true, res.get('success'));
        Order__c updated = [SELECT Status__c FROM Order__c WHERE Id = :ord.Id];
        System.assertEquals('Approved', updated.Status__c);
    }

    @isTest
    static void testGetInvoicesAndInventory() {
        Distributor__c dist = [SELECT Id FROM Distributor__c LIMIT 1];
        Test.startTest();
        List<Invoice__c> invoices = DmsPortalController.getInvoices(dist.Id);
        List<Inventory__c> inventory = DmsPortalController.getInventory(dist.Id);
        Test.stopTest();

        System.assertNotEquals(null, invoices);
        System.assertNotEquals(null, inventory);
    }
}

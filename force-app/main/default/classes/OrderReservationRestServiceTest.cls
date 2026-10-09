@isTest
private class OrderReservationRestServiceTest {

    @testSetup
    static void setupTestData() {
        // 1. Create Product
        Product2 prod = new Product2(
            Name = 'Test Shampoo 200ml',
            ProductCode = 'SHMP-200',
            IsActive = true
        );
        insert prod;

        // 2. Create Distributors
        Distributor__c distPrimary = new Distributor__c(
            Name = 'Apex Traders Primary',
            Distributor_Code__c = 'DIST-PRI-001',
            Status__c = 'Active'
        );
        Distributor__c distBackup = new Distributor__c(
            Name = 'Zenith Logistics Backup',
            Distributor_Code__c = 'DIST-BAK-002',
            Status__c = 'Active'
        );
        insert new List<Distributor__c>{ distPrimary, distBackup };

        // 3. Create Warehouses
        Warehouse__c whPrimary = new Warehouse__c(
            Name = 'Primary Depot A',
            Warehouse_Code__c = 'WH-PRI-A',
            Distributor__c = distPrimary.Id,
            Is_Active__c = true
        );
        Warehouse__c whBackup = new Warehouse__c(
            Name = 'Backup Depot B',
            Warehouse_Code__c = 'WH-BAK-B',
            Distributor__c = distBackup.Id,
            Is_Active__c = true
        );
        insert new List<Warehouse__c>{ whPrimary, whBackup };

        distPrimary.Default_Warehouse__c = whPrimary.Id;
        distBackup.Default_Warehouse__c = whBackup.Id;
        update new List<Distributor__c>{ distPrimary, distBackup };

        // 4. Create Retailer
        Retailer__c ret = new Retailer__c(
            Name = 'Gupta Supermarket',
            Retailer_Code__c = 'RET-1001',
            Primary_Distributor__c = distPrimary.Id,
            Backup_Distributor__c = distBackup.Id,
            Allow_Backup_Fulfillment__c = true,
            Credit_Limit__c = 50000,
            Outstanding_Balance__c = 0,
            Credit_Hold__c = false
        );
        insert ret;

        // 5. Create Inventory
        // Primary WH has 70 physical units (0 reserved => 70 available)
        Inventory__c invPri = new Inventory__c(
            Warehouse__c = whPrimary.Id,
            Product__c = prod.Id,
            Warehouse_Product_Key__c = whPrimary.Id + '_' + prod.Id,
            Physical_Stock__c = 70,
            Reserved_Stock__c = 0
        );
        // Backup WH has 150 physical units (0 reserved => 150 available)
        Inventory__c invBak = new Inventory__c(
            Warehouse__c = whBackup.Id,
            Product__c = prod.Id,
            Warehouse_Product_Key__c = whBackup.Id + '_' + prod.Id,
            Physical_Stock__c = 150,
            Reserved_Stock__c = 0
        );
        insert new List<Inventory__c>{ invPri, invBak };
    }

    @isTest
    static void testOrderSplitBetweenPrimaryAndBackup() {
        Retailer__c ret = [SELECT Id FROM Retailer__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        // Executive requests 100 units (70 from primary, 30 from backup)
        OrderReservationRestService.OrderSubmissionRequest req = new OrderReservationRestService.OrderSubmissionRequest();
        req.idempotencyKey = 'UUID-TEST-001';
        req.retailerId = ret.Id;
        req.items = new List<OrderReservationRestService.OrderRequestItem>();

        OrderReservationRestService.OrderRequestItem item = new OrderReservationRestService.OrderRequestItem();
        item.productId = prod.Id;
        item.quantity = 100;
        item.unitPrice = 120;
        req.items.add(item);

        Test.startTest();
        OrderReservationRestService.OrderSubmissionResponse resp = OrderReservationRestService.submitOrder(req);
        Test.stopTest();

        System.assert(resp.success, 'Order reservation should succeed: ' + resp.message);
        System.assertNotEquals(null, resp.orderId, 'Order ID should be returned');

        // Check Order Lines
        List<Order_Line__c> lines = [
            SELECT Quantity__c, Fulfillment_Status__c, Fulfilling_Distributor__c 
            FROM Order_Line__c 
            WHERE Order__c = :resp.orderId
            ORDER BY Quantity__c DESC
        ];
        System.assertEquals(2, lines.size(), 'Should create two split order lines');
        System.assertEquals(70, lines[0].Quantity__c, 'Primary should allocate 70');
        System.assertEquals(30, lines[1].Quantity__c, 'Backup should allocate 30');

        // Verify Idempotent Replay
        OrderReservationRestService.OrderSubmissionResponse replayResp = OrderReservationRestService.submitOrder(req);
        System.assert(replayResp.success, 'Replay should succeed');
        System.assertEquals(resp.orderId, replayResp.orderId, 'Replay should return identical order ID');
    }

    @isTest
    static void testBootstrapService() {
        Test.startTest();
        SyncBootstrapRestService.BootstrapResponse resp = SyncBootstrapRestService.getBootstrapData();
        Test.stopTest();

        System.assert(resp.success, 'Bootstrap data retrieval should succeed');
        System.assertNotEquals(null, resp.products, 'Products should not be null');
    }
}

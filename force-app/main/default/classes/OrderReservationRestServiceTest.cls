@isTest
// Marks this class as a test class.
// Salesforce runs these methods during Apex testing to verify the order reservation service.
private class OrderReservationRestServiceTest {

    @testSetup
    // Creates common test data once for all test methods in this class.
    // Test data is isolated from actual Salesforce business records.
    static void setupTestData() {

        // STEP 1: Create a test product.
        Product2 prod = new Product2(
            Name = 'Test Shampoo 200ml', // Name of the product.
            ProductCode = 'SHMP-200',     // Unique business code for the product.
            IsActive = true               // Makes the product active.
        );
        insert prod; // Saves the product in Salesforce.

        // STEP 2: Create the primary and backup distributors.
        Distributor__c distPrimary = new Distributor__c(
            Name = 'Apex Traders Primary',
            Distributor_Code__c = 'DIST-PRI-001',
            Status__c = 'Active'
        );
        // This distributor supplies stock first.

        Distributor__c distBackup = new Distributor__c(
            Name = 'Zenith Logistics Backup',
            Distributor_Code__c = 'DIST-BAK-002',
            Status__c = 'Active'
        );
        // This distributor supplies stock if the primary distributor has insufficient stock.

        insert new List<Distributor__c>{ distPrimary, distBackup };
        // Inserts both distributors in one DML operation.

        // STEP 3: Create warehouses for both distributors.
        Warehouse__c whPrimary = new Warehouse__c(
            Name = 'Primary Depot A',
            Warehouse_Code__c = 'WH-PRI-A',
            Distributor__c = distPrimary.Id,
            Is_Active__c = true
        );
        // Associates the primary warehouse with the primary distributor.

        Warehouse__c whBackup = new Warehouse__c(
            Name = 'Backup Depot B',
            Warehouse_Code__c = 'WH-BAK-B',
            Distributor__c = distBackup.Id,
            Is_Active__c = true
        );
        // Associates the backup warehouse with the backup distributor.

        insert new List<Warehouse__c>{ whPrimary, whBackup };
        // Saves both warehouse records.

        // STEP 4: Set each distributor's default warehouse.
        distPrimary.Default_Warehouse__c = whPrimary.Id;
        // Sets the primary warehouse as the primary distributor's default warehouse.

        distBackup.Default_Warehouse__c = whBackup.Id;
        // Sets the backup warehouse as the backup distributor's default warehouse.

        update new List<Distributor__c>{ distPrimary, distBackup };
        // Saves the default warehouse relationships.

        // STEP 5: Create a retailer that can use both distributors.
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
        // The retailer's primary distributor is checked first.
        // Backup fulfillment is enabled.
        // The retailer is not on credit hold.

        insert ret;
        // Saves the retailer record.

        // STEP 6: Create inventory for the primary warehouse.
        Inventory__c invPri = new Inventory__c(
            Warehouse__c = whPrimary.Id,
            Product__c = prod.Id,
            Warehouse_Product_Key__c = whPrimary.Id + '_' + prod.Id,
            Physical_Stock__c = 70,
            Reserved_Stock__c = 0
        );
        // The primary warehouse has 70 physical units and zero reserved units.
        // This test assumes Available_Stock__c is calculated or populated as 70.

        // Create inventory for the backup warehouse.
        Inventory__c invBak = new Inventory__c(
            Warehouse__c = whBackup.Id,
            Product__c = prod.Id,
            Warehouse_Product_Key__c = whBackup.Id + '_' + prod.Id,
            Physical_Stock__c = 150,
            Reserved_Stock__c = 0
        );
        // The backup warehouse has 150 physical units and zero reserved units.
        // This test assumes Available_Stock__c is calculated or populated as 150.

        insert new List<Inventory__c>{ invPri, invBak };
        // Saves both inventory records for the allocation tests.
    }

    @isTest
    // Tests allocation across primary and backup distributors
    // and verifies that repeating a request does not create another order.
    static void testOrderSplitBetweenPrimaryAndBackup() {

        Retailer__c ret = [SELECT Id FROM Retailer__c LIMIT 1];
        // Retrieves the retailer created by the test setup.

        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        // Retrieves the test product.

        // STEP 1: Prepare the order request.
        OrderReservationRestService.OrderSubmissionRequest req =
            new OrderReservationRestService.OrderSubmissionRequest();
        // Creates the request object expected by the service.

        req.idempotencyKey = 'UUID-TEST-001';
        // Assigns a key that the service can use to identify repeated requests.

        req.retailerId = ret.Id;
        // Specifies which retailer is placing the order.

        req.items =
            new List<OrderReservationRestService.OrderRequestItem>();
        // Initializes the list of requested products.

        OrderReservationRestService.OrderRequestItem item =
            new OrderReservationRestService.OrderRequestItem();
        // Creates one product line for the order request.

        item.productId = prod.Id;
        // Sets the requested product ID.

        item.quantity = 100;
        // Requests 100 units.
        // Expected allocation: 70 from primary and 30 from backup.

        item.unitPrice = 120;
        // Sets the price of one unit to 120.

        req.items.add(item);
        // Adds the product line to the request.

        // STEP 2: Execute the service under test.
        Test.startTest();
        // Marks the beginning of the test execution section.
        // It also provides a fresh governor-limit context for this section.

        OrderReservationRestService.OrderSubmissionResponse resp =
            OrderReservationRestService.submitOrder(req);
        // Calls the service directly with the prepared request.
        // This tests submitOrder(), not the HTTP endpoint handler.

        Test.stopTest();
        // Ends the test execution section and runs pending asynchronous work, if any.

        // STEP 3: Verify the main response.
        System.assert(
            resp.success,
            'Order reservation should succeed: ' + resp.message
        );
        // Fails the test if the service reports an unsuccessful response.

        System.assertNotEquals(
            null,
            resp.orderId,
            'Order ID should be returned'
        );
        // Confirms that the response contains an order ID.

        // STEP 4: Query the order lines created by the service.
        List<Order_Line__c> lines = [
            SELECT Quantity__c, Fulfillment_Status__c,
                   Fulfilling_Distributor__c
            FROM Order_Line__c
            WHERE Order__c = :resp.orderId
            ORDER BY Quantity__c DESC
        ];
        // Retrieves the order lines belonging to the created order.
        // Sorting by quantity descending puts the 70-unit line before the 30-unit line.

        System.assertEquals(
            2,
            lines.size(),
            'Should create two split order lines'
        );
        // Confirms that the service created two lines:
        // one for primary stock and one for backup stock.

        System.assertEquals(
            70,
            lines[0].Quantity__c,
            'Primary should allocate 70'
        );
        // Verifies that the primary distributor supplies 70 units.

        System.assertEquals(
            30,
            lines[1].Quantity__c,
            'Backup should allocate 30'
        );
        // Verifies that the backup distributor supplies the remaining 30 units.

        // STEP 5: Verify idempotency.
        // Calling the service again with the same key should return the existing order.
        OrderReservationRestService.OrderSubmissionResponse replayResp =
            OrderReservationRestService.submitOrder(req);

        System.assert(
            replayResp.success,
            'Replay should succeed'
        );
        // Confirms that the repeated request is handled successfully.

        System.assertEquals(
            resp.orderId,
            replayResp.orderId,
            'Replay should return identical order ID'
        );
        // Confirms that the replay returns the same order ID,
        // rather than creating a second order.
    }

    @isTest
    // Tests that the bootstrap service returns initial synchronization data.
    static void testBootstrapService() {

        Test.startTest();
        // Starts the measured test execution section.

        SyncBootstrapRestService.BootstrapResponse resp =
            SyncBootstrapRestService.getBootstrapData();
        // Calls the bootstrap service to retrieve its initial data.
        // The implementation of SyncBootstrapRestService is not included here.

        Test.stopTest();
        // Ends the test execution section.

        System.assert(
            resp.success,
            'Bootstrap data retrieval should succeed'
        );
        // Verifies that the bootstrap response reports success.

        System.assertNotEquals(
            null,
            resp.products,
            'Products should not be null'
        );
        // Verifies that the products collection is initialized and returned.
    }
}
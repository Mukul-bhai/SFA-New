@isTest
private class DmsAdminRestServiceTest {

    @testSetup
    static void setupTestData() {
        // 1. Territory
        Territory__c terr = new Territory__c(
            Name = 'Test Territory',
            Territory_Code__c = 'TERR-01',
            Region__c = 'North'
        );
        insert terr;

        // 2. Distributor & Warehouse
        Distributor__c dist = new Distributor__c(
            Name = 'Test Dist',
            Distributor_Code__c = 'DIST-001',
            Status__c = 'Active',
            Credit_Limit__c = 100000,
            Current_Outstanding__c = 10000
        );
        insert dist;

        Warehouse__c wh = new Warehouse__c(
            Name = 'Test WH',
            Warehouse_Code__c = 'WH-001',
            Distributor__c = dist.Id,
            Is_Active__c = true
        );
        insert wh;

        dist.Default_Warehouse__c = wh.Id;
        update dist;

        // 3. Retailer
        Retailer__c ret = new Retailer__c(
            Name = 'Test Retailer',
            Retailer_Code__c = 'RET-001',
            Primary_Distributor__c = dist.Id,
            Credit_Limit__c = 50000,
            Outstanding_Balance__c = 5000,
            Credit_Hold__c = false
        );
        insert ret;

        // 4. Product & Inventory
        Product2 prod = new Product2(
            Name = 'Test Shampoo',
            ProductCode = 'SHMP-1',
            IsActive = true
        );
        insert prod;

        Inventory__c inv = new Inventory__c(
            Warehouse__c = wh.Id,
            Product__c = prod.Id,
            Warehouse_Product_Key__c = wh.Id + '_' + prod.Id,
            Physical_Stock__c = 100,
            Reserved_Stock__c = 20
        );
        insert inv;

        // 5. Order & Lines
        Order__c ord = new Order__c(
            Retailer__c = ret.Id,
            Primary_Distributor__c = dist.Id,
            Status__c = 'Submitted',
            Total_Amount__c = 2400,
            Order_Date__c = System.now()
        );
        insert ord;

        Order_Line__c line = new Order_Line__c(
            Order__c = ord.Id,
            Product__c = prod.Id,
            Quantity__c = 10,
            Unit_Price__c = 240,
            Fulfilling_Distributor__c = dist.Id,
            Fulfillment_Status__c = 'Allocated_Primary'
        );
        insert line;
    }

    @isTest
    static void testGetEndpoints() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Overview
        req.requestURI = '/services/apexrest/api/v1/dms/overview';
        RestContext.request = req;
        DmsAdminRestService.doGet();
        System.assert(res.responseBody != null);

        // Distributors
        req.requestURI = '/services/apexrest/api/v1/dms/distributors';
        RestContext.request = req;
        DmsAdminRestService.doGet();

        // Warehouses
        req.requestURI = '/services/apexrest/api/v1/dms/warehouses';
        RestContext.request = req;
        DmsAdminRestService.doGet();

        // Retailers
        req.requestURI = '/services/apexrest/api/v1/dms/retailers';
        RestContext.request = req;
        DmsAdminRestService.doGet();

        // Inventory
        req.requestURI = '/services/apexrest/api/v1/dms/inventory';
        RestContext.request = req;
        DmsAdminRestService.doGet();

        // Orders
        req.requestURI = '/services/apexrest/api/v1/dms/orders';
        RestContext.request = req;
        DmsAdminRestService.doGet();
    }

    @isTest
    static void testFulfillmentEndpoint() {
        Order__c ord = [SELECT Id FROM Order__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/api/v1/dms/orders/fulfill';
        req.requestBody = Blob.valueOf('{"orderId":"' + ord.Id + '"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        DmsAdminRestService.doPost();
        Test.stopTest();

        Order__c updatedOrd = [SELECT Id, Status__c FROM Order__c WHERE Id = :ord.Id];
        System.assertEquals('Dispatched', updatedOrd.Status__c);

        List<Invoice__c> invoices = [SELECT Id, Order__c FROM Invoice__c WHERE Order__c = :ord.Id];
        System.assertEquals(1, invoices.size());
    }
}

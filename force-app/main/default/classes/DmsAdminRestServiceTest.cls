// @IsTest tells Salesforce that this class is used for testing.
// Test classes verify that our production Apex code works correctly.
@IsTest

// private means this test class is not exposed as a public Apex class.
// DmsAdminRestServiceTest is the name of our test class.
private class DmsAdminRestServiceTest {

    // @TestSetup runs once as a setup method for this test class.
    // Salesforce provides the created test records separately to each test method.
    @TestSetup
    static void setupTestData() {

        // Create a new Territory record in memory.
        // Territory__c is a custom Salesforce object.
        Territory__c territory = new Territory__c(

            // Set the Territory record's Name field.
            Name = 'Test Territory',

            // Set the custom Territory Code field.
            Territory_Code__c = 'TERR-01',

            // Set the Region field to North.
            Region__c = 'North'
        );

        // Save the Territory record to Salesforce.
        // Salesforce generates its Id after insertion.
        insert territory;


        // Create a new Distributor record.
        Distributor__c distributor = new Distributor__c(

            // Set the distributor's name.
            Name = 'Test Distributor',

            // Assign a unique distributor code for this test record.
            Distributor_Code__c = 'DIST-001',

            // Set the distributor's status to Active.
            Status__c = 'Active',

            // Set the distributor's credit limit to 100000.
            Credit_Limit__c = 100000,

            // Set the current outstanding amount to 10000.
            Current_Outstanding__c = 10000
        );

        // Insert the distributor into Salesforce.
        insert distributor;


        // Create a Warehouse record.
        Warehouse__c warehouse = new Warehouse__c(

            // Set the warehouse name.
            Name = 'Test Warehouse',

            // Assign a warehouse code.
            Warehouse_Code__c = 'WH-001',

            // Link the warehouse to the distributor we created above.
            // distributor.Id contains the Salesforce record ID.
            Distributor__c = distributor.Id,

            // Mark the warehouse as active.
            Is_Active__c = true
        );

        // Save the warehouse record.
        insert warehouse;


        // Assign the newly created warehouse as the distributor's default.
        // This lookup field stores the Warehouse record's Id.
        distributor.Default_Warehouse__c = warehouse.Id;

        // Update the existing distributor record.
        // update saves the changed Default_Warehouse__c field.
        update distributor;


        // Create a Retailer record.
        Retailer__c retailer = new Retailer__c(

            // Set the retailer's name.
            Name = 'Test Retailer',

            // Assign a retailer code.
            Retailer_Code__c = 'RET-001',

            // Link the retailer to its primary distributor.
            Primary_Distributor__c = distributor.Id,

            // Set the retailer's credit limit.
            Credit_Limit__c = 50000,

            // Set the retailer's outstanding balance.
            Outstanding_Balance__c = 5000,

            // Set Credit Hold to false.
            // The retailer is not on credit hold in this test.
            Credit_Hold__c = false
        );

        // Save the retailer record.
        insert retailer;


        // Create a standard Salesforce Product record.
        // Product2 is Salesforce's standard product object.
        Product2 product = new Product2(

            // Set the product name.
            Name = 'Test Shampoo',

            // Assign the product code.
            ProductCode = 'SHMP-1',

            // Make the product active.
            IsActive = true
        );

        // Insert the product record.
        insert product;


        // Create an Inventory record.
        Inventory__c inventory = new Inventory__c(

            // Link the inventory record to the warehouse.
            Warehouse__c = warehouse.Id,

            // Link the inventory record to the product.
            Product__c = product.Id,

            // Create a unique warehouse-product key.
            // String.valueOf converts each Id into a String.
            // The + operator joins the strings with an underscore.
            Warehouse_Product_Key__c =
                String.valueOf(warehouse.Id) + '_' +
                String.valueOf(product.Id),

            // Set physical stock to 100 units.
            Physical_Stock__c = 100,

            // Set reserved stock to 20 units.
            Reserved_Stock__c = 20
        );

        // Insert the inventory record.
        insert inventory;


        // Create an Order record.
        Order__c orderRecord = new Order__c(

            // Link the order to the retailer.
            Retailer__c = retailer.Id,

            // Set the primary distributor for the order.
            Primary_Distributor__c = distributor.Id,

            // Set the initial order status to Submitted.
            Status__c = 'Submitted',

            // Set the order's total amount to 2400.
            Total_Amount__c = 2400,

            // Set the order date and time to the current date and time.
            // System.now() returns a Datetime value.
            Order_Date__c = System.now()
        );

        // Insert the order record.
        insert orderRecord;


        // Create an Order Line record.
        // An order line represents a product included in an order.
        Order_Line__c orderLine = new Order_Line__c(

            // Link this order line to the order created above.
            Order__c = orderRecord.Id,

            // Link the order line to the product.
            Product__c = product.Id,

            // Set the ordered quantity to 10 units.
            Quantity__c = 10,

            // Set the price per unit to 240.
            Unit_Price__c = 240,

            // Assign the distributor responsible for fulfillment.
            Fulfilling_Distributor__c = distributor.Id,

            // Set the fulfillment status.
            Fulfillment_Status__c = 'Allocated_Primary'
        );

        // Save the order line.
        insert orderLine;
    }


    // This helper method prepares a simulated REST request.
    // It avoids repeating the same request setup in every test method.
    private static void prepareRequest(
        String requestUri,  // The API endpoint to test.
        String httpMethod   // The HTTP method, such as GET or POST.
    ) {

        // Create a new simulated REST request.
        RestRequest request = new RestRequest();

        // Set the endpoint path that the Apex REST service will inspect.
        request.requestURI = requestUri;

        // Set the HTTP method for the request.
        request.httpMethod = httpMethod;

        // Store the request in RestContext.
        // Production Apex REST methods read the request from this context.
        RestContext.request = request;

        // Create a fresh response object for this request.
        RestContext.response = new RestResponse();
    }


    // TEST 1: Verify the overview GET endpoint.
    @IsTest
    static void testGetOverview() {

        // Prepare a GET request for the overview endpoint.
        prepareRequest(
            '/services/apexrest/api/v1/dms/overview',
            'GET'
        );

        // Start a fresh governor-limit window for the code under test.
        Test.startTest();

        // Call the actual production method directly.
        // It should process the overview endpoint.
        DmsAdminRestService.doGet();

        // End the test execution window.
        // Eligible asynchronous work queued in this window is executed.
        Test.stopTest();

        // Verify that the API returned a response body.
        // assertNotEquals fails the test if both values are equal.
        System.assertNotEquals(
            null,
            RestContext.response.responseBody,
            'Overview endpoint should return a response body.'
        );

        // Verify that the API returned HTTP 200.
        // This expected status must match the production implementation.
        System.assertEquals(
            200,
            RestContext.response.statusCode,
            'Overview endpoint should return HTTP 200.'
        );
    }


    // TEST 2: Verify the distributors GET endpoint.
    @IsTest
    static void testGetDistributors() {

        // Prepare a GET request for distributors.
        prepareRequest(
            '/services/apexrest/api/v1/dms/distributors',
            'GET'
        );

        // Start the test execution window.
        Test.startTest();

        // Execute the production GET method.
        DmsAdminRestService.doGet();

        // End the test execution window.
        Test.stopTest();

        // Confirm that a response body exists.
        System.assertNotEquals(
            null,
            RestContext.response.responseBody,
            'Distributors endpoint should return a response body.'
        );

        // Confirm that the expected success status is returned.
        System.assertEquals(
            200,
            RestContext.response.statusCode,
            'Distributors endpoint should return HTTP 200.'
        );
    }


    // TEST 3: Verify the warehouses GET endpoint.
    @IsTest
    static void testGetWarehouses() {

        // Prepare a GET request for warehouses.
        prepareRequest(
            '/services/apexrest/api/v1/dms/warehouses',
            'GET'
        );

        // Start the test execution window.
        Test.startTest();

        // Call the production method to process the GET request.
        DmsAdminRestService.doGet();

        // Finish the test execution window.
        Test.stopTest();

        // Verify that a response body was returned.
        System.assertNotEquals(
            null,
            RestContext.response.responseBody,
            'Warehouses endpoint should return a response body.'
        );

        // Verify the expected HTTP success code.
        System.assertEquals(
            200,
            RestContext.response.statusCode,
            'Warehouses endpoint should return HTTP 200.'
        );
    }


    // TEST 4: Verify the retailers GET endpoint.
    @IsTest
    static void testGetRetailers() {

        // Prepare a GET request for retailers.
        prepareRequest(
            '/services/apexrest/api/v1/dms/retailers',
            'GET'
        );

        // Start the test execution window.
        Test.startTest();

        // Execute the production GET method.
        DmsAdminRestService.doGet();

        // End the test execution window.
        Test.stopTest();

        // Check that the response body is not null.
        System.assertNotEquals(
            null,
            RestContext.response.responseBody,
            'Retailers endpoint should return a response body.'
        );

        // Check that the endpoint returned HTTP 200.
        System.assertEquals(
            200,
            RestContext.response.statusCode,
            'Retailers endpoint should return HTTP 200.'
        );
    }


    // TEST 5: Verify the inventory GET endpoint.
    @IsTest
    static void testGetInventory() {

        // Prepare a GET request for inventory.
        prepareRequest(
            '/services/apexrest/api/v1/dms/inventory',
            'GET'
        );

        // Start the test execution window.
        Test.startTest();

        // Execute the production GET method.
        DmsAdminRestService.doGet();

        // Finish the test execution window.
        Test.stopTest();

        // Confirm that the response body exists.
        System.assertNotEquals(
            null,
            RestContext.response.responseBody,
            'Inventory endpoint should return a response body.'
        );

        // Confirm the expected success status.
        System.assertEquals(
            200,
            RestContext.response.statusCode,
            'Inventory endpoint should return HTTP 200.'
        );
    }


    // TEST 6: Verify the orders GET endpoint.
    @IsTest
    static void testGetOrders() {

        // Prepare a GET request for orders.
        prepareRequest(
            '/services/apexrest/api/v1/dms/orders',
            'GET'
        );

        // Start the test execution window.
        Test.startTest();

        // Call the production GET method.
        DmsAdminRestService.doGet();

        // End the test execution window.
        Test.stopTest();

        // Confirm that the endpoint returned a response body.
        System.assertNotEquals(
            null,
            RestContext.response.responseBody,
            'Orders endpoint should return a response body.'
        );

        // Confirm that the expected HTTP status is returned.
        System.assertEquals(
            200,
            RestContext.response.statusCode,
            'Orders endpoint should return HTTP 200.'
        );
    }


    // TEST 7: Verify successful order fulfillment.
    @IsTest
    static void testFulfillmentSuccess() {

        // Query the test order created by @TestSetup.
        // SELECT specifies the fields we want to retrieve.
        // WHERE filters the records by status.
        // LIMIT 1 returns at most one matching record.
        Order__c orderRecord = [
            SELECT Id, Status__c, Total_Amount__c
            FROM Order__c
            WHERE Status__c = 'Submitted'
            LIMIT 1
        ];

        // Prepare a simulated POST request for fulfillment.
        prepareRequest(
            '/services/apexrest/api/v1/dms/orders/fulfill',
            'POST'
        );

        // Create a map containing the order ID.
        // JSON.serialize converts the map into a JSON string.
        // Blob.valueOf converts the string into a Blob request body.
        RestContext.request.requestBody = Blob.valueOf(
            JSON.serialize(
                new Map<String, String>{
                    'orderId' => String.valueOf(orderRecord.Id)
                }
            )
        );

        // Set the Content-Type header.
        // This indicates that the request body contains JSON.
        RestContext.request.addHeader(
            'Content-Type',
            'application/json'
        );

        // Start the test execution window.
        Test.startTest();

        // Call the production POST method.
        // It should process the order fulfillment request.
        DmsAdminRestService.doPost();

        // Finish the test execution window.
        Test.stopTest();


        // Query the order again to retrieve its updated status.
        // A new query is used to verify the result of the operation.
        Order__c updatedOrder = [
            SELECT Id, Status__c
            FROM Order__c
            WHERE Id = :orderRecord.Id
        ];

        // Confirm that the order was moved to Dispatched.
        // The colon before orderRecord.Id binds the Apex variable
        // to the SOQL query.
        System.assertEquals(
            'Dispatched',
            updatedOrder.Status__c,
            'Order status should change to Dispatched after fulfillment.'
        );


        // Query all invoices associated with this order.
        // The query returns a list because zero, one, or multiple
        // invoices could exist.
        List<Invoice__c> invoices = [
            SELECT Id, Order__c
            FROM Invoice__c
            WHERE Order__c = :orderRecord.Id
        ];

        // Verify that exactly one invoice was created.
        // invoices.size() returns the number of records in the list.
        System.assertEquals(
            1,
            invoices.size(),
            'Exactly one invoice should be created for the fulfilled order.'
        );

        // Verify that the invoice is linked to the correct order.
        // invoices[0] accesses the first record in the list.
        System.assertEquals(
            orderRecord.Id,
            invoices[0].Order__c,
            'The invoice should belong to the fulfilled order.'
        );
    }
}
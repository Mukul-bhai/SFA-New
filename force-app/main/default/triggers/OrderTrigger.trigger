// Trigger on Order__c.
// Runs before an order is inserted or updated.
trigger OrderTrigger on Order__c (before insert, before update) {

    // Create a Set to store unique Outlet record IDs.
    Set<Id> outletIds = new Set<Id>();

    // Loop through all orders being inserted or updated.
    for (Order__c ord : Trigger.new) {

        // Check that the order has an outlet assigned
        // and that its Beat field is currently empty.
        if (ord.Outlet__c != null && ord.Beat__c == null) {

            // Store the outlet ID so we can retrieve its Beat.
            outletIds.add(ord.Outlet__c);
        }
    }

    // Query Salesforce only when there are outlet IDs to look up.
    if (!outletIds.isEmpty()) {

        // Retrieve the Outlet records and their associated Beat IDs.
        // Build a Map so each Outlet can be accessed quickly using its ID.
        Map<Id, Outlet__c> outletMap = new Map<Id, Outlet__c>(
            [
                SELECT Id, Beat__c
                FROM Outlet__c
                WHERE Id IN :outletIds
            ]
        );

        // Loop through the orders again to populate their Beat fields.
        for (Order__c ord : Trigger.new) {

            // Proceed when the order has an outlet, its Beat is blank,
            // and the outlet was found in the query result.
            if (
                ord.Outlet__c != null &&
                ord.Beat__c == null &&
                outletMap.containsKey(ord.Outlet__c)
            ) {

                // Copy the Beat ID from the related Outlet to the Order.
                // This automatically associates the order with the outlet's Beat.
                ord.Beat__c = outletMap.get(ord.Outlet__c).Beat__c;
            }
        }
    }
}
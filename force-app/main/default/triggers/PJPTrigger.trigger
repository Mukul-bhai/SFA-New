// Trigger on PJP__c.
// Runs before a PJP record is inserted or updated.
trigger PJPTrigger on PJP__c (before insert, before update) {

    // Store unique Employee record IDs.
    // These employees will be queried to get their manager and Salesforce user.
    Set<Id> empIds = new Set<Id>();

    // Loop through the PJP records being inserted or updated.
    for (PJP__c pjp : Trigger.new) {

        // Check that an Employee is selected and the Reporting Manager is empty.
        if (pjp.Employee__c != null && pjp.Reporting_Manager__c == null) {

            // Add the Employee ID to the set for querying.
            empIds.add(pjp.Employee__c);
        }
    }

    // Continue only if at least one Employee ID was collected.
    if (!empIds.isEmpty()) {

        // Query the related Employee records.
        // Fetch the Reporting Manager and Salesforce User fields.
        // The Map allows Employee records to be accessed quickly using their IDs.
        Map<Id, Employee__c> empMap = new Map<Id, Employee__c>(
            [
                SELECT Id, Reporting_Manager__c, User__c
                FROM Employee__c
                WHERE Id IN :empIds
            ]
        );

        // Loop through the PJP records again to populate missing values.
        for (PJP__c pjp : Trigger.new) {

            // Check that the Employee is selected,
            // the Reporting Manager is empty,
            // and the Employee exists in the queried Map.
            if (
                pjp.Employee__c != null &&
                pjp.Reporting_Manager__c == null &&
                empMap.containsKey(pjp.Employee__c)
            ) {

                // Get the related Employee record from the Map.
                Employee__c emp = empMap.get(pjp.Employee__c);

                // If the Employee has a Reporting Manager,
                // copy that manager to the PJP record.
                if (emp.Reporting_Manager__c != null) {
                    pjp.Reporting_Manager__c = emp.Reporting_Manager__c;
                }

                // If the PJP's User field is empty
                // and the Employee has a Salesforce User,
                // copy that User to the PJP record.
                if (pjp.User__c == null && emp.User__c != null) {
                    pjp.User__c = emp.User__c;
                }
            }
        }
    }

    // Automatically manage Approved_Date__c based on the PJP status.
    // This loop runs for both insert and update operations.
    for (PJP__c pjp : Trigger.new) {

        // On insert, there is no old record.
        // On update, get the record's previous values.
        PJP__c oldPjp = (Trigger.isUpdate && Trigger.oldMap != null)
            ? Trigger.oldMap.get(pjp.Id)
            : null;

        // Check whether the current PJP status is Approved.
        if (pjp.Status__c == 'Approved') {

            // Set the approval date if:
            // 1. This is a new record.
            // 2. The previous status was not Approved.
            // 3. The approval date is currently empty.
            if (
                oldPjp == null ||
                oldPjp.Status__c != 'Approved' ||
                pjp.Approved_Date__c == null
            ) {
                // Store the current date and time.
                pjp.Approved_Date__c = System.now();
            }

        // Check whether the status is changed back to a non-approved stage.
        } else if (
            pjp.Status__c == 'Draft' ||
            pjp.Status__c == 'Submitted' ||
            pjp.Status__c == 'Pending Approval'
        ) {

            // If the previous status was Approved,
            // clear the previously stored approval date.
            if (oldPjp != null && oldPjp.Status__c == 'Approved') {
                pjp.Approved_Date__c = null;
            }
        }
    }
}
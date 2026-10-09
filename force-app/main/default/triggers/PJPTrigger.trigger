trigger PJPTrigger on PJP__c (before insert, before update) {
    Set<Id> empIds = new Set<Id>();
    for (PJP__c pjp : Trigger.new) {
        if (pjp.Employee__c != null && pjp.Reporting_Manager__c == null) {
            empIds.add(pjp.Employee__c);
        }
    }

    if (!empIds.isEmpty()) {
        Map<Id, Employee__c> empMap = new Map<Id, Employee__c>(
            [SELECT Id, Reporting_Manager__c, User__c FROM Employee__c WHERE Id IN :empIds]
        );
        for (PJP__c pjp : Trigger.new) {
            if (pjp.Employee__c != null && pjp.Reporting_Manager__c == null && empMap.containsKey(pjp.Employee__c)) {
                Employee__c emp = empMap.get(pjp.Employee__c);
                if (emp.Reporting_Manager__c != null) {
                    pjp.Reporting_Manager__c = emp.Reporting_Manager__c;
                }
                if (pjp.User__c == null && emp.User__c != null) {
                    pjp.User__c = emp.User__c;
                }
            }
        }
    }

    // Auto-populate Approved_Date__c whenever Status becomes Approved
    for (PJP__c pjp : Trigger.new) {
        PJP__c oldPjp = (Trigger.isUpdate && Trigger.oldMap != null) ? Trigger.oldMap.get(pjp.Id) : null;
        if (pjp.Status__c == 'Approved') {
            if (oldPjp == null || oldPjp.Status__c != 'Approved' || pjp.Approved_Date__c == null) {
                pjp.Approved_Date__c = System.now();
            }
        } else if (pjp.Status__c == 'Draft' || pjp.Status__c == 'Submitted' || pjp.Status__c == 'Pending Approval') {
            if (oldPjp != null && oldPjp.Status__c == 'Approved') {
                pjp.Approved_Date__c = null;
            }
        }
    }
}

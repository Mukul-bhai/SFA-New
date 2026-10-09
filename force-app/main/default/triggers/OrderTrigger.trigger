trigger OrderTrigger on Order__c (before insert, before update) {
    Set<Id> outletIds = new Set<Id>();
    for (Order__c ord : Trigger.new) {
        if (ord.Outlet__c != null && ord.Beat__c == null) {
            outletIds.add(ord.Outlet__c);
        }
    }

    if (!outletIds.isEmpty()) {
        Map<Id, Outlet__c> outletMap = new Map<Id, Outlet__c>(
            [SELECT Id, Beat__c FROM Outlet__c WHERE Id IN :outletIds]
        );
        for (Order__c ord : Trigger.new) {
            if (ord.Outlet__c != null && ord.Beat__c == null && outletMap.containsKey(ord.Outlet__c)) {
                ord.Beat__c = outletMap.get(ord.Outlet__c).Beat__c;
            }
        }
    }
}

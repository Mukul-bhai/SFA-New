trigger OutletTrigger on Outlet__c (after insert, after update, after delete, after undelete) {
    Set<Id> beatIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUndelete) {
        for (Outlet__c o : Trigger.new) {
            if (o.Beat__c != null) {
                beatIds.add(o.Beat__c);
            }
        }
    } else if (Trigger.isUpdate) {
        for (Outlet__c o : Trigger.new) {
            Outlet__c oldO = Trigger.oldMap.get(o.Id);
            if (o.Beat__c != oldO.Beat__c) {
                if (o.Beat__c != null) beatIds.add(o.Beat__c);
                if (oldO.Beat__c != null) beatIds.add(oldO.Beat__c);
            }
        }
    } else if (Trigger.isDelete) {
        for (Outlet__c o : Trigger.old) {
            if (o.Beat__c != null) {
                beatIds.add(o.Beat__c);
            }
        }
    }

    if (!beatIds.isEmpty()) {
        SFARollupService.recalculateBeatOutlets(beatIds);
    }
}

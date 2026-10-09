trigger BeatTrigger on Beat__c (after insert, after update, after delete, after undelete) {
    Set<Id> pjpIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUndelete) {
        for (Beat__c b : Trigger.new) {
            if (b.PJP__c != null) {
                pjpIds.add(b.PJP__c);
            }
        }
    } else if (Trigger.isUpdate) {
        for (Beat__c b : Trigger.new) {
            Beat__c oldB = Trigger.oldMap.get(b.Id);
            if (b.PJP__c != oldB.PJP__c) {
                if (b.PJP__c != null) pjpIds.add(b.PJP__c);
                if (oldB.PJP__c != null) pjpIds.add(oldB.PJP__c);
            }
        }
    } else if (Trigger.isDelete) {
        for (Beat__c b : Trigger.old) {
            if (b.PJP__c != null) {
                pjpIds.add(b.PJP__c);
            }
        }
    }

    if (!pjpIds.isEmpty()) {
        SFARollupService.recalculatePJPTotals(pjpIds);
    }
}

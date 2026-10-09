public without sharing class SFARollupService {

    /**
     * Recalculates Total_Outlets__c on Beat__c and triggers PJP recalculation.
     */
    public static void recalculateBeatOutlets(Set<Id> beatIds) {
        if (beatIds == null || beatIds.isEmpty()) {
            return;
        }

        Map<Id, Beat__c> beatsToUpdate = new Map<Id, Beat__c>(
            [SELECT Id, Total_Outlets__c, PJP__c FROM Beat__c WHERE Id IN :beatIds]
        );

        if (beatsToUpdate.isEmpty()) {
            return;
        }

        Map<Id, Integer> beatOutletCountMap = new Map<Id, Integer>();
        for (Id bId : beatIds) {
            beatOutletCountMap.put(bId, 0);
        }

        for (AggregateResult ar : [
            SELECT Beat__c bId, COUNT(Id) totalCount 
            FROM Outlet__c 
            WHERE Beat__c IN :beatIds 
            GROUP BY Beat__c
        ]) {
            Id bId = (Id) ar.get('bId');
            Integer count = (Integer) ar.get('totalCount');
            beatOutletCountMap.put(bId, count);
        }

        Set<Id> pjpIds = new Set<Id>();
        List<Beat__c> updates = new List<Beat__c>();

        for (Beat__c b : beatsToUpdate.values()) {
            Integer newCount = beatOutletCountMap.get(b.Id);
            if (b.Total_Outlets__c != newCount) {
                b.Total_Outlets__c = newCount;
                updates.add(b);
            }
            if (b.PJP__c != null) {
                pjpIds.add(b.PJP__c);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }

        if (!pjpIds.isEmpty()) {
            recalculatePJPTotals(pjpIds);
        }
    }

    /**
     * Recalculates Total_Beats__c and Total_Outlets__c on PJP__c.
     */
    public static void recalculatePJPTotals(Set<Id> pjpIds) {
        if (pjpIds == null || pjpIds.isEmpty()) {
            return;
        }

        Map<Id, PJP__c> pjpsToUpdate = new Map<Id, PJP__c>(
            [SELECT Id, Total_Beats__c, Total_Outlets__c FROM PJP__c WHERE Id IN :pjpIds]
        );

        if (pjpsToUpdate.isEmpty()) {
            return;
        }

        // Count Beats grouped by PJP__c
        Map<Id, Integer> pjpBeatCountMap = new Map<Id, Integer>();
        for (Id pjpId : pjpIds) {
            pjpBeatCountMap.put(pjpId, 0);
        }

        for (AggregateResult ar : [
            SELECT PJP__c pId, COUNT(Id) totalCount 
            FROM Beat__c 
            WHERE PJP__c IN :pjpIds 
            GROUP BY PJP__c
        ]) {
            Id pId = (Id) ar.get('pId');
            Integer count = (Integer) ar.get('totalCount');
            pjpBeatCountMap.put(pId, count);
        }

        // Count Outlets grouped by Beat__r.PJP__c
        Map<Id, Integer> pjpOutletCountMap = new Map<Id, Integer>();
        for (Id pjpId : pjpIds) {
            pjpOutletCountMap.put(pjpId, 0);
        }

        for (AggregateResult ar : [
            SELECT Beat__r.PJP__c pId, COUNT(Id) totalCount 
            FROM Outlet__c 
            WHERE Beat__r.PJP__c IN :pjpIds 
            GROUP BY Beat__r.PJP__c
        ]) {
            Id pId = (Id) ar.get('pId');
            Integer count = (Integer) ar.get('totalCount');
            pjpOutletCountMap.put(pId, count);
        }

        List<PJP__c> updates = new List<PJP__c>();
        for (PJP__c pjp : pjpsToUpdate.values()) {
            Integer beatCount = pjpBeatCountMap.get(pjp.Id);
            Integer outletCount = pjpOutletCountMap.get(pjp.Id);
            Boolean changed = false;

            if (pjp.Total_Beats__c != beatCount) {
                pjp.Total_Beats__c = beatCount;
                changed = true;
            }
            if (pjp.Total_Outlets__c != outletCount) {
                pjp.Total_Outlets__c = outletCount;
                changed = true;
            }

            if (changed) {
                updates.add(pjp);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    /**
     * Resynchronizes all existing Beats and PJPs in the entire org.
     */
    public static void resyncAll() {
        Set<Id> allBeatIds = new Map<Id, Beat__c>([SELECT Id FROM Beat__c]).keySet();
        recalculateBeatOutlets(allBeatIds);

        Set<Id> allPjpIds = new Map<Id, PJP__c>([SELECT Id FROM PJP__c]).keySet();
        recalculatePJPTotals(allPjpIds);
    }
}

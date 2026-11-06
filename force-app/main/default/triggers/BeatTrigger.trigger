// Trigger on the Beat__c object.
// Runs after a record is inserted, updated, deleted, or undeleted.
trigger BeatTrigger on Beat__c (
    after insert,
    after update,
    after delete,
    after undelete
) {

    // Stores the IDs of all PJP records whose beat totals may need recalculation.
    // Set automatically prevents duplicate PJP IDs.
    Set<Id> pjpIds = new Set<Id>();

    // INSERT: Runs when new Beat records are created.
    // UNDELETE: Runs when deleted Beat records are restored.
    if (Trigger.isInsert || Trigger.isUndelete) {

        // Loop through all newly created or restored Beat records.
        for (Beat__c b : Trigger.new) {

            // Check whether the Beat is associated with a PJP.
            if (b.PJP__c != null) {

                // Add the related PJP ID to the set for recalculation.
                pjpIds.add(b.PJP__c);
            }
        }

    // UPDATE: Runs when existing Beat records are modified.
    } else if (Trigger.isUpdate) {

        // Loop through the updated Beat records.
        for (Beat__c b : Trigger.new) {

            // Get the previous version of this Beat record.
            Beat__c oldB = Trigger.oldMap.get(b.Id);

            // Check whether the Beat's associated PJP has changed.
            if (b.PJP__c != oldB.PJP__c) {

                // Add the new PJP ID if the Beat has been assigned to a PJP.
                if (b.PJP__c != null) {
                    pjpIds.add(b.PJP__c);
                }

                // Add the old PJP ID if the Beat was previously assigned to one.
                // Its totals must also be recalculated because the Beat moved away.
                if (oldB.PJP__c != null) {
                    pjpIds.add(oldB.PJP__c);
                }
            }
        }

    // DELETE: Runs when Beat records are deleted.
    } else if (Trigger.isDelete) {

        // Trigger.old contains the records before deletion.
        for (Beat__c b : Trigger.old) {

            // Check whether the deleted Beat was linked to a PJP.
            if (b.PJP__c != null) {

                // Add the related PJP so its totals can be recalculated.
                pjpIds.add(b.PJP__c);
            }
        }
    }

    // Continue only if at least one related PJP was identified.
    if (!pjpIds.isEmpty()) {

        // Call the service class to recalculate the PJP totals.
        // The service class contains the actual calculation and update logic.
        SFARollupService.recalculatePJPTotals(pjpIds);
    }
}
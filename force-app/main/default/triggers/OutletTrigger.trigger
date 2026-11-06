// Trigger on Outlet__c.
// Runs after an outlet is inserted, updated, deleted, or restored.
trigger OutletTrigger on Outlet__c (
    after insert,
    after update,
    after delete,
    after undelete
) {

    // Store unique Beat record IDs whose outlet totals need recalculation.
    Set<Id> beatIds = new Set<Id>();

    // INSERT: Runs when new outlets are created.
    // UNDELETE: Runs when deleted outlets are restored.
    if (Trigger.isInsert || Trigger.isUndelete) {

        // Loop through newly created or restored outlets.
        for (Outlet__c o : Trigger.new) {

            // Check whether the outlet is associated with a Beat.
            if (o.Beat__c != null) {

                // Add the related Beat ID to the set.
                beatIds.add(o.Beat__c);
            }
        }

    // UPDATE: Runs when existing outlets are modified.
    } else if (Trigger.isUpdate) {

        // Loop through the updated outlet records.
        for (Outlet__c o : Trigger.new) {

            // Retrieve the outlet's values before the update.
            Outlet__c oldO = Trigger.oldMap.get(o.Id);

            // Check whether the outlet's assigned Beat has changed.
            if (o.Beat__c != oldO.Beat__c) {

                // Add the new Beat ID if the outlet now belongs to a Beat.
                if (o.Beat__c != null) {
                    beatIds.add(o.Beat__c);
                }

                // Add the old Beat ID because its outlet count may decrease.
                if (oldO.Beat__c != null) {
                    beatIds.add(oldO.Beat__c);
                }
            }
        }

    // DELETE: Runs when outlets are deleted.
    } else if (Trigger.isDelete) {

        // Trigger.old contains the outlet records before deletion.
        for (Outlet__c o : Trigger.old) {

            // Check whether the deleted outlet was assigned to a Beat.
            if (o.Beat__c != null) {

                // Add the Beat whose outlet count needs recalculation.
                beatIds.add(o.Beat__c);
            }
        }
    }

    // Call the rollup service only when at least one Beat was identified.
    if (!beatIds.isEmpty()) {

        // Recalculate the outlet totals for the affected Beat records.
        // The actual counting and updating logic is in SFARollupService.
        SFARollupService.recalculateBeatOutlets(beatIds);
    }
}
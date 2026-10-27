List<Distributor__c> dists = [SELECT Id, Name, Distributor_Code__c, DMS_Portal_Enabled__c, DMS_Username__c, DMS_Password__c FROM Distributor__c];

for (Distributor__c d : dists) {
    if (d.Distributor_Code__c == 'DIST-PRI-001') {
        d.DMS_Portal_Enabled__c = true;
        d.DMS_Username__c = 'apex_dist';
        d.DMS_Password__c = 'Apex@123';
    } else if (d.Distributor_Code__c == 'THA-001') {
        d.DMS_Portal_Enabled__c = true;
        d.DMS_Username__c = 'thakur_dist';
        d.DMS_Password__c = 'Thakur@123';
    } else {
        d.DMS_Portal_Enabled__c = false;
        d.DMS_Username__c = null;
        d.DMS_Password__c = null;
    }
}
update dists;

System.debug('Distributor DMS credentials updated successfully.');

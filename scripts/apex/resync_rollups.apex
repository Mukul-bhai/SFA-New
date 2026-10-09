SFARollupService.resyncAll();

List<PJP__c> pjps = [SELECT Id, Name, Total_Beats__c, Total_Outlets__c FROM PJP__c];
for (PJP__c pjp : pjps) {
    System.debug('PJP: ' + pjp.Name + ' => Total Beats: ' + pjp.Total_Beats__c + ', Total Outlets: ' + pjp.Total_Outlets__c);
}

List<Beat__c> beats = [SELECT Id, Name, PJP__r.Name, Total_Outlets__c FROM Beat__c];
for (Beat__c b : beats) {
    System.debug('Beat: ' + b.Name + ' (PJP: ' + b.PJP__r.Name + ') => Total Outlets: ' + b.Total_Outlets__c);
}

// Test trigger auto-populating Approved_Date__c
PJP__c testPjp = [SELECT Id, Name, Status__c, Approved_Date__c FROM PJP__c WHERE Name LIKE '%Mukul%' LIMIT 1];
System.debug('Before test: Status = ' + testPjp.Status__c + ', Approved Date = ' + testPjp.Approved_Date__c);

// Simulate setting to Approved
testPjp.Status__c = 'Approved';
update testPjp;

PJP__c verifiedPjp = [SELECT Id, Name, Status__c, Approved_Date__c FROM PJP__c WHERE Id = :testPjp.Id];
System.debug('After setting Approved: Status = ' + verifiedPjp.Status__c + ', Approved Date = ' + verifiedPjp.Approved_Date__c);

if (verifiedPjp.Approved_Date__c != null) {
    System.debug('SUCCESS: Approved_Date__c was automatically populated!');
} else {
    System.debug('FAILURE: Approved_Date__c is null!');
}

// Reset back to Draft for user testing
testPjp.Status__c = 'Draft';
update testPjp;

PJP__c resetPjp = [SELECT Id, Name, Status__c, Approved_Date__c FROM PJP__c WHERE Id = :testPjp.Id];
System.debug('After reset back to Draft: Status = ' + resetPjp.Status__c + ', Approved Date = ' + resetPjp.Approved_Date__c);

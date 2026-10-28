// Test inserting a Return_Order__c
Distributor__c d = [SELECT Id FROM Distributor__c LIMIT 1];
String rNum = 'RET-PRM-' + String.valueOf(DateTime.now().getTime());
Return_Order__c ro = new Return_Order__c(
    Name = rNum,
    Return_Number__c = rNum,
    Distributor__c = d.Id,
    Return_Type__c = 'Primary',
    Return_Reason__c = 'Expired Stock',
    Total_Return_Amount__c = 1032,
    Status__c = 'Submitted',
    Return_Date__c = Date.today(),
    Scanned_Barcode__c = 'CASE-PGLU-B2601-E5-106',
    Barcode_Type__c = 'Case Barcode',
    Verification_Status__c = 'Expired Stock'
);
insert ro;
System.debug('Successfully inserted Return_Order__c with Id: ' + ro.Id);

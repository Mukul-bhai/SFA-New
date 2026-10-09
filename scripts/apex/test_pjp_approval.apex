PJP__c pjp = [SELECT Id, Name, Status__c, Reporting_Manager__c, Employee__r.Name FROM PJP__c WHERE Name LIKE '%Viresh%' LIMIT 1];
System.debug('Initial PJP Status: ' + pjp.Status__c);

// 1. Submit for Approval
String submitMsg = PJPApprovalController.submitForApproval(pjp.Id, 'Viresh submitting PJP for October 2026 routes.');
System.debug('Submit Result: ' + submitMsg);

pjp = [SELECT Id, Status__c FROM PJP__c WHERE Id = :pjp.Id];
System.debug('PJP Status after Submit: ' + pjp.Status__c);
System.assert(pjp.Status__c == 'Submitted' || pjp.Status__c == 'Pending Approval', 'Status should be Submitted');

// 2. Approve PJP (as Manager Dinesh / Admin)
String approveMsg = PJPApprovalController.processApproval(pjp.Id, 'Approve', 'Dinesh (L2) approved route plan.');
System.debug('Approve Result: ' + approveMsg);

pjp = [SELECT Id, Status__c, Approved_Date__c, Approval_Comments__c FROM PJP__c WHERE Id = :pjp.Id];
System.debug('PJP Status after Approval: ' + pjp.Status__c);
System.debug('Approved Date: ' + pjp.Approved_Date__c);
System.debug('Approval Comments: ' + pjp.Approval_Comments__c);
System.assert(pjp.Status__c == 'Approved', 'Status should be Approved');

// Reset to Draft for the user to demonstrate live clicking
pjp.Status__c = 'Draft';
update pjp;
System.debug('PJP reset to Draft for user interactive demo: ' + pjp.Status__c);

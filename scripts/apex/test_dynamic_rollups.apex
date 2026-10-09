Beat__c ggRoad = [SELECT Id, Total_Outlets__c, PJP__c FROM Beat__c WHERE Name = 'GG-Road' LIMIT 1];
PJP__c mukulPjp = [SELECT Id, Total_Beats__c, Total_Outlets__c FROM PJP__c WHERE Id = :ggRoad.PJP__c];

System.debug('--- INITIAL STATE ---');
System.debug('GG-Road Outlets: ' + ggRoad.Total_Outlets__c);
System.debug('Mukul PJP Beats: ' + mukulPjp.Total_Beats__c + ', Outlets: ' + mukulPjp.Total_Outlets__c);

// 1. Create a new test Outlet
Outlet__c tempOutlet = new Outlet__c(
    Name = 'Test Dynamic Shop',
    Beat__c = ggRoad.Id
);
insert tempOutlet;

ggRoad = [SELECT Id, Total_Outlets__c FROM Beat__c WHERE Id = :ggRoad.Id];
mukulPjp = [SELECT Id, Total_Beats__c, Total_Outlets__c FROM PJP__c WHERE Id = :mukulPjp.Id];
System.debug('--- AFTER ADDING 1 OUTLET ---');
System.debug('GG-Road Outlets: ' + ggRoad.Total_Outlets__c + ' (Expected: 3)');
System.debug('Mukul PJP Outlets: ' + mukulPjp.Total_Outlets__c + ' (Expected: 3)');
System.assertEquals(3, ggRoad.Total_Outlets__c);
System.assertEquals(3, mukulPjp.Total_Outlets__c);

// 2. Delete the test Outlet
delete tempOutlet;

ggRoad = [SELECT Id, Total_Outlets__c FROM Beat__c WHERE Id = :ggRoad.Id];
mukulPjp = [SELECT Id, Total_Beats__c, Total_Outlets__c FROM PJP__c WHERE Id = :mukulPjp.Id];
System.debug('--- AFTER DELETING THE OUTLET ---');
System.debug('GG-Road Outlets: ' + ggRoad.Total_Outlets__c + ' (Expected: 2)');
System.debug('Mukul PJP Outlets: ' + mukulPjp.Total_Outlets__c + ' (Expected: 2)');
System.assertEquals(2, ggRoad.Total_Outlets__c);
System.assertEquals(2, mukulPjp.Total_Outlets__c);

System.debug('ALL DYNAMIC ROLLUP TESTS PASSED SUCCESSFULLY!');

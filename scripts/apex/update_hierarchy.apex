List<Employee__c> emps = [SELECT Id, Name, Employee_Code__c, Hierarchy_Level__c FROM Employee__c];
for (Employee__c e : emps) {
    if (e.Name.contains('Viresh')) {
        e.Hierarchy_Level__c = 'Sales Executive';
    } else if (e.Name.contains('Dinesh')) {
        e.Hierarchy_Level__c = 'Sales Manager';
    } else if (e.Name.contains('Aishwarya')) {
        e.Hierarchy_Level__c = 'Admin';
    } else {
        e.Hierarchy_Level__c = 'Sales Executive';
    }
}
update emps;
System.debug('Updated employees hierarchy successfully: ' + emps);

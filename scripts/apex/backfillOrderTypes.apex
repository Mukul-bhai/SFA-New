List<Order__c> toUpd = new List<Order__c>();
for (Order__c o : [SELECT Id, Order_Type__c, Retailer__c, Outlet__c, Primary_Distributor__c FROM Order__c WHERE Order_Type__c = null]) {
    if (o.Retailer__c != null || o.Outlet__c != null) {
        o.Order_Type__c = 'Secondary';
    } else {
        o.Order_Type__c = 'Primary';
    }
    toUpd.add(o);
}
if (!toUpd.isEmpty()) {
    update toUpd;
    System.debug('Backfilled ' + toUpd.size() + ' orders.');
} else {
    System.debug('No orders needed backfilling.');
}

List<Product2> prods = [SELECT Id FROM Product2 FOR VIEW];
List<Distributor__c> dists = [SELECT Id FROM Distributor__c FOR VIEW];
List<Warehouse__c> whs = [SELECT Id FROM Warehouse__c FOR VIEW];
List<Retailer__c> rets = [SELECT Id FROM Retailer__c FOR VIEW];
System.debug('Indexed records for view: ' + prods.size() + ' products.');

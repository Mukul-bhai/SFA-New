Distributor__c dist = [SELECT Id FROM Distributor__c WHERE Distributor_Code__c = 'DIST-PRI-001' LIMIT 1];
List<Product__c> prods = [SELECT Id, Name, Product_Code__c, RBP__c, MRP__c FROM Product__c LIMIT 3];

List<Map<String, Object>> items = new List<Map<String, Object>>();
for (Product__c p : prods) {
    Map<String, Object> itm = new Map<String, Object>();
    itm.put('productId', p.Id);
    itm.put('productName', p.Name);
    itm.put('productCode', p.Product_Code__c);
    itm.put('quantity', 25);
    itm.put('unitPrice', p.RBP__c != null ? p.RBP__c : 80);
    itm.put('mrp', p.MRP__c != null ? p.MRP__c : 100);
    items.add(itm);
}

String itemsJson = JSON.serialize(items);
Map<String, Object> res = DmsPortalController.createBulkPrimaryOrder(dist.Id, 'PO-BULK-VERIFY-001', 'Multi-SKU Primary Order Test', itemsJson);
System.debug('Bulk Primary Order Result: ' + res);

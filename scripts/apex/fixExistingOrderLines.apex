List<Order__c> ords = [SELECT Id, Total_Amount__c, (SELECT Id FROM Order_Lines__r) FROM Order__c WHERE Id IN ('a08g800000cG6bRAAS', 'a08g800000cG65BAAS')];
List<Product__c> prods = [SELECT Id, Name, Product_Code__c, RBP__c, MRP__c FROM Product__c LIMIT 2];

List<Order_Line__c> lines = new List<Order_Line__c>();
for (Order__c ord : ords) {
    if (ord.Order_Lines__r.isEmpty()) {
        Order_Line__c l1 = new Order_Line__c(
            Order__c = ord.Id,
            Name = prods[0].Name,
            Product_Name__c = prods[0].Name,
            Product_Custom__c = prods[0].Id,
            SKU__c = prods[0].Product_Code__c,
            Quantity__c = 60,
            Unit_Price__c = prods[0].RBP__c != null ? prods[0].RBP__c : 21.5
        );
        Order_Line__c l2 = new Order_Line__c(
            Order__c = ord.Id,
            Name = prods[1].Name,
            Product_Name__c = prods[1].Name,
            Product_Custom__c = prods[1].Id,
            SKU__c = prods[1].Product_Code__c,
            Quantity__c = 40,
            Unit_Price__c = prods[1].RBP__c != null ? prods[1].RBP__c : 17.2
        );
        lines.add(l1);
        lines.add(l2);
    }
}

if (!lines.isEmpty()) {
    insert lines;
    System.debug('Inserted ' + lines.size() + ' lines for existing orders.');
}

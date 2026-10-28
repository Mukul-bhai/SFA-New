// Seed realistic Parle Product Cases with Two-Tier Barcodes (Case & Packet)
List<Distributor__c> distList = [SELECT Id, Name FROM Distributor__c WHERE Status__c = 'Active' LIMIT 5];
if (distList.isEmpty()) {
    distList = [SELECT Id, Name FROM Distributor__c LIMIT 5];
}
Id primeDistId = !distList.isEmpty() ? distList[0].Id : null;
Id secondDistId = distList.size() > 1 ? distList[1].Id : primeDistId;

List<Product__c> prods = [
    SELECT Id, Name, Product_Code__c, SKU__c, MRP__c, RBP__c, Category__c 
    FROM Product__c 
    LIMIT 20
];

System.debug('Found ' + prods.size() + ' products and ' + distList.size() + ' distributors.');

List<Product_Case__c> casesToInsert = new List<Product_Case__c>();

// Clean up any old test cases first if needed
delete [SELECT Id FROM Product_Case__c WHERE Case_Barcode__c LIKE 'CASE-%'];

Integer seq = 100;
for (Product__c p : prods) {
    String pName = p.Name != null ? p.Name : 'Parle Product';
    String prefix = 'PGLU';
    Integer units = 48;
    if (pName.containsIgnoreCase('Monaco')) { prefix = 'MONA'; units = 36; }
    else if (pName.containsIgnoreCase('Krackjack')) { prefix = 'KJCK'; units = 36; }
    else if (pName.containsIgnoreCase('Hide')) { prefix = 'HNDS'; units = 24; }
    else if (pName.containsIgnoreCase('20-20')) { prefix = 'TTW'; units = 40; }
    else if (pName.containsIgnoreCase('Milano')) { prefix = 'MIL'; units = 24; }
    else if (pName.containsIgnoreCase('Bourbon')) { prefix = 'BRB'; units = 30; }
    else if (pName.containsIgnoreCase('Kopiko')) { prefix = 'KOP'; units = 12; }

    // Tier 1: Fresh Batch (MFG: Sep 2026, EXP: Mar 2027)
    String batchFresh = 'B2609-F' + String.valueOf(Math.mod(seq, 10));
    String pktFresh = 'PKT-' + prefix + '-' + batchFresh;
    for (Integer i = 1; i <= 3; i++) {
        seq++;
        casesToInsert.add(new Product_Case__c(
            Product_Custom__c = p.Id,
            Distributor__c = (i == 1 ? secondDistId : primeDistId),
            Case_Barcode__c = 'CASE-' + prefix + '-' + batchFresh + '-' + String.valueOf(seq),
            Packet_Barcode__c = pktFresh,
            Batch_Number__c = batchFresh,
            Manufacturing_Date__c = Date.newInstance(2026, 9, 15),
            Expiry_Date__c = Date.newInstance(2027, 3, 15),
            Units_Per_Case__c = units,
            Status__c = 'Delivered'
        ));
    }

    // Tier 2: Near-Expiry Batch (MFG: May 2026, EXP: Nov 10, 2026 - ~14 days left!)
    String batchNear = 'B2605-N' + String.valueOf(Math.mod(seq, 10));
    String pktNear = 'PKT-' + prefix + '-' + batchNear;
    for (Integer i = 1; i <= 2; i++) {
        seq++;
        casesToInsert.add(new Product_Case__c(
            Product_Custom__c = p.Id,
            Distributor__c = primeDistId,
            Case_Barcode__c = 'CASE-' + prefix + '-' + batchNear + '-' + String.valueOf(seq),
            Packet_Barcode__c = pktNear,
            Batch_Number__c = batchNear,
            Manufacturing_Date__c = Date.newInstance(2026, 5, 10),
            Expiry_Date__c = Date.newInstance(2026, 11, 10),
            Units_Per_Case__c = units,
            Status__c = 'Delivered'
        ));
    }

    // Tier 3: Expired Batch (MFG: Jan 2026, EXP: Jul 2026 - Already Expired!)
    String batchExp = 'B2601-E' + String.valueOf(Math.mod(seq, 10));
    String pktExp = 'PKT-' + prefix + '-' + batchExp;
    for (Integer i = 1; i <= 2; i++) {
        seq++;
        casesToInsert.add(new Product_Case__c(
            Product_Custom__c = p.Id,
            Distributor__c = primeDistId,
            Case_Barcode__c = 'CASE-' + prefix + '-' + batchExp + '-' + String.valueOf(seq),
            Packet_Barcode__c = pktExp,
            Batch_Number__c = batchExp,
            Manufacturing_Date__c = Date.newInstance(2026, 1, 20),
            Expiry_Date__c = Date.newInstance(2026, 7, 20),
            Units_Per_Case__c = units,
            Status__c = 'Delivered'
        ));
    }
}

if (!casesToInsert.isEmpty()) {
    insert casesToInsert;
    System.debug('Successfully created ' + casesToInsert.size() + ' Product_Case__c records with Two-Tier Barcodes!');
}

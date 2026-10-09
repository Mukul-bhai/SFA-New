// Seed Data Script for SFA + DMS Salesforce Core Cloud
System.debug('--- Beginning SFA/DMS Seed Data Insertion ---');

// 1. Clean existing test data (optional or safe upsert)
delete [SELECT Id FROM Order_Line__c];
delete [SELECT Id FROM Order__c];
delete [SELECT Id FROM Inventory_Ledger__c];
delete [SELECT Id FROM Inventory_Batch__c];
delete [SELECT Id FROM Inventory__c];
delete [SELECT Id FROM Retailer_Beat_Mapping__c];
delete [SELECT Id FROM Beat__c];
delete [SELECT Id FROM Retailer__c];
delete [SELECT Id FROM Warehouse__c];
delete [SELECT Id FROM Distributor__c];
delete [SELECT Id FROM Territory__c];

// 2. Insert Territory
Territory__c terr = new Territory__c(
    Name = 'Mumbai Central Territory',
    Territory_Code__c = 'TERR-MUM-01',
    Region__c = 'West India'
);
insert terr;
System.debug('Created Territory: ' + terr.Id);

// 3. Insert Contacts for Distributor contact persons
Contact c1 = new Contact(FirstName = 'Vikram', LastName = 'Malhotra', Email = 'vikram@apextraders.com');
Contact c2 = new Contact(FirstName = 'Rajesh', LastName = 'Singhania', Email = 'rajesh@zenithlogistics.com');
insert new List<Contact>{ c1, c2 };

// 4. Insert Distributors
Distributor__c distPri = new Distributor__c(
    Name = 'Apex Traders Primary',
    Distributor_Code__c = 'DIST-PRI-001',
    Status__c = 'Active',
    Credit_Limit__c = 500000,
    Current_Outstanding__c = 120000,
    Contact_Person__c = c1.Id,
    GSTIN__c = '27AABCT1332L1Z5'
);
Distributor__c distBak = new Distributor__c(
    Name = 'Zenith Logistics Backup',
    Distributor_Code__c = 'DIST-BAK-002',
    Status__c = 'Active',
    Credit_Limit__c = 300000,
    Current_Outstanding__c = 45000,
    Contact_Person__c = c2.Id,
    GSTIN__c = '27BBBPZ8821M2Z3'
);
insert new List<Distributor__c>{ distPri, distBak };
System.debug('Created Distributors');

// 4. Insert Warehouses
Warehouse__c whPri = new Warehouse__c(
    Name = 'Primary Central Depot A',
    Warehouse_Code__c = 'WH-PRI-A',
    Distributor__c = distPri.Id,
    Address__c = 'Plot 42, Industrial Area Phase 1, Mumbai',
    Is_Active__c = true
);
Warehouse__c whBak = new Warehouse__c(
    Name = 'Backup Regional Depot B',
    Warehouse_Code__c = 'WH-BAK-B',
    Distributor__c = distBak.Id,
    Address__c = 'Warehouse Hub 9, Ring Road, Pune',
    Is_Active__c = true
);
insert new List<Warehouse__c>{ whPri, whBak };
System.debug('Created Warehouses');

// 5. Update Distributors with Default Warehouses
distPri.Default_Warehouse__c = whPri.Id;
distBak.Default_Warehouse__c = whBak.Id;
update new List<Distributor__c>{ distPri, distBak };

// 6. Insert Retailers
Retailer__c ret1 = new Retailer__c(
    Name = 'Gupta Supermarket',
    Retailer_Code__c = 'RET-1001',
    Shop_Name__c = 'Gupta Kirana & General Store',
    Owner_Phone__c = '+91 98765 43210',
    Territory__c = terr.Id,
    Primary_Distributor__c = distPri.Id,
    Backup_Distributor__c = distBak.Id,
    Allow_Backup_Fulfillment__c = true,
    Credit_Limit__c = 50000,
    Outstanding_Balance__c = 12000,
    Credit_Hold__c = false,
    Geolocation__Latitude__s = 19.0760,
    Geolocation__Longitude__s = 72.8777,
    Geofence_Radius_Meters__c = 100,
    Verification_Status__c = 'Verified'
);
Retailer__c ret2 = new Retailer__c(
    Name = 'Sharma Departmental Store',
    Retailer_Code__c = 'RET-1002',
    Shop_Name__c = 'Sharma Daily Needs',
    Owner_Phone__c = '+91 98111 22233',
    Territory__c = terr.Id,
    Primary_Distributor__c = distPri.Id,
    Backup_Distributor__c = null,
    Allow_Backup_Fulfillment__c = false,
    Credit_Limit__c = 25000,
    Outstanding_Balance__c = 27500,
    Credit_Hold__c = true,
    Geolocation__Latitude__s = 18.5204,
    Geolocation__Longitude__s = 73.8567,
    Geofence_Radius_Meters__c = 100,
    Verification_Status__c = 'Verified'
);
insert new List<Retailer__c>{ ret1, ret2 };
System.debug('Created Retailers');

// 7. Insert or Retrieve Products
List<Product2> existingProds = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN ('SHMP-200', 'SOAP-125', 'TEA-100')];
delete existingProds;

Product2 prodShmp = new Product2(
    Name = 'Herbal Shampoo 200ml',
    ProductCode = 'SHMP-200',
    Description = 'Natural herbal formula with aloe vera',
    IsActive = true
);
Product2 prodSoap = new Product2(
    Name = 'Neem Glow Soap 125g',
    ProductCode = 'SOAP-125',
    Description = 'Antibacterial neem body soap',
    IsActive = true
);
Product2 prodTea = new Product2(
    Name = 'Organic Green Tea 100g',
    ProductCode = 'TEA-100',
    Description = 'Pure Darjeeling whole leaf green tea',
    IsActive = true
);
insert new List<Product2>{ prodShmp, prodSoap, prodTea };
System.debug('Created Products');

// 8. Insert Inventories (Multi-Bucket Stock)
Inventory__c invPriShmp = new Inventory__c(
    Warehouse__c = whPri.Id,
    Product__c = prodShmp.Id,
    Warehouse_Product_Key__c = whPri.Id + '_' + prodShmp.Id,
    Physical_Stock__c = 150,
    Reserved_Stock__c = 80,
    Blocked_Stock__c = 0,
    Damaged_Stock__c = 0,
    Expired_Stock__c = 0
);
Inventory__c invPriSoap = new Inventory__c(
    Warehouse__c = whPri.Id,
    Product__c = prodSoap.Id,
    Warehouse_Product_Key__c = whPri.Id + '_' + prodSoap.Id,
    Physical_Stock__c = 300,
    Reserved_Stock__c = 50,
    Blocked_Stock__c = 10,
    Damaged_Stock__c = 5,
    Expired_Stock__c = 0
);
Inventory__c invPriTea = new Inventory__c(
    Warehouse__c = whPri.Id,
    Product__c = prodTea.Id,
    Warehouse_Product_Key__c = whPri.Id + '_' + prodTea.Id,
    Physical_Stock__c = 100,
    Reserved_Stock__c = 15,
    Blocked_Stock__c = 0,
    Damaged_Stock__c = 0,
    Expired_Stock__c = 0
);

Inventory__c invBakShmp = new Inventory__c(
    Warehouse__c = whBak.Id,
    Product__c = prodShmp.Id,
    Warehouse_Product_Key__c = whBak.Id + '_' + prodShmp.Id,
    Physical_Stock__c = 200,
    Reserved_Stock__c = 20,
    Blocked_Stock__c = 0,
    Damaged_Stock__c = 0,
    Expired_Stock__c = 0
);
Inventory__c invBakSoap = new Inventory__c(
    Warehouse__c = whBak.Id,
    Product__c = prodSoap.Id,
    Warehouse_Product_Key__c = whBak.Id + '_' + prodSoap.Id,
    Physical_Stock__c = 150,
    Reserved_Stock__c = 0,
    Blocked_Stock__c = 0,
    Damaged_Stock__c = 0,
    Expired_Stock__c = 0
);
Inventory__c invBakTea = new Inventory__c(
    Warehouse__c = whBak.Id,
    Product__c = prodTea.Id,
    Warehouse_Product_Key__c = whBak.Id + '_' + prodTea.Id,
    Physical_Stock__c = 80,
    Reserved_Stock__c = 0,
    Blocked_Stock__c = 0,
    Damaged_Stock__c = 0,
    Expired_Stock__c = 0
);
insert new List<Inventory__c>{ invPriShmp, invPriSoap, invPriTea, invBakShmp, invBakSoap, invBakTea };
System.debug('Created Inventories across Warehouses');

// 9. Insert Beat & Executive Assignment
Id currentUserId = UserInfo.getUserId();
Beat__c beatMon = new Beat__c(
    Name = 'Monday Central Market Beat',
    Beat_Code__c = 'BEAT-MUM-MON',
    Assigned_Executive__c = currentUserId,
    Territory__c = terr.Id,
    Day_Of_Week__c = 'Monday'
);
insert beatMon;

Retailer_Beat_Mapping__c rbm1 = new Retailer_Beat_Mapping__c(
    Beat__c = beatMon.Id,
    Retailer__c = ret1.Id,
    Sequence_Order__c = 1
);
Retailer_Beat_Mapping__c rbm2 = new Retailer_Beat_Mapping__c(
    Beat__c = beatMon.Id,
    Retailer__c = ret2.Id,
    Sequence_Order__c = 2
);
insert new List<Retailer_Beat_Mapping__c>{ rbm1, rbm2 };
System.debug('Created Beats and Retailer Mappings');

// 10. Insert a Seed Sample Order & Lines
Order__c ord = new Order__c(
    Retailer__c = ret1.Id,
    Primary_Distributor__c = distPri.Id,
    Sales_Executive__c = currentUserId,
    Status__c = 'Allocated',
    Total_Amount__c = 9600,
    Idempotency_Key__c = 'UUID-SEED-INIT-001',
    Order_Date__c = System.now().addHours(-2)
);
insert ord;

Order_Line__c line1 = new Order_Line__c(
    Order__c = ord.Id,
    Product__c = prodShmp.Id,
    Quantity__c = 50,
    Unit_Price__c = 120,
    Fulfilling_Distributor__c = distPri.Id,
    Fulfillment_Status__c = 'Allocated_Primary'
);
Order_Line__c line2 = new Order_Line__c(
    Order__c = ord.Id,
    Product__c = prodSoap.Id,
    Quantity__c = 80,
    Unit_Price__c = 45,
    Fulfilling_Distributor__c = distPri.Id,
    Fulfillment_Status__c = 'Allocated_Primary'
);
insert new List<Order_Line__c>{ line1, line2 };
System.debug('Created Seed Order and Order Lines');

System.debug('=== SFA/DMS Seed Data Finished Successfully ===');

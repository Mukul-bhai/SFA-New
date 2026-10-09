// Seed complete SFA Data for Slide 8 and Slide 11
System.debug('Starting SFA data seeding...');

// 1. Assign SFA_DMS_Admin Permission Set to Mukul & Nayan if not already assigned
PermissionSet psAdmin = [SELECT Id FROM PermissionSet WHERE Name = 'SFA_DMS_Admin' LIMIT 1];
for (User u : [SELECT Id, Username FROM User WHERE (Username LIKE '%nayan%' OR Username LIKE '%mukul%') AND IsActive = true]) {
    Integer existing = [SELECT count() FROM PermissionSetAssignment WHERE AssigneeId = :u.Id AND PermissionSetId = :psAdmin.Id];
    if (existing == 0) {
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = psAdmin.Id);
        System.debug('Assigned SFA_DMS_Admin to ' + u.Username);
    }
}

// 2. Seed Products (Slide 11 Biscuit Catalog + Scheme gift products)
List<Product__c> products = new List<Product__c>{
    new Product__c(
        Name = 'Parle-G Original Glucose Biscuit',
        Product_Code__c = 'P-GLU-001',
        SKU__c = 'SKU-GLU-250G',
        Category__c = 'Biscuits',
        Brand__c = 'Parle',
        Sub_Brand__c = 'Parle-G',
        Brand_Alias__c = 'G-Man',
        Flavour__c = 'Glucose / Regular',
        Variant__c = 'Standard Pack 250g',
        Package_Type__c = 'Packet',
        Unit_Conversion__c = 24,
        Batch_No__c = 'BATCH-2026-PG-01',
        Quantity__c = 1500,
        Available_Stock__c = 1500,
        MRP__c = 25.00,
        RBP__c = 21.50,
        GST_Percentage__c = 18.0,
        Manufacturing_Date__c = Date.today().addDays(-20),
        Expiry_Date__c = Date.today().addMonths(9),
        Product_Image__c = 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=300',
        Is_Active__c = true
    ),
    new Product__c(
        Name = 'Monaco Classic Salted Crackers',
        Product_Code__c = 'P-MON-002',
        SKU__c = 'SKU-MON-120G',
        Category__c = 'Biscuits',
        Brand__c = 'Parle',
        Sub_Brand__c = 'Monaco',
        Brand_Alias__c = 'Monaco Salted',
        Flavour__c = 'Salted',
        Variant__c = 'Standard Pack 120g',
        Package_Type__c = 'Packet',
        Unit_Conversion__c = 30,
        Batch_No__c = 'BATCH-2026-MN-02',
        Quantity__c = 1200,
        Available_Stock__c = 1200,
        MRP__c = 20.00,
        RBP__c = 17.20,
        GST_Percentage__c = 18.0,
        Manufacturing_Date__c = Date.today().addDays(-15),
        Expiry_Date__c = Date.today().addMonths(8),
        Product_Image__c = 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=300',
        Is_Active__c = true
    ),
    new Product__c(
        Name = 'Krackjack Sweet & Salty Biscuit',
        Product_Code__c = 'P-KRK-003',
        SKU__c = 'SKU-KRK-200G',
        Category__c = 'Biscuits',
        Brand__c = 'Parle',
        Sub_Brand__c = 'Krackjack',
        Brand_Alias__c = 'KJ Original',
        Flavour__c = 'Sweet & Salty',
        Variant__c = 'Family Pack 200g',
        Package_Type__c = 'Packet',
        Unit_Conversion__c = 24,
        Batch_No__c = 'BATCH-2026-KJ-03',
        Quantity__c = 900,
        Available_Stock__c = 900,
        MRP__c = 30.00,
        RBP__c = 25.80,
        GST_Percentage__c = 18.0,
        Manufacturing_Date__c = Date.today().addDays(-10),
        Expiry_Date__c = Date.today().addMonths(9),
        Product_Image__c = 'https://images.unsplash.com/photo-1583338917451-face2751d8d5?w=300',
        Is_Active__c = true
    ),
    new Product__c(
        Name = 'Hide & Seek Chocolate Chip Cookies',
        Product_Code__c = 'P-HNS-004',
        SKU__c = 'SKU-HNS-120G',
        Category__c = 'Cookies',
        Brand__c = 'Parle',
        Sub_Brand__c = 'Hide & Seek',
        Brand_Alias__c = 'H&S Choco',
        Flavour__c = 'Chocolate / Choco-Chip',
        Variant__c = 'Premium Pack 120g',
        Package_Type__c = 'Packet',
        Unit_Conversion__c = 24,
        Batch_No__c = 'BATCH-2026-HS-04',
        Quantity__c = 800,
        Available_Stock__c = 800,
        MRP__c = 40.00,
        RBP__c = 34.00,
        GST_Percentage__c = 18.0,
        Manufacturing_Date__c = Date.today().addDays(-8),
        Expiry_Date__c = Date.today().addMonths(6),
        Product_Image__c = 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=300',
        Is_Active__c = true
    ),
    new Product__c(
        Name = 'Parle 20-20 Cashew Butter Cookies',
        Product_Code__c = 'P-TTW-005',
        SKU__c = 'SKU-TTW-150G',
        Category__c = 'Cookies',
        Brand__c = 'Parle',
        Sub_Brand__c = '20-20',
        Brand_Alias__c = '20-20 Cashew',
        Flavour__c = 'Cashew & Butter',
        Variant__c = 'Standard Pack 150g',
        Package_Type__c = 'Packet',
        Unit_Conversion__c = 30,
        Batch_No__c = 'BATCH-2026-TT-05',
        Quantity__c = 1100,
        Available_Stock__c = 1100,
        MRP__c = 25.00,
        RBP__c = 21.25,
        GST_Percentage__c = 18.0,
        Manufacturing_Date__c = Date.today().addDays(-12),
        Expiry_Date__c = Date.today().addMonths(8),
        Product_Image__c = 'https://images.unsplash.com/photo-1548741487-18d16a145e80?w=300',
        Is_Active__c = true
    ),
    new Product__c(
        Name = 'Milano Choco Delight Cookies',
        Product_Code__c = 'P-MIL-006',
        SKU__c = 'SKU-MIL-75G',
        Category__c = 'Cookies',
        Brand__c = 'Parle',
        Sub_Brand__c = 'Milano',
        Brand_Alias__c = 'Milano Choco',
        Flavour__c = 'Rich Chocolate Hazelnut',
        Variant__c = 'Box Pack 75g',
        Package_Type__c = 'Box',
        Unit_Conversion__c = 20,
        Batch_No__c = 'BATCH-2026-ML-06',
        Quantity__c = 600,
        Available_Stock__c = 600,
        MRP__c = 50.00,
        RBP__c = 42.50,
        GST_Percentage__c = 18.0,
        Manufacturing_Date__c = Date.today().addDays(-5),
        Expiry_Date__c = Date.today().addMonths(6),
        Product_Image__c = 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=300',
        Is_Active__c = true
    ),
    new Product__c(
        Name = 'Parle Platina Top Crackers',
        Product_Code__c = 'P-TOP-007',
        SKU__c = 'SKU-TOP-100G',
        Category__c = 'Crackers',
        Brand__c = 'Parle',
        Sub_Brand__c = 'Top',
        Brand_Alias__c = 'Platina Top',
        Flavour__c = 'Butter Cracker',
        Variant__c = 'Standard Pack 100g',
        Package_Type__c = 'Packet',
        Unit_Conversion__c = 30,
        Batch_No__c = 'BATCH-2026-TP-07',
        Quantity__c = 750,
        Available_Stock__c = 750,
        MRP__c = 20.00,
        RBP__c = 17.00,
        GST_Percentage__c = 18.0,
        Manufacturing_Date__c = Date.today().addDays(-14),
        Expiry_Date__c = Date.today().addMonths(7),
        Product_Image__c = 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=300',
        Is_Active__c = true
    ),
    new Product__c(
        Name = 'Parle Bourbon Chocolate Cream',
        Product_Code__c = 'P-BRB-008',
        SKU__c = 'SKU-BRB-150G',
        Category__c = 'Cream Biscuits',
        Brand__c = 'Parle',
        Sub_Brand__c = 'Bourbon',
        Brand_Alias__c = 'Parle Bourbon',
        Flavour__c = 'Chocolate Cream',
        Variant__c = 'Standard Pack 150g',
        Package_Type__c = 'Packet',
        Unit_Conversion__c = 24,
        Batch_No__c = 'BATCH-2026-BB-08',
        Quantity__c = 850,
        Available_Stock__c = 850,
        MRP__c = 35.00,
        RBP__c = 29.75,
        GST_Percentage__c = 18.0,
        Manufacturing_Date__c = Date.today().addDays(-18),
        Expiry_Date__c = Date.today().addMonths(8),
        Product_Image__c = 'https://images.unsplash.com/photo-1548741487-18d16a145e80?w=300',
        Is_Active__c = true
    ),
    new Product__c(
        Name = 'Parle Gold Rich Glucose Biscuit',
        Product_Code__c = 'P-GLD-009',
        SKU__c = 'SKU-GLD-300G',
        Category__c = 'Biscuits',
        Brand__c = 'Parle',
        Sub_Brand__c = 'Parle Gold',
        Brand_Alias__c = 'Gold Glucose',
        Flavour__c = 'Rich Milk & Glucose',
        Variant__c = 'Family Pack 300g',
        Package_Type__c = 'Packet',
        Unit_Conversion__c = 20,
        Batch_No__c = 'BATCH-2026-PGD-09',
        Quantity__c = 1000,
        Available_Stock__c = 1000,
        MRP__c = 40.00,
        RBP__c = 34.00,
        GST_Percentage__c = 18.0,
        Manufacturing_Date__c = Date.today().addDays(-10),
        Expiry_Date__c = Date.today().addMonths(9),
        Product_Image__c = 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=300',
        Is_Active__c = true
    ),
    new Product__c(
        Name = 'Kopiko Coffee Candy Jar',
        Product_Code__c = 'P-KOP-010',
        SKU__c = 'SKU-KOP-150U',
        Category__c = 'Confectionery',
        Brand__c = 'Kopiko',
        Sub_Brand__c = 'Coffee Candy',
        Brand_Alias__c = 'Kopiko Jar',
        Flavour__c = 'Rich Coffee',
        Variant__c = 'Jar 150 Pieces',
        Package_Type__c = 'Box',
        Unit_Conversion__c = 12,
        Batch_No__c = 'BATCH-2026-KP-10',
        Quantity__c = 400,
        Available_Stock__c = 400,
        MRP__c = 150.00,
        RBP__c = 120.00,
        GST_Percentage__c = 18.0,
        Manufacturing_Date__c = Date.today().addDays(-30),
        Expiry_Date__c = Date.today().addMonths(12),
        Product_Image__c = 'https://images.unsplash.com/photo-1582058091505-f87a2e55a40f?w=300',
        Is_Active__c = true
    ),
    new Product__c(
        Name = 'Cello Gripper Ball Pen Box',
        Product_Code__c = 'P-PEN-011',
        SKU__c = 'SKU-PEN-20S',
        Category__c = 'Stationery',
        Brand__c = 'Cello',
        Sub_Brand__c = 'Gripper',
        Brand_Alias__c = 'Promo Pen',
        Flavour__c = 'Blue Ink',
        Variant__c = 'Box of 20 Pens',
        Package_Type__c = 'Box',
        Unit_Conversion__c = 50,
        Batch_No__c = 'BATCH-2026-CP-11',
        Quantity__c = 500,
        Available_Stock__c = 500,
        MRP__c = 100.00,
        RBP__c = 80.00,
        GST_Percentage__c = 18.0,
        Manufacturing_Date__c = Date.today().addDays(-40),
        Expiry_Date__c = Date.today().addYears(3),
        Product_Image__c = 'https://images.unsplash.com/photo-1585336261026-77cc7c469b61?w=300',
        Is_Active__c = true
    )
};

Map<String, Product__c> existingProdMap = new Map<String, Product__c>();
for (Product__c p : [SELECT Id, Product_Code__c FROM Product__c]) {
    existingProdMap.put(p.Product_Code__c, p);
}
List<Product__c> prodToInsert = new List<Product__c>();
List<Product__c> prodToUpdate = new List<Product__c>();
for (Product__c p : products) {
    if (existingProdMap.containsKey(p.Product_Code__c)) {
        p.Id = existingProdMap.get(p.Product_Code__c).Id;
        prodToUpdate.add(p);
    } else {
        prodToInsert.add(p);
    }
}
if (!prodToInsert.isEmpty()) insert prodToInsert;
if (!prodToUpdate.isEmpty()) update prodToUpdate;
System.debug('Products seeded successfully. Total: ' + products.size());

// Map products by code
Map<String, Id> prodMap = new Map<String, Id>();
for (Product__c p : [SELECT Id, Product_Code__c FROM Product__c WHERE Product_Code__c IN ('P-GLU-001', 'P-MON-002', 'P-KRK-003', 'P-HNS-004', 'P-BRB-008', 'P-KOP-010', 'P-PEN-011')]) {
    prodMap.put(p.Product_Code__c, p.Id);
}

// 3. Seed Schemes (Slide 11 Schemes)
List<Scheme__c> schemes = new List<Scheme__c>{
    new Scheme__c(
        Name = 'Parle-G 10+1 Mega Offer',
        Scheme_Code__c = 'SCH-BUY-SAME-01',
        Scheme_Type__c = 'Buy same free',
        Primary_Product__c = prodMap.get('P-GLU-001'),
        Free_Product_Custom__c = prodMap.get('P-GLU-001'),
        Buy_Quantity__c = 10,
        Get_Quantity__c = 1,
        Duration_Days__c = 30,
        Start_Date__c = Date.today().addDays(-5),
        End_Date__c = Date.today().addDays(25),
        Region__c = 'North',
        Outlet_Type__c = 'Kirana',
        Status__c = 'Active',
        Description__c = 'Buy 10 packets of Parle-G 250g and get 1 packet free of the same product.'
    ),
    new Scheme__c(
        Name = 'Bourbon Promo - Free Cello Pen Box',
        Scheme_Code__c = 'SCH-BUY-PEN-02',
        Scheme_Type__c = 'Buy product get pen free',
        Primary_Product__c = prodMap.get('P-BRB-008'),
        Free_Product_Custom__c = prodMap.get('P-PEN-011'),
        Buy_Quantity__c = 5,
        Get_Quantity__c = 1,
        Duration_Days__c = 45,
        Start_Date__c = Date.today().addDays(-10),
        End_Date__c = Date.today().addDays(35),
        Region__c = 'All India',
        Outlet_Type__c = 'Supermarket',
        Status__c = 'Active',
        Description__c = 'Order 5 cases of Parle Bourbon and get 1 box of Cello Gripper Pens free for retailer counter.'
    ),
    new Scheme__c(
        Name = 'Hide & Seek Choco Fest - Free Kopiko Jar',
        Scheme_Code__c = 'SCH-BUY-KOP-03',
        Scheme_Type__c = 'Buy product get Kopiko chocolate free',
        Primary_Product__c = prodMap.get('P-HNS-004'),
        Free_Product_Custom__c = prodMap.get('P-KOP-010'),
        Buy_Quantity__c = 8,
        Get_Quantity__c = 1,
        Duration_Days__c = 30,
        Start_Date__c = Date.today().addDays(-2),
        End_Date__c = Date.today().addDays(28),
        Region__c = 'West',
        Outlet_Type__c = 'Convenience Store',
        Status__c = 'Active',
        Description__c = 'Order 8 boxes of Hide & Seek Cookies and get 1 Kopiko Coffee Candy Jar free!'
    ),
    new Scheme__c(
        Name = 'Monaco Festive Volume Slab Scheme',
        Scheme_Code__c = 'SCH-SLAB-04',
        Scheme_Type__c = 'Slab scheme',
        Primary_Product__c = prodMap.get('P-MON-002'),
        Minimum_Order_Value__c = 1000.00,
        Discount_Percentage__c = 7.5,
        Duration_Days__c = 60,
        Start_Date__c = Date.today().addDays(-15),
        End_Date__c = Date.today().addDays(45),
        Region__c = 'North',
        Outlet_Type__c = 'Kirana',
        Status__c = 'Active',
        Description__c = 'Order above ₹1000 of Monaco Crackers and get instant 7.5% bill discount.'
    ),
    new Scheme__c(
        Name = 'Tea-Time Special Bundle Pack',
        Scheme_Code__c = 'SCH-BUNDLE-05',
        Scheme_Type__c = 'Bundle scheme with prices',
        Primary_Product__c = prodMap.get('P-GLU-001'),
        Bundle_Price__c = 99.00,
        Discount_Amount__c = 25.00,
        Duration_Days__c = 30,
        Start_Date__c = Date.today().addDays(-5),
        End_Date__c = Date.today().addDays(25),
        Region__c = 'All India',
        Outlet_Type__c = 'Kirana',
        Status__c = 'Active',
        Description__c = 'Parle-G + Krackjack + Monaco Trio Bundle for special combo price of ₹99 only.'
    )
};

Map<String, Scheme__c> existingSchemeMap = new Map<String, Scheme__c>();
for (Scheme__c s : [SELECT Id, Scheme_Code__c FROM Scheme__c]) {
    existingSchemeMap.put(s.Scheme_Code__c, s);
}
List<Scheme__c> sToInsert = new List<Scheme__c>();
List<Scheme__c> sToUpdate = new List<Scheme__c>();
for (Scheme__c s : schemes) {
    if (existingSchemeMap.containsKey(s.Scheme_Code__c)) {
        s.Id = existingSchemeMap.get(s.Scheme_Code__c).Id;
        sToUpdate.add(s);
    } else {
        sToInsert.add(s);
    }
}
if (!sToInsert.isEmpty()) insert sToInsert;
if (!sToUpdate.isEmpty()) update sToUpdate;
System.debug('Schemes seeded successfully. Total: ' + schemes.size());

// 4. Seed In-Visit Activities (Slide 8) for existing Outlets
Outlet__c sampleOutlet = [SELECT Id, Name, Beat__c FROM Outlet__c LIMIT 1];
System.debug('Found sample outlet: ' + sampleOutlet.Name);

// 4a. Asset Survey
Asset_Survey__c assetSurvey = new Asset_Survey__c(
    Outlet__c = sampleOutlet.Id,
    Asset_Name__c = 'Parle Visibility Floor Rack (4-Tier)',
    Asset_Code__c = 'AST-RCK-1092',
    Status__c = 'Good Condition',
    Given_Date__c = Date.today().addDays(-60),
    Picture__c = 'https://images.unsplash.com/photo-1534452203293-494d7ddbf7e0?w=300',
    Remarks__c = 'Rack is positioned in the prime billing counter zone with 100% brand visibility.'
);
insert assetSurvey;
System.debug('Created Asset Survey: ' + assetSurvey.Id);

// 4b. Competitors Activity
Competitor_Activity__c compAct = new Competitor_Activity__c(
    Outlet__c = sampleOutlet.Id,
    Competitor_Name__c = 'Britannia Good Day Butter',
    Company__c = 'Britannia Industries Ltd',
    Category__c = 'Biscuits',
    MRP__c = 30.00,
    RBP__c = 25.50,
    Schemes__c = 'Buy 10 Packets Get 1 Free Promo with counter hanging dispenser',
    Image__c = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300',
    Remarks__c = 'Competitor is offering higher retailer margin on Good Day 100g packs.'
);
insert compAct;
System.debug('Created Competitor Activity: ' + compAct.Id);

// 4c. Stock Check
Stock_Check__c stockCheck = new Stock_Check__c(
    Outlet__c = sampleOutlet.Id,
    Product__c = prodMap.get('P-GLU-001'),
    Quantity__c = 48,
    Manufacturing_Date__c = Date.today().addDays(-20),
    Batch_No__c = 'BATCH-2026-PG-01',
    Stock_Condition__c = 'Good',
    Remarks__c = 'Shelf has 24 units, backroom storage has 24 units in undamaged condition.'
);
insert stockCheck;
System.debug('Created Stock Check: ' + stockCheck.Id);

// 4d. Tickets / Issue
Ticket__c ticket = new Ticket__c(
    Outlet__c = sampleOutlet.Id,
    Subject__c = 'Damaged Outer Packaging on Monaco Delivery',
    Category__c = 'Damaged Product',
    Priority__c = 'Medium',
    Status__c = 'In Progress',
    Description__c = 'Two master cartons had crushed corner corners resulting in 8 bruised inner packs.',
    Image__c = 'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=300',
    Resolution_Notes__c = 'Distributor delivery agent informed; replacement voucher initiated.'
);
insert ticket;
System.debug('Created Ticket: ' + ticket.Id);

// 4e. Product Return
Product_Return__c prodReturn = new Product_Return__c(
    Outlet__c = sampleOutlet.Id,
    Product__c = prodMap.get('P-MON-002'),
    Quantity__c = 8,
    Manufacturing_Date__c = Date.today().addDays(-45),
    Batch_No__c = 'BATCH-2026-MN-02',
    Return_Reason__c = 'Damaged in Transit',
    Status__c = 'Approved',
    Remarks__c = 'Outer sealed carton was punctured during monsoon delivery.'
);
insert prodReturn;
System.debug('Created Product Return: ' + prodReturn.Id);

// 4f. Attendance
Id currentUserId = UserInfo.getUserId();
List<Employee__c> emps = [SELECT Id FROM Employee__c WHERE User__c = :currentUserId LIMIT 1];

Attendance__c att = new Attendance__c(
    Employee__c = !emps.isEmpty() ? emps[0].Id : null,
    User__c = currentUserId,
    Attendance_Date__c = Date.today(),
    Start_Time__c = DateTime.now().addHours(-4),
    End_Time__c = DateTime.now(),
    Geo_Location__c = '19.0760° N, 72.8777° E (Mumbai Hub)',
    Total_Working_Hours__c = 4.0,
    Attendance_Status__c = 'Present',
    Is_Leave__c = false
);
insert att;
System.debug('Created Attendance: ' + att.Id);

System.debug('SFA data seeding successfully completed!');

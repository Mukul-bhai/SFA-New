// Full End-to-End Test Data Flow Script for Salesforce Core Cloud
System.debug('=== Starting SFA & DMS Full Flow Seed Insertion ===');

// 0. Current User
Id currentUserId = UserInfo.getUserId();

// 1. Master Data: Territory
List<Territory__c> existingTerr = [SELECT Id FROM Territory__c WHERE Territory_Code__c = 'TERR-MUM-01'];
delete existingTerr;

Territory__c terr = new Territory__c(
    Name = 'Mumbai Central Territory',
    Territory_Code__c = 'TERR-MUM-01',
    Region__c = 'West',
    State__c = 'Maharashtra',
    Area__c = 'Mumbai Urban'
);
insert terr;
System.debug('1. Created Territory: ' + terr.Name);

// 2. Master Data: Beat (Route)
Beat__c beat = new Beat__c(
    Name = 'Dadar West Route - Monday',
    Beat_Code__c = 'BEAT-DAD-MON',
    Territory__c = terr.Id,
    Day_Of_Week__c = 'Monday',
    Assigned_Executive__c = currentUserId
);
insert beat;
System.debug('2. Created Beat: ' + beat.Name);

// 3. Master Data: Distributors & Warehouses
List<Distributor__c> existingDist = [SELECT Id FROM Distributor__c WHERE Distributor_Code__c IN ('DIST-PRI-001', 'DIST-BAK-002')];
delete existingDist;

Distributor__c distPri = new Distributor__c(
    Name = 'Apex Traders Primary',
    Distributor_Code__c = 'DIST-PRI-001',
    Status__c = 'Active',
    Credit_Limit__c = 500000,
    Current_Outstanding__c = 85000,
    GSTIN__c = '27AABCT1332L1Z5'
);
Distributor__c distBak = new Distributor__c(
    Name = 'Zenith Logistics Backup',
    Distributor_Code__c = 'DIST-BAK-002',
    Status__c = 'Active',
    Credit_Limit__c = 300000,
    Current_Outstanding__c = 25000,
    GSTIN__c = '27BBBPZ8821M2Z3'
);
insert new List<Distributor__c>{ distPri, distBak };

Warehouse__c whPri = new Warehouse__c(
    Name = 'Primary Central Depot A',
    Warehouse_Code__c = 'WH-PRI-A',
    Distributor__c = distPri.Id,
    Address__c = 'Plot 42, Industrial Area Phase 1, Dadar, Mumbai',
    Is_Active__c = true
);
Warehouse__c whBak = new Warehouse__c(
    Name = 'Backup Regional Depot B',
    Warehouse_Code__c = 'WH-BAK-B',
    Distributor__c = distBak.Id,
    Address__c = 'Warehouse Hub 9, Ring Road, Bhiwandi, Mumbai',
    Is_Active__c = true
);
insert new List<Warehouse__c>{ whPri, whBak };

// Update default warehouses on distributors
distPri.Default_Warehouse__c = whPri.Id;
distBak.Default_Warehouse__c = whBak.Id;
update new List<Distributor__c>{ distPri, distBak };
System.debug('3. Created Distributors & Warehouses');

// 4. Master Data: FMCG Product Catalog
List<Product2> existingProds = [SELECT Id FROM Product2 WHERE ProductCode IN ('SHMP-200', 'SOAP-125', 'TEA-100')];
delete existingProds;

Product2 prodShmp = new Product2(
    Name = 'Herbal Shampoo 200ml',
    ProductCode = 'SHMP-200',
    IsActive = true,
    Brand__c = 'NatureCare',
    Category__c = 'Personal_Care',
    Sub_Category__c = 'Hair Care',
    Pack_Size__c = '200ml Bottle',
    UOM__c = 'Piece',
    MRP__c = 180.00,
    Base_Price__c = 135.00,
    HSN_Code__c = '330510',
    GST_Rate__c = 18.00,
    EAN_Barcode__c = '8901030752109'
);
Product2 prodSoap = new Product2(
    Name = 'Neem Glow Soap 125g',
    ProductCode = 'SOAP-125',
    IsActive = true,
    Brand__c = 'NatureCare',
    Category__c = 'Personal_Care',
    Sub_Category__c = 'Skin Cleansing',
    Pack_Size__c = '125g Bar',
    UOM__c = 'Piece',
    MRP__c = 45.00,
    Base_Price__c = 32.00,
    HSN_Code__c = '340111',
    GST_Rate__c = 18.00,
    EAN_Barcode__c = '8901030821003'
);
Product2 prodTea = new Product2(
    Name = 'Organic Green Tea 100g',
    ProductCode = 'TEA-100',
    IsActive = true,
    Brand__c = 'PureLeaf',
    Category__c = 'Beverages',
    Sub_Category__c = 'Healthy Tea',
    Pack_Size__c = '100g Tin',
    UOM__c = 'Box',
    MRP__c = 220.00,
    Base_Price__c = 160.00,
    HSN_Code__c = '090210',
    GST_Rate__c = 12.00,
    EAN_Barcode__c = '8901030998821'
);
insert new List<Product2>{ prodShmp, prodSoap, prodTea };
System.debug('4. Created Products with FMCG fields');

// 5. Commercial Rules: Trade Schemes & Slabs
List<Scheme__c> existingSchemes = [SELECT Id FROM Scheme__c WHERE Scheme_Code__c = 'SCH-DIWALI-2026'];
delete existingSchemes;

Scheme__c sch = new Scheme__c(
    Name = 'Diwali Festival Trade Bonanza',
    Scheme_Code__c = 'SCH-DIWALI-2026',
    Scheme_Type__c = 'Buy_X_Get_Y',
    Status__c = 'Active',
    Start_Date__c = Date.today().addDays(-15),
    End_Date__c = Date.today().addDays(45),
    Applicable_Product__c = prodShmp.Id,
    Free_Product__c = prodSoap.Id,
    Buy_Quantity__c = 10,
    Get_Quantity__c = 1,
    Discount_Percentage__c = 5.00,
    Minimum_Order_Value__c = 5000.00,
    Description__c = 'Buy 10 Herbal Shampoo, get 1 Neem Soap Free + 5% slab discount on 50+ units'
);
insert sch;

Scheme_Slab__c slab = new Scheme_Slab__c(
    Scheme__c = sch.Id,
    Min_Quantity__c = 50,
    Max_Quantity__c = 500,
    Discount_Percentage__c = 5.00,
    Free_Quantity__c = 5
);
insert slab;
System.debug('5. Created Trade Scheme & Slabs');

// 6. Master Data: Retailer & Beat Mapping
List<Retailer__c> existingRets = [SELECT Id FROM Retailer__c WHERE Retailer_Code__c = 'RET-1001'];
delete existingRets;

Retailer__c ret = new Retailer__c(
    Name = 'Gupta Supermarket',
    Retailer_Code__c = 'RET-1001',
    Shop_Name__c = 'Gupta Kirana & General Store',
    Owner_Phone__c = '+91 98765 43210',
    Territory__c = terr.Id,
    Primary_Distributor__c = distPri.Id,
    Backup_Distributor__c = distBak.Id,
    Allow_Backup_Fulfillment__c = true,
    Credit_Limit__c = 50000.00,
    Outstanding_Balance__c = 8348.50,
    Credit_Hold__c = false,
    Verification_Status__c = 'Verified',
    Geolocation__Latitude__s = 19.0178,
    Geolocation__Longitude__s = 72.8478,
    Geofence_Radius_Meters__c = 100
);
insert ret;

Retailer_Beat_Mapping__c rbm = new Retailer_Beat_Mapping__c(
    Retailer__c = ret.Id,
    Beat__c = beat.Id,
    Sequence_Order__c = 1
);
insert rbm;
System.debug('6. Created Retailer & Beat Mapping');

// 7. Warehouse Stock & Batches
Inventory__c invShmp = new Inventory__c(
    Name = 'INV-Dadar-Shampoo-200',
    Warehouse__c = whPri.Id,
    Product__c = prodShmp.Id,
    Warehouse_Product_Key__c = whPri.Id + '_' + prodShmp.Id,
    Physical_Stock__c = 150,
    Reserved_Stock__c = 50,
    Blocked_Stock__c = 0,
    Damaged_Stock__c = 2,
    Expired_Stock__c = 0
);
Inventory__c invTea = new Inventory__c(
    Name = 'INV-Dadar-Tea-100',
    Warehouse__c = whPri.Id,
    Product__c = prodTea.Id,
    Warehouse_Product_Key__c = whPri.Id + '_' + prodTea.Id,
    Physical_Stock__c = 100,
    Reserved_Stock__c = 10,
    Blocked_Stock__c = 0,
    Damaged_Stock__c = 0,
    Expired_Stock__c = 0
);
insert new List<Inventory__c>{ invShmp, invTea };

Inventory_Batch__c batch1 = new Inventory_Batch__c(
    Inventory__c = invShmp.Id,
    Batch_Number__c = 'BATCH-2026-NC01',
    Manufacturing_Date__c = Date.today().addMonths(-2),
    Expiry_Date__c = Date.today().addMonths(22),
    Quantity__c = 150,
    MRP__c = 180.00
);
insert batch1;

Inventory_Ledger__c ledg1 = new Inventory_Ledger__c(
    Inventory__c = invShmp.Id,
    Type__c = 'Order_Reservation',
    Quantity_Delta__c = -50,
    Reference_Record_Id__c = 'ORD-20261005-001',
    Notes__c = 'Stock reserved for Order ORD-20261005-001 (Gupta Supermarket)',
    Timestamp__c = System.now()
);
insert ledg1;
System.debug('7. Created Inventory, Batch, and Ledger');

// 8. 3-Tier Sales Targets
Target__c tgtMonthly = new Target__c(
    Name = 'Oct 2026 - Monthly Target - Vikram',
    Sales_Executive__c = currentUserId,
    Territory__c = terr.Id,
    Target_Type__c = 'Monthly',
    Month__c = 'October',
    Year__c = '2026',
    Target_Revenue__c = 500000.00,
    Achieved_Revenue__c = 125000.00,
    Target_Volume_Units__c = 3500,
    Achieved_Volume_Units__c = 920,
    Target_Visits_Count__c = 120,
    Achieved_Visits_Count__c = 38
);
Target__c tgtDaily = new Target__c(
    Name = '05 Oct 2026 - Daily Target - Vikram',
    Sales_Executive__c = currentUserId,
    Target_Type__c = 'Day_Wise',
    Target_Date__c = Date.today(),
    Target_Revenue__c = 25000.00,
    Achieved_Revenue__c = 8348.50,
    Target_Volume_Units__c = 180,
    Achieved_Volume_Units__c = 60,
    Target_Visits_Count__c = 15,
    Achieved_Visits_Count__c = 6
);
Target__c tgtOutlet = new Target__c(
    Name = 'Oct 2026 - Supermarket Channel Target',
    Sales_Executive__c = currentUserId,
    Target_Type__c = 'Outlet_Type',
    Outlet_Category__c = 'Supermarket',
    Target_Revenue__c = 150000.00,
    Achieved_Revenue__c = 42000.00,
    Target_Volume_Units__c = 1000,
    Achieved_Volume_Units__c = 310
);
insert new List<Target__c>{ tgtMonthly, tgtDaily, tgtOutlet };
System.debug('8. Created 3-Tier Targets');

// 9. Morning Attendance & TA/DA Claim
Attendance__c att = new Attendance__c(
    Sales_Executive__c = currentUserId,
    Day_Type__c = 'Full_Day',
    Punch_In_Time__c = System.now().addHours(-5),
    Punch_In_Location__Latitude__s = 19.0180,
    Punch_In_Location__Longitude__s = 72.8475,
    Punch_In_Battery_Level__c = 94,
    Status__c = 'Punched_In',
    Daily_Allowance_Eligible__c = true,
    Total_Distance_KM__c = 38.50,
    Selfie_Image_URL__c = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb'
);
insert att;

Expense_Claim__c exp = new Expense_Claim__c(
    Name = 'EXP-20261005-01',
    Sales_Executive__c = currentUserId,
    Attendance__c = att.Id,
    Claim_Date__c = Date.today(),
    Day_Type__c = 'Full_Day',
    Daily_Allowance_Amount__c = 250.00,
    Travel_Mode__c = 'Two_Wheeler',
    Distance_Traveled_KM__c = 38.50,
    Rate_Per_KM__c = 3.50,
    Travel_Allowance_Amount__c = 134.75,
    Food_Amount__c = 120.00,
    Status__c = 'Submitted',
    Approval_Comments__c = 'Standard field beat travel for Dadar West'
);
insert exp;
System.debug('9. Created Attendance & TA/DA Expense Claim');

// 10. Store Visit
Visit__c vis = new Visit__c(
    Retailer__c = ret.Id,
    Sales_Executive__c = currentUserId,
    Beat__c = beat.Id,
    Check_In_Time__c = System.now().addHours(-3),
    Check_Out_Time__c = System.now().addHours(-2),
    Check_In_Location__Latitude__s = 19.0179,
    Check_In_Location__Longitude__s = 72.8479,
    Is_Within_Geofence__c = true,
    Geofence_Deviation_Distance_Meters__c = 14.50,
    Visit_Status__c = 'Completed',
    Order_Placed__c = true
);
insert vis;

// 11. In-Store Field Activities: Surveys, Planograms, Competition & Shelf Audit
Survey_Response__c srv = new Survey_Response__c(
    Name = 'Dadar Supermarket Service Survey',
    Visit__c = vis.Id,
    Retailer__c = ret.Id,
    Sales_Executive__c = currentUserId,
    Survey_Date__c = Date.today(),
    Survey_Type__c = 'General_Feedback',
    Rating__c = '5',
    Feedback_Notes__c = 'Store owner very satisfied with 24-hr delivery turnaround. Requested higher credit limit for upcoming festival week.'
);
Merchandising_Audit__c merch = new Merchandising_Audit__c(
    Name = 'Dadar Shelf Planogram Compliance',
    Visit__c = vis.Id,
    Retailer__c = ret.Id,
    Planogram_Compliant__c = true,
    Brand_Shelf_Share_Percent__c = 45.00,
    Display_Location__c = 'Eye_Level_Shelf',
    Shelf_Photo_URL__c = 'https://images.unsplash.com/photo-1578916171728-46686eac8d58',
    Remarks__c = 'Shampoo and Soaps placed prominently at entrance eye-level shelf.'
);
Competition_Capture__c comp = new Competition_Capture__c(
    Name = 'Dabur Vatika Competitor Audit',
    Visit__c = vis.Id,
    Retailer__c = ret.Id,
    Competitor_Brand__c = 'Dabur',
    Competitor_Product__c = 'Vatika Enriched Olive Shampoo 200ml',
    Competitor_Price__c = 175.00,
    Competitor_Scheme_Offer__c = 'Consumer Promo: Extra 20ml Free + Scratch Card',
    Stock_Visibility__c = 'High'
);
Shop_Stock_Check__c ssc = new Shop_Stock_Check__c(
    Name = 'Gupta Supermarket Shampoo Shelf Audit',
    Visit__c = vis.Id,
    Retailer__c = ret.Id,
    Product__c = prodShmp.Id,
    Shelf_Stock_Quantity__c = 8,
    Suggested_Order_Quantity__c = 50
);
insert new List<SObject>{ srv, merch, comp, ssc };
System.debug('11. Created In-Store Field Audits & Surveys');

// 12. Order Booking
Order__c ord = new Order__c(
    Name = 'ORD-20261005-001',
    Retailer__c = ret.Id,
    Primary_Distributor__c = distPri.Id,
    Sales_Executive__c = currentUserId,
    Visit__c = vis.Id,
    Order_Date__c = System.now().addHours(-2),
    Status__c = 'Approved',
    Applied_Scheme__c = sch.Id,
    Total_Amount__c = 8012.50,
    Discount_Amount__c = 337.50
);
insert ord;

Order_Line__c ol1 = new Order_Line__c(
    Order__c = ord.Id,
    Product__c = prodShmp.Id,
    Quantity__c = 50,
    Unit_Price__c = 135.00,
    Applied_Scheme__c = sch.Id,
    Free_Goods_Quantity__c = 5,
    Fulfillment_Status__c = 'Allocated_Primary',
    Fulfilling_Distributor__c = distPri.Id
);
Order_Line__c ol2 = new Order_Line__c(
    Order__c = ord.Id,
    Product__c = prodTea.Id,
    Quantity__c = 10,
    Unit_Price__c = 160.00,
    Fulfillment_Status__c = 'Allocated_Primary',
    Fulfilling_Distributor__c = distPri.Id
);
insert new List<Order_Line__c>{ ol1, ol2 };
System.debug('12. Created Order and Order Lines with Scheme Applied');

// 13. Billing & Invoicing
Invoice__c inv = new Invoice__c(
    Name = 'INV-2026-0098',
    Order__c = ord.Id,
    Invoice_Number__c = 'INV-2026-0098',
    Invoice_Date__c = Date.today(),
    Invoice_Amount__c = 8348.50,
    Status__c = 'Issued'
);
insert inv;

// 14. Payment Collection
Payment__c pay = new Payment__c(
    Name = 'PAY-20261005-01',
    Retailer__c = ret.Id,
    Order__c = ord.Id,
    Payment_Mode__c = 'UPI',
    Amount__c = 8348.50,
    Transaction_Reference__c = 'UPI/428491028491',
    Status__c = 'Confirmed'
);
insert pay;
System.debug('13-14. Created Invoice and Payment');

// 15. Damaged Stock Return & Credit Note
Return_Order__c retOrd = new Return_Order__c(
    Name = 'RET-2026-042',
    Return_Number__c = 'RET-2026-042',
    Retailer__c = ret.Id,
    Distributor__c = distPri.Id,
    Warehouse__c = whPri.Id,
    Return_Date__c = Date.today(),
    Status__c = 'Approved',
    Total_Return_Amount__c = 270.00,
    Remarks__c = 'Transit damage: 2 bottles with cracked flip-top caps during transport unloading.'
);
insert retOrd;

Return_Line__c retLine = new Return_Line__c(
    Return_Order__c = retOrd.Id,
    Product__c = prodShmp.Id,
    Quantity__c = 2,
    Unit_Price__c = 135.00,
    Batch_Number__c = 'BATCH-2026-NC01',
    Return_Reason__c = 'Damaged_In_Transit'
);
insert retLine;

Credit_Note__c cn = new Credit_Note__c(
    Name = 'CN-2026-015',
    Credit_Note_Number__c = 'CN-2026-015',
    Retailer__c = ret.Id,
    Distributor__c = distPri.Id,
    Return_Order__c = retOrd.Id,
    Credit_Amount__c = 270.00,
    Issue_Date__c = Date.today(),
    Reason__c = 'Goods_Return',
    Status__c = 'Issued'
);
insert cn;
System.debug('15. Created Return Order, Return Line, and Credit Note');

// 16. Touch all newly seeded records for RecentlyViewed
List<SObject> touchList = new List<SObject>();
touchList.addAll([SELECT Id FROM Territory__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Beat__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Distributor__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Warehouse__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Product2 FOR VIEW]);
touchList.addAll([SELECT Id FROM Scheme__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Target__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Retailer__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Attendance__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Expense_Claim__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Visit__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Survey_Response__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Merchandising_Audit__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Competition_Capture__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Order__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Invoice__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Payment__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Return_Order__c FOR VIEW]);
touchList.addAll([SELECT Id FROM Credit_Note__c FOR VIEW]);

System.debug('=== SUCCESS: Complete SFA & DMS Full Flow Test Data Seeded! ===');

// ==============================================================================
// SEED SFA DMS PROJECT DATA: EMPLOYEES, PJP, BEATS, AND OUTLETS
// Corresponds directly to Slide 5 & Slide 6 specs
// ==============================================================================

System.debug('--- STARTING SFA DMS DATA SEEDING ---');

// 1. Fetch Admin User (Mukul Yadav) and other users
User adminUser = [SELECT Id, Name, Email FROM User WHERE Name LIKE '%Mukul%' LIMIT 1];
List<User> standardUsers = [SELECT Id, Name, Email FROM User WHERE Profile.Name = 'Standard User' LIMIT 2];

Id vireshUserId = !standardUsers.isEmpty() ? standardUsers[0].Id : adminUser.Id;
Id dineshUserId = standardUsers.size() > 1 ? standardUsers[1].Id : adminUser.Id;
Id aishwaryaUserId = adminUser.Id;

// 2. Fetch or Create Territory for Bengaluru (for Beat__c MasterDetail)
Territory__c territory;
List<Territory__c> territories = [SELECT Id, Name FROM Territory__c WHERE Name LIKE '%Bengaluru%' OR Name LIKE '%Central%' LIMIT 1];
if (territories.isEmpty()) {
    territory = new Territory__c(
        Name = 'Bengaluru South Territory',
        Territory_Code__c = 'TER-BLR-01',
        Region__c = 'South',
        State__c = 'Karnataka',
        Area__c = 'Bengaluru Central & South'
    );
    insert territory;
} else {
    territory = territories[0];
}

// Fetch Distributor
Distributor__c dist = [SELECT Id, Name FROM Distributor__c LIMIT 1];

// 3. CREATE 3 EMPLOYEES (Hierarchical: Viresh L1 -> Dinesh L2 -> Aishwarya L3)
// Check if employees already exist
delete [SELECT Id FROM Employee__c WHERE Name IN ('Viresh', 'Dinesh', 'Aishwarya')];

Employee__c emp3 = new Employee__c(
    Name = 'Aishwarya',
    User__c = aishwaryaUserId,
    Reporting_Manager__c = adminUser.Id,
    Hierarchy_Level__c = 'L3 - Aishwarya',
    Aadhar_Number__c = '345678901234',
    Pan_Number__c = 'CDEFG3456H',
    Phone_Number__c = '9876543230',
    Emergency_Contact__c = '9876543231',
    Email__c = 'aishwarya.sfa@example.com',
    Country__c = 'India',
    State__c = 'Delhi',
    District__c = 'South Delhi',
    Town__c = 'Saket',
    Municipality__c = 'MCD - Delhi',
    Village__c = 'Empty',
    Pincode__c = '110017',
    Status__c = 'Active'
);
insert emp3;

Employee__c emp2 = new Employee__c(
    Name = 'Dinesh',
    User__c = dineshUserId,
    Reporting_Manager__c = aishwaryaUserId,
    Reporting_Manager_Employee__c = emp3.Id,
    Hierarchy_Level__c = 'L2 - Dinesh',
    Aadhar_Number__c = '234567890123',
    Pan_Number__c = 'BCDEF2345G',
    Phone_Number__c = '9876543220',
    Emergency_Contact__c = '9876543221',
    Email__c = 'dinesh.sfa@example.com',
    Country__c = 'India',
    State__c = 'Maharashtra',
    District__c = 'Mumbai',
    Town__c = 'Bandra',
    Municipality__c = 'BMC - Mumbai',
    Village__c = 'Empty',
    Pincode__c = '400050',
    Status__c = 'Active'
);
insert emp2;

Employee__c emp1 = new Employee__c(
    Name = 'Viresh',
    User__c = vireshUserId,
    Reporting_Manager__c = dineshUserId,
    Reporting_Manager_Employee__c = emp2.Id,
    Hierarchy_Level__c = 'L1 - Viresh',
    Aadhar_Number__c = '123456789012',
    Pan_Number__c = 'ABCDE1234F',
    Phone_Number__c = '9876543210',
    Emergency_Contact__c = '9876543211',
    Email__c = 'viresh.sfa@example.com',
    Country__c = 'India',
    State__c = 'Karnataka',
    District__c = 'Bengaluru',
    Town__c = 'MG road',
    Municipality__c = 'Empty',
    Village__c = 'Empty',
    Pincode__c = '560001',
    Status__c = 'Active'
);
insert emp1;

System.debug('Created 3 Employees: Viresh -> Dinesh -> Aishwarya');

// 4. CREATE PJP FOR VIRESH (October 2026, 1st Oct to 30th Oct)
delete [SELECT Id FROM PJP__c WHERE Name LIKE '%Viresh%October 2026%'];

PJP__c vireshPjp = new PJP__c(
    Name = 'PJP - Viresh - October 2026',
    Employee__c = emp1.Id,
    User__c = vireshUserId,
    Reporting_Manager__c = dineshUserId,
    Month__c = 'October',
    Year__c = '2026',
    Start_Date__c = Date.newInstance(2026, 10, 1),
    End_Date__c = Date.newInstance(2026, 10, 30),
    Status__c = 'Draft',
    Total_Beats__c = 10,
    Total_Outlets__c = 100,
    Remarks__c = 'Monthly journey plan for 10 route beats and 100 retail outlets in Bengaluru.'
);
insert vireshPjp;
System.debug('Created PJP for Viresh: ' + vireshPjp.Id);

// 5. CREATE 10 BEATS FOR VIRESH (Slide 6: "Create 10 beats, each beat should have 10 outlets")
List<Beat__c> beatsToInsert = new List<Beat__c>();

String[] beatNames = new String[]{
    'MG Road Route',
    'Indiranagar Route',
    'Koramangala Route',
    'Jayanagar Route',
    'Whitefield Route',
    'HSR Layout Route',
    'Malleshwaram Route',
    'Rajajinagar Route',
    'Hebbal Route',
    'Electronic City Route'
};

String[] dayNames = new String[]{
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
};

for (Integer i = 0; i < 10; i++) {
    Date routeDate = Date.newInstance(2026, 10, i + 1);
    Beat__c b = new Beat__c(
        Name = beatNames[i],
        Beat_Code__c = 'BEAT-BLR-0' + (i + 1),
        Territory__c = territory.Id,
        Distributor__c = dist.Id,
        PJP__c = vireshPjp.Id,
        Assigned_To__c = emp1.Id,
        Assigned_Executive__c = vireshUserId,
        Route_Date__c = routeDate,
        Day_Of_Week__c = dayNames[i],
        Total_Outlets__c = 10,
        Country__c = 'India',
        State__c = 'Karnataka',
        District__c = 'Bengaluru',
        Town__c = 'MG road',
        Municipality__c = 'Empty',
        Village__c = 'Empty'
    );
    beatsToInsert.add(b);
}
insert beatsToInsert;
System.debug('Created 10 Beats');

// 6. CREATE 10 OUTLETS FOR EACH BEAT (Total 100 Outlets)
// Slide 6 Example:
// Outlet: Balaji stores
// Outlet owner name: Mukul
// Contact no: 899899
// email: mukul@
// aadhar: 12 digit
// pan: 10 char
// Geo location: 12.9716, 77.5946
// beat: MG road

List<Outlet__c> outletsToInsert = new List<Outlet__c>();

String[] shopPrefixes = new String[]{
    'Balaji Stores',
    'Sri Krishna Provisions',
    'Ganesh Daily Needs',
    'Shiva Super Bazaar',
    'Lakshmi General Store',
    'Sai Ram Kirana',
    'Anand Retail Mart',
    'Ambika Provision Store',
    'Mahadev Daily Mart',
    'Jai Hind Super Market'
};

String[] owners = new String[]{
    'Mukul Yadav', 'Ramesh Kumar', 'Suresh Patel', 'Mahesh Gupta', 'Vikram Singh',
    'Anil Sharma', 'Praveen Reddy', 'Sunil Verma', 'Deepak Joshi', 'Santosh Nair'
};

for (Integer bIdx = 0; bIdx < beatsToInsert.size(); bIdx++) {
    Beat__c b = beatsToInsert[bIdx];
    for (Integer oIdx = 0; oIdx < 10; oIdx++) {
        String shopName = (bIdx == 0 && oIdx == 0) ? 'Balaji stores' : (shopPrefixes[oIdx] + ' - ' + (bIdx + 1));
        String ownerName = (bIdx == 0 && oIdx == 0) ? 'Mukul' : owners[oIdx];
        String contactNo = (bIdx == 0 && oIdx == 0) ? '8998990001' : ('987650' + String.valueOf(bIdx) + String.valueOf(oIdx) + '1');
        String email = (bIdx == 0 && oIdx == 0) ? 'mukul@balaji.com' : ('outlet' + bIdx + '_' + oIdx + '@gmail.com');
        
        Outlet__c out = new Outlet__c(
            Name = shopName,
            Beat__c = b.Id,
            Outlet_Owner_Name__c = ownerName,
            Contact_No__c = contactNo,
            Email__c = email,
            Aadhar_Number__c = '987654' + String.valueOf(100000 + bIdx * 10 + oIdx),
            Pan_Number__c = 'ABCDE' + String.valueOf(1000 + bIdx * 10 + oIdx) + 'Z',
            Outlet_Type__c = (Math.mod(oIdx, 3) == 0) ? 'Kirana' : (Math.mod(oIdx, 3) == 1 ? 'General Store' : 'Supermarket'),
            Sequence_Order__c = oIdx + 1,
            Country__c = 'India',
            State__c = 'Karnataka',
            District__c = 'Bengaluru',
            Town__c = 'MG road',
            Municipality__c = 'Empty',
            Village__c = 'Empty',
            Address__c = 'Shop No. ' + (oIdx + 1) + ', ' + b.Name + ', Bengaluru',
            Pincode__c = '560001',
            Status__c = 'Active',
            Geo_Location__Latitude__s = 12.9716 + (bIdx * 0.005) + (oIdx * 0.0008),
            Geo_Location__Longitude__s = 77.5946 + (bIdx * 0.005) + (oIdx * 0.0008)
        );
        outletsToInsert.add(out);
    }
}

insert outletsToInsert;
System.debug('Created ' + outletsToInsert.size() + ' Outlets (10 beats x 10 outlets each = 100 outlets!)');
System.debug('--- SFA DMS SEEDING COMPLETED SUCCESSFULLY ---');

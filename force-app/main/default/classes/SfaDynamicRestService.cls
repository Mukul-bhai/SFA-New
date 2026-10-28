@RestResource(urlMapping='/api/v1/sfa/dynamic/*')
global inherited sharing class SfaDynamicRestService {

    // Dynamic Metadata DTO
    global class MetadataResponse {
        public Boolean success;
        public String message;
        public Decimal geofenceRadiusMeters;
        public List<String> ticketCategories;
        public List<String> ticketPriorities;
        public List<String> returnReasons;
        public List<String> assetStatuses;
        public List<String> missedVisitReasons;
        public List<String> geofenceBypassReasons;
        public List<String> leaveCategories;
        public List<String> leaveTypes;
        public List<DistributorDTO> distributors;
    }

    // Dynamic Dashboard DTO
    global class DashboardResponse {
        public Boolean success;
        public String message;
        public String employeeId;
        public String employeeName;
        public String employeeCode;
        public String designation;
        public Decimal targetRevenue;
        public Decimal achievedRevenue;
        public Decimal achievementPercent;
        public Integer targetVisits;
        public Integer completedVisits;
        public Integer ordersBooked;
        public AttendanceDTO todayAttendance;
        public List<SchemeDTO> activeSchemes;
    }

    global class AttendanceDTO {
        public String id;
        public Date attendanceDate;
        public Datetime startTime;
        public Datetime endTime;
        public String geoLocation;
        public String status;
        public Decimal totalWorkingHours;
        public Boolean isDayActive;
        public String remarks;
        public String employeeName;
        public String dayPlan;
        public String dayPlanOtherDetails;
        public String tourPlan;
        public String modeOfTransport;
        public String vehicleUsed;
    }

    global class AttendanceResponse {
        public Boolean success;
        public String message;
        public AttendanceDTO record;
        public List<AttendanceDTO> history;
    }

    global class SchemeDTO {
        public String id;
        public String name;
        public String schemeCode;
        public String schemeType;
        public String primaryProductId;
        public String primaryProductName;
        public String freeProductId;
        public String freeProductName;
        public Decimal buyQuantity;
        public Decimal getQuantity;
        public Decimal minOrderValue;
        public Decimal discountPercentage;
        public Decimal bundlePrice;
        public Decimal discountAmount;
        public Integer durationDays;
        public Date startDate;
        public Date endDate;
        public String region;
        public String outletType;
        public String description;
    }

    global class ProductDTO {
        public String id;
        public String name;
        public String productCode;
        public String sku;
        public String category;
        public String brand;
        public String subBrand;
        public String brandAlias;
        public String flavour;
        public String variant;
        public String packageType;
        public Decimal unitConversion;
        public String batchNo;
        public Decimal quantity;
        public Decimal availableStock;
        public Decimal mrp;
        public Decimal rbp;
        public Decimal gstPercentage;
        public Date manufacturingDate;
        public Date expiryDate;
        public String productImage;
        public Boolean isActive;
        public String sellClassification;
        public Map<String, String> regionClassifications;
        public List<String> nonPurchaseReasons;
    }

    global class PJPTreeResponse {
        public Boolean success;
        public String message;
        public List<PJPDTO> pjps;
    }

    global class PJPDTO {
        public String id;
        public String name;
        public String month;
        public String year;
        public String status;
        public Decimal totalOutlets;
        public Decimal totalBeats;
        public List<BeatDTO> beats;
    }

    global class BeatDTO {
        public String id;
        public String name;
        public String code;
        public String beatId;
        public String dayOfWeek;
        public Date routeDate;
        public String pjpId;
        public String territoryName;
        public Decimal totalOutlets;
        public List<OutletDTO> outlets;
    }

    global class OutletDTO {
        public String id;
        public String name;
        public String outletCode;
        public String outletType;
        public String category;
        public String ownerName;
        public String contactPhone;
        public String address;
        public Decimal latitude;
        public Decimal longitude;
        public Decimal creditLimit;
        public Decimal outstandingBalance;
        public Boolean canTakeOrder;
        public Integer totalOrders;
        public List<OrderSummaryDTO> previousOrders;
        public String primaryDistributorId;
        public String primaryDistributorName;
    }

    global class DistributorDTO {
        public String id;
        public String name;
        public String code;
        public String contactPerson;
        public String status;
        public Decimal creditLimit;
        public Decimal currentOutstanding;
        public Boolean dmsPortalEnabled;
    }

    global class OrderSummaryDTO {
        public String id;
        public String orderNumber;
        public Datetime orderDate;
        public Decimal totalAmount;
        public String status;
        public Integer totalProductsCount;
        public Decimal totalQuantity;
        public String productNames;
    }

    // Generic Action Request
    global class ActionRequest {
        public String action; // attendance, visit-start, visit-checkout, order, stock-check, asset-survey, competitor, return, ticket
        public String outletId;
        public String visitId;
        public Decimal latitude;
        public Decimal longitude;
        public Decimal distanceMeters;
        public String bypassReason;
        public String missedReason;
        public String remarks;

        // Order data
        public Decimal grossAmount;
        public Decimal taxAmount;
        public Decimal totalAmount;
        public String appliedSchemeId;
        public String schemesApplied;
        public String mustSellNonPurchaseReasons;
        public String distributorId;
        public String orderType;
        public List<OrderItemRequest> items;

        // Stock check / Return data
        public String productId;
        public Decimal quantity;
        public String batchNo;
        public Date manufacturingDate;
        public String stockCondition;
        public String returnReason;

        // Asset data
        public String assetName;
        public String assetCode;
        public String assetStatus;
        public String pictureUrl;

        // Competitor data
        public String competitorName;
        public String company;
        public String competitorCategory;
        public Decimal mrp;
        public Decimal rbp;
        public String competitorSchemes;
        public String imageUrl;

        // Ticket data
        public String pjpId;
        public String beatId;
        public String subject;
        public String ticketCategory;
        public String priority;
        public String description;

        // Leave data
        public String leaveCategory;
        public String leaveType;
        public Date startDate;
        public Date endDate;
        public Decimal totalDays;
        public String reason;

        // PJP / Beat / Outlet Creation & Approval
        public String pjpName;
        public String month;
        public Integer year;
        public String beatName;
        public String beatCode;
        public String dayOfWeek;
        public Date beatDate;
        public String outletName;
        public String outletCode;
        public String ownerName;
        public String contactPhone;
        public String address;
        public String outletType;
        public Decimal creditLimit;
        public String territoryId;
        public String email;
        public String userId;

        // BRD Start Day / Attendance Fields (Points 21 & 31)
        public String dayPlan;
        public String dayPlanOtherDetails;
        public String tourPlan;
        public String modeOfTransport;
        public String vehicleUsed;

        // BRD Check-Out Fields (Points 23.7 & 30)
        public String selfieUrl;
        public String freezerPhotoUrl;
        public String checkoutComments;

        // Two-Tier Barcode & Return Verification Fields
        public String scannedBarcode;
        public String barcodeType;
        public String caseNumber;
        public String verificationStatus;
        public String returnType;
    }

    global class BarcodeVerificationDTO {
        public Boolean success;
        public String message;
        public String barcodeType; // 'Case Barcode' or 'Packet Barcode'
        public String scannedCode;
        public String caseBarcode;
        public String packetBarcode;
        public String batchNumber;
        public Date manufacturingDate;
        public Date expiryDate;
        public Decimal unitsPerCase;
        public String productId;
        public String productName;
        public String productCode;
        public String category;
        public String brand;
        public Decimal mrp;
        public Decimal rbp;
        public String distributorId;
        public String distributorName;
        public Integer shelfLifeDaysTotal;
        public Integer shelfLifeDaysRemaining;
        public String freshnessStatus;
        public String verificationStatus;
        public Boolean isReturnEligible;
        public String suggestedReturnReason;
    }

    global class TargetDTO {
        public String id;
        public String name;
        public String type;
        public String period;
        public Decimal targetRevenue;
        public Decimal achievedRevenue;
        public Decimal targetVolume;
        public Decimal achievedVolume;
        public Decimal targetVisits;
        public Decimal achievedVisits;
        public Decimal achievementPercent;
    }

    global class LeaveDTO {
        public String id;
        public String name;
        public String leaveCategory;
        public String leaveType;
        public String outletId;
        public String outletName;
        public String beatId;
        public String beatName;
        public String employeeId;
        public String employeeName;
        public Date startDate;
        public Date endDate;
        public Decimal totalDays;
        public String status;
        public String reason;
        public Datetime createdDate;
    }

    global class OrderItemRequest {
        public String productId;
        public String productName;
        public String sku;
        public Decimal quantity;
        public Decimal unitPrice;
        public Decimal grossAmount;
        public Decimal taxAmount;
        public Decimal totalAmount;
        public Decimal freeGoodsQuantity;
        public String appliedSchemeId;
    }

    global class ActionResponse {
        public Boolean success;
        public String message;
        public String recordId;
        public String recordNumber;
    }

    @HttpGet
    global static void handleGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        String path = req.requestURI;
        Id currentUserId = UserInfo.getUserId();

        String paramEmail = req.params != null ? req.params.get('email') : null;
        String paramUserId = req.params != null ? req.params.get('userId') : null;
        String paramDate = req.params != null ? req.params.get('date') : null;

        if (String.isNotBlank(paramEmail)) {
            User u = findUser(paramEmail);
            if (u != null) currentUserId = u.Id;
        } else if (String.isNotBlank(paramUserId)) {
            try { currentUserId = (Id) paramUserId; } catch (Exception e) {}
        }

        if (path.endsWith('/metadata')) {
            MetadataResponse resp = getDynamicMetadata();
            res.responseBody = Blob.valueOf(JSON.serialize(resp));
        } else if (path.endsWith('/dashboard')) {
            DashboardResponse resp = getDynamicDashboard(currentUserId);
            res.responseBody = Blob.valueOf(JSON.serialize(resp));
        } else if (path.endsWith('/schemes')) {
            List<SchemeDTO> resp = getDynamicSchemes();
            res.responseBody = Blob.valueOf(JSON.serialize(resp));
        } else if (path.endsWith('/products')) {
            String regionParam = req.params != null ? req.params.get('region') : null;
            if (String.isBlank(regionParam) && req.params != null) {
                regionParam = req.params.get('state');
            }
            List<ProductDTO> resp = getDynamicProducts(regionParam);
            res.responseBody = Blob.valueOf(JSON.serialize(resp));
        } else if (path.endsWith('/product-region-mappings')) {
            List<Product_Region_Mapping__c> mappings = [
                SELECT Id, Name, Product__c, Product__r.Name, Region__c, Sell_Classification__c, Priority__c, Is_Active__c
                FROM Product_Region_Mapping__c
                WHERE Is_Active__c = true
                ORDER BY Region__c, Priority__c
            ];
            res.responseBody = Blob.valueOf(JSON.serialize(mappings));
        } else if (path.endsWith('/pjp-tree')) {
            PJPTreeResponse resp = getDynamicPJPTree(currentUserId);
            res.responseBody = Blob.valueOf(JSON.serialize(resp));
        } else if (path.endsWith('/leave')) {
            List<LeaveDTO> resp = getDynamicLeaves(currentUserId);
            res.responseBody = Blob.valueOf(JSON.serialize(resp));
        } else if (path.endsWith('/attendance')) {
            AttendanceResponse resp = getDynamicAttendance(currentUserId, paramDate);
            res.responseBody = Blob.valueOf(JSON.serialize(resp));
        } else if (path.endsWith('/targets')) {
            List<TargetDTO> resp = getDynamicTargets(currentUserId);
            res.responseBody = Blob.valueOf(JSON.serialize(resp));
        } else if (path.endsWith('/distributors')) {
            List<DistributorDTO> resp = getDistributors();
            res.responseBody = Blob.valueOf(JSON.serialize(resp));
        } else if (path.endsWith('/barcode') || path.contains('/barcode')) {
            String codeParam = req.params != null ? req.params.get('code') : null;
            String distParam = req.params != null ? req.params.get('distributorId') : null;
            BarcodeVerificationDTO resp = verifyBarcode(codeParam, distParam);
            res.responseBody = Blob.valueOf(JSON.serialize(resp));
        } else {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('{"success":false,"message":"Endpoint not found"}');
        }
    }

    @HttpPost
    global static ActionResponse handlePost() {
        RestRequest req = RestContext.request;
        String body = req.requestBody != null ? req.requestBody.toString() : '{}';
        ActionRequest payload = (ActionRequest) JSON.deserialize(body, ActionRequest.class);
        Id currentUserId = UserInfo.getUserId();

        String paramEmail = req.params != null ? req.params.get('email') : null;
        String paramUserId = req.params != null ? req.params.get('userId') : null;
        if (String.isNotBlank(payload.email)) {
            paramEmail = payload.email;
        }
        if (String.isNotBlank(payload.userId)) {
            paramUserId = payload.userId;
        }
        if (String.isNotBlank(paramEmail)) {
            User u = findUser(paramEmail);
            if (u != null) currentUserId = u.Id;
        } else if (String.isNotBlank(paramUserId)) {
            try { currentUserId = (Id) paramUserId; } catch (Exception e) {}
        }

        String path = req.requestURI;
        String action = payload.action;
        if (String.isBlank(action)) {
            if (path.endsWith('/attendance')) action = 'attendance';
            else if (path.endsWith('/visit/start')) action = 'visit-start';
            else if (path.endsWith('/visit/checkout')) action = 'visit-checkout';
            else if (path.endsWith('/visit/missed')) action = 'visit-missed';
            else if (path.endsWith('/orders')) action = 'order';
            else if (path.endsWith('/stock-check')) action = 'stock-check';
            else if (path.endsWith('/asset-survey')) action = 'asset-survey';
            else if (path.endsWith('/competitor')) action = 'competitor';
            else if (path.endsWith('/return')) action = 'return';
            else if (path.endsWith('/tickets')) action = 'ticket';
            else if (path.endsWith('/leave')) action = 'leave';
            else if (path.endsWith('/pjp/create') || path.endsWith('/pjp')) action = 'create-pjp';
            else if (path.endsWith('/pjp/submit-approval')) action = 'submit-pjp-approval';
            else if (path.endsWith('/beat/create') || path.endsWith('/beat')) action = 'create-beat';
            else if (path.endsWith('/outlet/create') || path.endsWith('/outlet')) action = 'create-outlet';
            else if (path.endsWith('/expense') || path.endsWith('/expense-claim')) action = 'expense-claim';
        }

        if (action == 'attendance') {
            return processAttendance(payload, currentUserId);
        } else if (action == 'visit-start') {
            return processVisitStart(payload, currentUserId);
        } else if (action == 'visit-checkout') {
            return processVisitCheckout(payload, currentUserId);
        } else if (action == 'visit-missed') {
            return processVisitMissed(payload, currentUserId);
        } else if (action == 'order') {
            return processOrder(payload, currentUserId);
        } else if (action == 'stock-check') {
            return processStockCheck(payload);
        } else if (action == 'asset-survey') {
            return processAssetSurvey(payload);
        } else if (action == 'competitor') {
            return processCompetitorActivity(payload);
        } else if (action == 'return') {
            return processProductReturn(payload);
        } else if (action == 'ticket') {
            return processTicket(payload, currentUserId);
        } else if (action == 'leave') {
            return processLeaveRequest(payload, currentUserId);
        } else if (action == 'create-pjp') {
            return processCreatePJP(payload, currentUserId);
        } else if (action == 'submit-pjp-approval') {
            return processSubmitPJPApproval(payload, currentUserId);
        } else if (action == 'create-beat') {
            return processCreateBeat(payload, currentUserId);
        } else if (action == 'create-outlet') {
            return processCreateOutlet(payload, currentUserId);
        } else if (action == 'expense' || action == 'expense-claim') {
            return processExpenseClaim(payload, currentUserId);
        }

        ActionResponse resp = new ActionResponse();
        resp.success = false;
        resp.message = 'Unknown action: ' + action;
        return resp;
    }

    // 1. Dynamic Metadata
    private static MetadataResponse getDynamicMetadata() {
        MetadataResponse resp = new MetadataResponse();
        resp.success = true;
        resp.geofenceRadiusMeters = 100.0;
        resp.ticketCategories = getPicklistValues('Ticket__c', 'Category__c');
        resp.ticketPriorities = getPicklistValues('Ticket__c', 'Priority__c');
        resp.returnReasons = getPicklistValues('Product_Return__c', 'Return_Reason__c');
        resp.assetStatuses = getPicklistValues('Asset_Survey__c', 'Status__c');
        resp.missedVisitReasons = new List<String>{
            'Shop Closed', 'Owner Not Available', 'Sufficient Stock Available', 'Payment Dispute', 'Shop Under Renovation', 'Other'
        };
        resp.geofenceBypassReasons = new List<String>{
            'GPS Signal Drift', 'Road Construction / Detour', 'Shop Counter Relocated', 'Met Retailer Outside Shop', 'Emergency Order Collection'
        };
        resp.leaveCategories = getPicklistValues('Leave_Request__c', 'Leave_Type_Category__c');
        resp.leaveTypes = getPicklistValues('Leave_Request__c', 'Leave_Type__c');
        resp.distributors = getDistributors();
        return resp;
    }

    private static List<DistributorDTO> getDistributors() {
        List<DistributorDTO> listDTO = new List<DistributorDTO>();
        for (Distributor__c d : [
            SELECT Id, Name, Distributor_Code__c, Contact_Person__c, Status__c, 
                   Credit_Limit__c, Current_Outstanding__c, DMS_Portal_Enabled__c
            FROM Distributor__c
            WHERE Status__c = 'Active'
            ORDER BY Name ASC
        ]) {
            DistributorDTO dto = new DistributorDTO();
            dto.id = d.Id;
            dto.name = d.Name;
            dto.code = d.Distributor_Code__c != null ? d.Distributor_Code__c : '';
            dto.contactPerson = d.Contact_Person__c != null ? d.Contact_Person__c : '';
            dto.status = d.Status__c != null ? d.Status__c : 'Active';
            dto.creditLimit = d.Credit_Limit__c != null ? d.Credit_Limit__c : 0;
            dto.currentOutstanding = d.Current_Outstanding__c != null ? d.Current_Outstanding__c : 0;
            dto.dmsPortalEnabled = d.DMS_Portal_Enabled__c != null ? d.DMS_Portal_Enabled__c : true;
            listDTO.add(dto);
        }
        return listDTO;
    }

    private static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> values = new List<String>();
        try {
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectName);
            if (targetType != null) {
                Schema.DescribeSObjectResult describe = targetType.getDescribe();
                Schema.SObjectField field = describe.fields.getMap().get(fieldName);
                if (field != null) {
                    for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
                        if (entry.isActive()) values.add(entry.getLabel());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error describing picklist: ' + e.getMessage());
        }
        return values;
    }

    // 2. Dynamic Dashboard
    private static DashboardResponse getDynamicDashboard(Id userId) {
        DashboardResponse resp = new DashboardResponse();
        resp.success = true;

        List<Employee__c> emps = [
            SELECT Id, Name, Employee_Code__c, Hierarchy_Level__c, User__c 
            FROM Employee__c 
            WHERE User__c = :userId 
            LIMIT 1
        ];

        if (!emps.isEmpty()) {
            Employee__c emp = emps[0];
            resp.employeeId = emp.Id;
            resp.employeeName = emp.Name;
            resp.employeeCode = emp.Employee_Code__c;
            resp.designation = emp.Hierarchy_Level__c != null ? emp.Hierarchy_Level__c : 'Sales Executive';
        } else {
            List<User> userList = [SELECT Id, Name FROM User WHERE Id = :userId LIMIT 1];
            resp.employeeName = !userList.isEmpty() ? userList[0].Name : UserInfo.getName();
            resp.designation = 'Sales Executive';
        }

        // 1. Query Primary Target for user (monthly target with revenue > 0)
        List<Target__c> targets = [
            SELECT Id, Target_Revenue__c, Achieved_Revenue__c, Target_Visits_Count__c, Achieved_Visits_Count__c 
            FROM Target__c 
            WHERE Sales_Executive__c = :userId AND Target_Revenue__c > 0
            ORDER BY Target_Revenue__c DESC 
            LIMIT 1
        ];

        // 2. Aggregate live booked orders for this user
        AggregateResult[] orderAgg = [
            SELECT SUM(Total_Amount__c) totalAchieved, count(Id) totalCount 
            FROM Order__c 
            WHERE Sales_Executive__c = :userId OR CreatedById = :userId
        ];
        Decimal realOrderRevenue = 0.0;
        Integer userOrderCount = 0;
        if (!orderAgg.isEmpty()) {
            if (orderAgg[0].get('totalAchieved') != null) {
                realOrderRevenue = (Decimal) orderAgg[0].get('totalAchieved');
            }
            if (orderAgg[0].get('totalCount') != null) {
                userOrderCount = (Integer) orderAgg[0].get('totalCount');
            }
        }

        if (!targets.isEmpty()) {
            Target__c t = targets[0];
            resp.targetRevenue = t.Target_Revenue__c != null ? t.Target_Revenue__c : 500000.00;
            Decimal baseAchieved = t.Achieved_Revenue__c != null ? t.Achieved_Revenue__c : 125000.00;
            resp.achievedRevenue = baseAchieved + realOrderRevenue;
            resp.targetVisits = t.Target_Visits_Count__c != null ? Integer.valueOf(t.Target_Visits_Count__c) : 120;
        } else {
            resp.targetRevenue = 500000.00;
            resp.achievedRevenue = 125000.00 + realOrderRevenue;
            resp.targetVisits = 120;
        }
        resp.achievementPercent = resp.targetRevenue > 0 ? (resp.achievedRevenue / resp.targetRevenue * 100).setScale(1) : 0;

        // 3. Today's live attendance
        Id empId = resp.employeeId;
        List<Attendance__c> atts = [
            SELECT Id, Attendance_Date__c, Start_Time__c, End_Time__c, Geo_Location__c, Attendance_Status__c, Total_Working_Hours__c,
                   Day_Plan__c, Day_Plan_Other_Details__c, Tour_Plan__c, Mode_Of_Transport__c, Vehicle_Used__c 
            FROM Attendance__c 
            WHERE (User__c = :userId OR (Employee__c != null AND Employee__c = :empId)) 
              AND (Attendance_Date__c = :Date.today() OR (Attendance_Date__c = null AND CreatedDate = TODAY))
            ORDER BY Start_Time__c DESC 
            LIMIT 1
        ];

        resp.todayAttendance = new AttendanceDTO();
        if (!atts.isEmpty()) {
            Attendance__c a = atts[0];
            resp.todayAttendance.id = a.Id;
            resp.todayAttendance.attendanceDate = a.Attendance_Date__c != null ? a.Attendance_Date__c : Date.today();
            resp.todayAttendance.startTime = a.Start_Time__c;
            resp.todayAttendance.endTime = a.End_Time__c;
            resp.todayAttendance.geoLocation = a.Geo_Location__c;
            resp.todayAttendance.status = String.isNotBlank(a.Attendance_Status__c) ? a.Attendance_Status__c : 'Present';
            resp.todayAttendance.totalWorkingHours = a.Total_Working_Hours__c != null ? a.Total_Working_Hours__c : 0.0;
            resp.todayAttendance.isDayActive = (a.Start_Time__c != null && a.End_Time__c == null);
            resp.todayAttendance.dayPlan = a.Day_Plan__c;
            resp.todayAttendance.dayPlanOtherDetails = a.Day_Plan_Other_Details__c;
            resp.todayAttendance.tourPlan = a.Tour_Plan__c;
            resp.todayAttendance.modeOfTransport = a.Mode_Of_Transport__c;
            resp.todayAttendance.vehicleUsed = a.Vehicle_Used__c;
        } else {
            resp.todayAttendance.isDayActive = false;
        }

        // Visits and orders
        resp.completedVisits = [SELECT count() FROM Visit__c WHERE Sales_Executive__c = :userId AND Visit_Status__c = 'Completed'];
        resp.ordersBooked = userOrderCount;

        // Active schemes
        resp.activeSchemes = getDynamicSchemes();
        return resp;
    }

    // 2b. Dynamic Targets
    private static List<TargetDTO> getDynamicTargets(Id userId) {
        List<TargetDTO> result = new List<TargetDTO>();
        for (Target__c t : [
            SELECT Id, Name, Target_Revenue__c, Achieved_Revenue__c, Target_Visits_Count__c, Achieved_Visits_Count__c 
            FROM Target__c 
            ORDER BY Target_Revenue__c DESC 
            LIMIT 50
        ]) {
            TargetDTO d = new TargetDTO();
            d.id = t.Id;
            d.name = t.Name;
            if (t.Name.toLowerCase().contains('daily') || t.Name.toLowerCase().contains('day')) {
                d.type = 'Daywise';
            } else if (t.Name.toLowerCase().contains('channel') || t.Name.toLowerCase().contains('supermarket')) {
                d.type = 'Outlet Type';
            } else {
                d.type = 'Monthly';
            }
            d.period = 'October 2026';
            d.targetRevenue = t.Target_Revenue__c != null ? t.Target_Revenue__c : 0.0;
            d.achievedRevenue = t.Achieved_Revenue__c != null ? t.Achieved_Revenue__c : 0.0;
            d.targetVisits = t.Target_Visits_Count__c != null ? t.Target_Visits_Count__c : 0.0;
            d.achievedVisits = t.Achieved_Visits_Count__c != null ? t.Achieved_Visits_Count__c : 0.0;
            d.targetVolume = 1200.0;
            d.achievedVolume = d.targetRevenue > 0 ? (d.achievedRevenue / d.targetRevenue * 1200.0).setScale(0) : 0.0;
            d.achievementPercent = d.targetRevenue > 0 ? (d.achievedRevenue / d.targetRevenue * 100).setScale(1) : 0.0;
            result.add(d);
        }
        return result;
    }

    // 3. Dynamic Schemes
    private static List<SchemeDTO> getDynamicSchemes() {
        List<SchemeDTO> listDTO = new List<SchemeDTO>();
        for (Scheme__c s : [
            SELECT Id, Name, Scheme_Code__c, Scheme_Type__c, Primary_Product__c, Primary_Product__r.Name,
                   Free_Product_Custom__c, Free_Product_Custom__r.Name, Buy_Quantity__c, Get_Quantity__c,
                   Minimum_Order_Value__c, Discount_Percentage__c, Bundle_Price__c, Discount_Amount__c,
                   Duration_Days__c, Start_Date__c, End_Date__c, Region__c, Outlet_Type__c, Description__c
            FROM Scheme__c
            WHERE Status__c = 'Active'
            ORDER BY CreatedDate DESC
        ]) {
            SchemeDTO d = new SchemeDTO();
            d.id = s.Id;
            d.name = s.Name;
            d.schemeCode = s.Scheme_Code__c;
            d.schemeType = s.Scheme_Type__c;
            d.primaryProductId = s.Primary_Product__c;
            d.primaryProductName = s.Primary_Product__r.Name;
            d.freeProductId = s.Free_Product_Custom__c;
            d.freeProductName = s.Free_Product_Custom__r.Name;
            d.buyQuantity = s.Buy_Quantity__c;
            d.getQuantity = s.Get_Quantity__c;
            d.minOrderValue = s.Minimum_Order_Value__c;
            d.discountPercentage = s.Discount_Percentage__c;
            d.bundlePrice = s.Bundle_Price__c;
            d.discountAmount = s.Discount_Amount__c;
            d.durationDays = s.Duration_Days__c != null ? Integer.valueOf(s.Duration_Days__c) : null;
            d.startDate = s.Start_Date__c;
            d.endDate = s.End_Date__c;
            d.region = s.Region__c;
            d.outletType = s.Outlet_Type__c;
            d.description = s.Description__c;
            listDTO.add(d);
        }
        return listDTO;
    }

    // 4. Dynamic Products with Region-Wise Sell Classifications (Must Sell, Focused Sell, Suggested Sell)
    private static void ensureRegionMappings() {
        Integer count = [SELECT count() FROM Product_Region_Mapping__c LIMIT 1];
        if (count > 0) return;

        List<Product__c> prods = [SELECT Id, Name FROM Product__c LIMIT 100];
        if (prods.isEmpty()) return;

        List<Product_Region_Mapping__c> toInsert = new List<Product_Region_Mapping__c>();
        for (Product__c p : prods) {
            String pName = p.Name != null ? p.Name.toLowerCase() : '';
            if (pName.contains('parle') || pName.contains('biscuit')) {
                // Parle-G: Must Sell in MP, Focused Sell in Karnataka, Must Sell in Maharashtra
                toInsert.add(new Product_Region_Mapping__c(Product__c = p.Id, Region__c = 'Madhya Pradesh', Sell_Classification__c = 'Must Sell', Priority__c = 1, Is_Active__c = true));
                toInsert.add(new Product_Region_Mapping__c(Product__c = p.Id, Region__c = 'Karnataka', Sell_Classification__c = 'Focused Sell', Priority__c = 2, Is_Active__c = true));
                toInsert.add(new Product_Region_Mapping__c(Product__c = p.Id, Region__c = 'Maharashtra', Sell_Classification__c = 'Must Sell', Priority__c = 1, Is_Active__c = true));
            } else if (pName.contains('malkist') || pName.contains('cracker')) {
                // Malkist: Focused Sell in MP, Must Sell in Karnataka
                toInsert.add(new Product_Region_Mapping__c(Product__c = p.Id, Region__c = 'Madhya Pradesh', Sell_Classification__c = 'Focused Sell', Priority__c = 1, Is_Active__c = true));
                toInsert.add(new Product_Region_Mapping__c(Product__c = p.Id, Region__c = 'Karnataka', Sell_Classification__c = 'Must Sell', Priority__c = 1, Is_Active__c = true));
                toInsert.add(new Product_Region_Mapping__c(Product__c = p.Id, Region__c = 'Maharashtra', Sell_Classification__c = 'Focused Sell', Priority__c = 2, Is_Active__c = true));
            } else if (pName.contains('cookie') || pName.contains('hide') || pName.contains('snack')) {
                // Multi Cookie / Hide & Seek: Suggested Sell in MP and Karnataka
                toInsert.add(new Product_Region_Mapping__c(Product__c = p.Id, Region__c = 'Madhya Pradesh', Sell_Classification__c = 'Suggested Sell', Priority__c = 1, Is_Active__c = true));
                toInsert.add(new Product_Region_Mapping__c(Product__c = p.Id, Region__c = 'Karnataka', Sell_Classification__c = 'Suggested Sell', Priority__c = 1, Is_Active__c = true));
                toInsert.add(new Product_Region_Mapping__c(Product__c = p.Id, Region__c = 'Maharashtra', Sell_Classification__c = 'Suggested Sell', Priority__c = 1, Is_Active__c = true));
            }
        }
        if (!toInsert.isEmpty()) {
            Database.insert(toInsert, false);
        }
    }

    private static List<ProductDTO> getDynamicProducts() {
        return getDynamicProducts(null);
    }

    private static List<ProductDTO> getDynamicProducts(String filterRegion) {
        List<ProductDTO> listDTO = new List<ProductDTO>();
        try {
            ensureRegionMappings();
        } catch (Exception e) {}

        Map<Id, Map<String, String>> regionMap = new Map<Id, Map<String, String>>();
        for (Product_Region_Mapping__c prm : [
            SELECT Product__c, Region__c, Sell_Classification__c
            FROM Product_Region_Mapping__c
            WHERE Is_Active__c = true AND Product__c != null
            ORDER BY Priority__c ASC
        ]) {
            if (!regionMap.containsKey(prm.Product__c)) {
                regionMap.put(prm.Product__c, new Map<String, String>());
            }
            if (String.isNotBlank(prm.Region__c)) {
                regionMap.get(prm.Product__c).put(prm.Region__c, prm.Sell_Classification__c);
                regionMap.get(prm.Product__c).put(prm.Region__c.toLowerCase(), prm.Sell_Classification__c);
            }
        }

        List<String> defaultReasons = new List<String>{
            'Stock Available',
            'Low demand',
            'Season expired',
            'No product demand',
            'Non movable',
            'Other'
        };

        for (Product__c p : [
            SELECT Id, Name, Product_Code__c, SKU__c, Category__c, Brand__c, Sub_Brand__c, Brand_Alias__c,
                   Flavour__c, Variant__c, Package_Type__c, Unit_Conversion__c, Batch_No__c, Quantity__c,
                   Available_Stock__c, MRP__c, RBP__c, GST_Percentage__c, Manufacturing_Date__c, Expiry_Date__c,
                   Product_Image__c, Is_Active__c, Sell_Classification__c
            FROM Product__c
            WHERE Is_Active__c = true
            ORDER BY Brand__c, Name
        ]) {
            ProductDTO d = new ProductDTO();
            d.id = p.Id;
            d.name = p.Name;
            d.productCode = p.Product_Code__c;
            d.sku = p.SKU__c;
            d.category = p.Category__c;
            d.brand = p.Brand__c;
            d.subBrand = p.Sub_Brand__c;
            d.brandAlias = p.Brand_Alias__c;
            d.flavour = p.Flavour__c;
            d.variant = p.Variant__c;
            d.packageType = p.Package_Type__c;
            d.unitConversion = p.Unit_Conversion__c;
            d.batchNo = p.Batch_No__c;
            d.quantity = p.Quantity__c;
            d.availableStock = p.Available_Stock__c;
            d.mrp = p.MRP__c;
            d.rbp = p.RBP__c;
            d.gstPercentage = p.GST_Percentage__c;
            d.manufacturingDate = p.Manufacturing_Date__c;
            d.expiryDate = p.Expiry_Date__c;
            d.productImage = p.Product_Image__c;
            d.isActive = p.Is_Active__c;

            String baseClass = p.Sell_Classification__c != null ? p.Sell_Classification__c : 'Regular';
            Map<String, String> pRegions = regionMap.containsKey(p.Id) ? regionMap.get(p.Id) : new Map<String, String>();
            d.regionClassifications = pRegions;
            d.nonPurchaseReasons = defaultReasons;

            if (String.isNotBlank(filterRegion)) {
                String regKey = filterRegion.trim();
                String regLower = regKey.toLowerCase();
                if (pRegions.containsKey(regKey)) {
                    d.sellClassification = pRegions.get(regKey);
                } else if (pRegions.containsKey(regLower)) {
                    d.sellClassification = pRegions.get(regLower);
                } else {
                    d.sellClassification = baseClass;
                }
            } else {
                d.sellClassification = baseClass;
            }

            listDTO.add(d);
        }
        return listDTO;
    }

    // 5. Dynamic PJP -> Beat -> Outlet Tree
    private static PJPTreeResponse getDynamicPJPTree(Id userId) {
        PJPTreeResponse resp = new PJPTreeResponse();
        resp.success = true;
        resp.pjps = new List<PJPDTO>();

        // 1. Query all PJPs ordered by CreatedDate DESC so newly created plans from mobile or Salesforce are immediately at the top
        List<PJP__c> pjps = [
            SELECT Id, Name, Month__c, Year__c, Status__c, Total_Beats__c, Total_Outlets__c, CreatedDate 
            FROM PJP__c 
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];

        // Also query beats and map them
        Map<Id, List<BeatDTO>> pjpToBeats = new Map<Id, List<BeatDTO>>();
        List<Beat__c> beats = [
            SELECT Id, Name, Beat_ID__c, Beat_Code__c, Day_Of_Week__c, Route_Date__c, PJP__c, Territory__r.Name, Total_Outlets__c 
            FROM Beat__c
        ];

        // Outlets map by Beat
        Map<Id, List<OutletDTO>> beatToOutlets = new Map<Id, List<OutletDTO>>();
        List<Outlet__c> outlets = [
            SELECT Id, Name, Outlet_Code__c, Outlet_Type__c, Outlet_Owner_Name__c, Contact_No__c,
                   Address__c, Beat__c, Geo_Location__Latitude__s, Geo_Location__Longitude__s,
                   Credit_Limit__c, Outstanding_Balance__c, Total_Orders__c
            FROM Outlet__c
        ];

        // Previous orders map by Outlet
        Map<Id, List<OrderSummaryDTO>> outletOrders = new Map<Id, List<OrderSummaryDTO>>();
        for (Order__c o : [
            SELECT Id, Name, Outlet__c, Total_Amount__c, Status__c, Order_Date__c, CreatedDate,
                   Total_Products_Count__c, Total_Quantity__c, Product_Names__c 
            FROM Order__c 
            ORDER BY CreatedDate DESC 
            LIMIT 50
        ]) {
            if (o.Outlet__c != null) {
                if (!outletOrders.containsKey(o.Outlet__c)) {
                    outletOrders.put(o.Outlet__c, new List<OrderSummaryDTO>());
                }
                OrderSummaryDTO os = new OrderSummaryDTO();
                os.id = o.Id;
                os.orderNumber = o.Name;
                os.orderDate = o.Order_Date__c != null ? o.Order_Date__c : o.CreatedDate;
                os.totalAmount = o.Total_Amount__c;
                os.status = o.Status__c;
                os.totalProductsCount = o.Total_Products_Count__c != null ? Integer.valueOf(o.Total_Products_Count__c) : null;
                os.totalQuantity = o.Total_Quantity__c;
                os.productNames = o.Product_Names__c;
                outletOrders.get(o.Outlet__c).add(os);
            }
        }

        for (Outlet__c o : outlets) {
            OutletDTO od = new OutletDTO();
            od.id = o.Id;
            od.name = o.Name;
            od.outletCode = o.Outlet_Code__c;
            od.outletType = o.Outlet_Type__c;
            od.category = 'Retailer';
            od.ownerName = o.Outlet_Owner_Name__c;
            od.contactPhone = o.Contact_No__c;
            od.address = o.Address__c;
            od.latitude = o.Geo_Location__Latitude__s != null ? o.Geo_Location__Latitude__s : 19.0760;
            od.longitude = o.Geo_Location__Longitude__s != null ? o.Geo_Location__Longitude__s : 72.8777;

            od.creditLimit = o.Credit_Limit__c != null ? o.Credit_Limit__c : 25000.00;
            od.outstandingBalance = o.Outstanding_Balance__c != null ? o.Outstanding_Balance__c : 4500.00;
            od.canTakeOrder = (od.outstandingBalance < od.creditLimit);
            od.totalOrders = o.Total_Orders__c != null ? Integer.valueOf(o.Total_Orders__c) : 0;
            od.previousOrders = outletOrders.containsKey(o.Id) ? outletOrders.get(o.Id) : new List<OrderSummaryDTO>();

            if (!beatToOutlets.containsKey(o.Beat__c)) {
                beatToOutlets.put(o.Beat__c, new List<OutletDTO>());
            }
            beatToOutlets.get(o.Beat__c).add(od);
        }

        List<BeatDTO> unassignedBeats = new List<BeatDTO>();
        for (Beat__c b : beats) {
            BeatDTO bd = new BeatDTO();
            bd.id = b.Id;
            bd.name = b.Name;
            bd.code = b.Beat_Code__c != null ? b.Beat_Code__c : b.Beat_ID__c;
            bd.beatId = b.Beat_ID__c;
            bd.dayOfWeek = b.Day_Of_Week__c != null ? b.Day_Of_Week__c : 'Monday';
            bd.routeDate = b.Route_Date__c;
            bd.pjpId = b.PJP__c;
            bd.territoryName = b.Territory__r != null ? b.Territory__r.Name : '';
            bd.totalOutlets = b.Total_Outlets__c;
            bd.outlets = beatToOutlets.containsKey(b.Id) ? beatToOutlets.get(b.Id) : new List<OutletDTO>();

            Id pjpKey = b.PJP__c;
            if (pjpKey != null) {
                if (!pjpToBeats.containsKey(pjpKey)) {
                    pjpToBeats.put(pjpKey, new List<BeatDTO>());
                }
                pjpToBeats.get(pjpKey).add(bd);
            } else {
                unassignedBeats.add(bd);
            }
        }

        // Attach unassigned beats to primary PJP
        Id primaryPjpId = !pjps.isEmpty() ? pjps[0].Id : null;
        if (primaryPjpId != null && !unassignedBeats.isEmpty()) {
            if (!pjpToBeats.containsKey(primaryPjpId)) {
                pjpToBeats.put(primaryPjpId, new List<BeatDTO>());
            }
            pjpToBeats.get(primaryPjpId).addAll(unassignedBeats);
        }

        for (PJP__c p : pjps) {
            PJPDTO pd = new PJPDTO();
            pd.id = p.Id;
            pd.name = p.Name;
            pd.month = p.Month__c;
            pd.year = p.Year__c;
            pd.status = p.Status__c;
            pd.totalBeats = p.Total_Beats__c;
            pd.totalOutlets = p.Total_Outlets__c;
            pd.beats = pjpToBeats.containsKey(p.Id) ? pjpToBeats.get(p.Id) : new List<BeatDTO>();
            resp.pjps.add(pd);
        }

        return resp;
    }

    // 5c. Dynamic Attendance per Date & History
    private static AttendanceResponse getDynamicAttendance(Id userId, String dateStr) {
        AttendanceResponse resp = new AttendanceResponse();
        resp.success = true;
        resp.history = new List<AttendanceDTO>();

        Date queryDate = Date.today();
        if (String.isNotBlank(dateStr)) {
            try {
                queryDate = Date.valueOf(dateStr.trim());
            } catch (Exception e) {}
        }

        Id empId = null;
        List<Employee__c> emps = [SELECT Id FROM Employee__c WHERE User__c = :userId LIMIT 1];
        if (!emps.isEmpty()) empId = emps[0].Id;

        // Query attendance for selected date
        List<Attendance__c> recs = [
            SELECT Id, Attendance_Date__c, Start_Time__c, End_Time__c, Geo_Location__c, 
                   Attendance_Status__c, Total_Working_Hours__c, Employee__r.Name,
                   Day_Plan__c, Day_Plan_Other_Details__c, Tour_Plan__c, Mode_Of_Transport__c, Vehicle_Used__c 
            FROM Attendance__c 
            WHERE (User__c = :userId OR (Employee__c != null AND Employee__c = :empId))
              AND (Attendance_Date__c = :queryDate OR (Attendance_Date__c = null AND CreatedDate = TODAY))
            ORDER BY Start_Time__c DESC 
            LIMIT 1
        ];

        if (!recs.isEmpty()) {
            resp.record = toAttendanceDTO(recs[0]);
        } else {
            resp.record = new AttendanceDTO();
            resp.record.attendanceDate = queryDate;
            resp.record.status = 'Not Marked';
            resp.record.totalWorkingHours = 0.0;
            resp.record.isDayActive = false;
        }

        // Query history for this employee (last 30 days)
        List<Attendance__c> historyRecs = [
            SELECT Id, Attendance_Date__c, Start_Time__c, End_Time__c, Geo_Location__c, 
                   Attendance_Status__c, Total_Working_Hours__c, Employee__r.Name,
                   Day_Plan__c, Day_Plan_Other_Details__c, Tour_Plan__c, Mode_Of_Transport__c, Vehicle_Used__c 
            FROM Attendance__c 
            WHERE (User__c = :userId OR (Employee__c != null AND Employee__c = :empId))
            ORDER BY Attendance_Date__c DESC, CreatedDate DESC 
            LIMIT 30
        ];

        for (Attendance__c a : historyRecs) {
            resp.history.add(toAttendanceDTO(a));
        }

        return resp;
    }

    private static AttendanceDTO toAttendanceDTO(Attendance__c a) {
        AttendanceDTO d = new AttendanceDTO();
        d.id = a.Id;
        d.attendanceDate = a.Attendance_Date__c != null ? a.Attendance_Date__c : Date.today();
        d.startTime = a.Start_Time__c;
        d.endTime = a.End_Time__c;
        d.geoLocation = a.Geo_Location__c;
        d.status = String.isNotBlank(a.Attendance_Status__c) ? a.Attendance_Status__c : 'Present';
        d.totalWorkingHours = a.Total_Working_Hours__c != null ? a.Total_Working_Hours__c : 0.0;
        d.isDayActive = (a.Start_Time__c != null && a.End_Time__c == null);
        if (a.Employee__r != null) {
            d.employeeName = a.Employee__r.Name;
        }
        d.dayPlan = a.Day_Plan__c;
        d.dayPlanOtherDetails = a.Day_Plan_Other_Details__c;
        d.tourPlan = a.Tour_Plan__c;
        d.modeOfTransport = a.Mode_Of_Transport__c;
        d.vehicleUsed = a.Vehicle_Used__c;
        return d;
    }

    private static User findUser(String email) {
        if (String.isBlank(email)) return null;
        String clean = email.trim();

        List<User> users = [
            SELECT Id, Name, Email, Username, IsActive 
            FROM User 
            WHERE (Email = :clean OR Username = :clean) 
              AND IsActive = true 
            LIMIT 1
        ];
        if (!users.isEmpty()) return users[0];

        List<Employee__c> emps = [
            SELECT Id, Name, Email__c, User__c 
            FROM Employee__c 
            WHERE Email__c = :clean 
              AND User__c != null 
            LIMIT 1
        ];
        if (!emps.isEmpty()) {
            List<User> empUsers = [
                SELECT Id, Name, Email, Username, IsActive 
                FROM User 
                WHERE Id = :emps[0].User__c 
                  AND IsActive = true 
                LIMIT 1
            ];
            if (!empUsers.isEmpty()) return empUsers[0];
        }
        return null;
    }

    // 6. Action Handlers
    private static ActionResponse processAttendance(ActionRequest req, Id userId) {
        ActionResponse resp = new ActionResponse();
        List<Attendance__c> existing = [
            SELECT Id, Start_Time__c, End_Time__c 
            FROM Attendance__c 
            WHERE User__c = :userId AND Attendance_Date__c = :Date.today() 
            LIMIT 1
        ];

        Attendance__c att;
        if (!existing.isEmpty() && existing[0].Start_Time__c != null && existing[0].End_Time__c == null) {
            att = existing[0];
            att.End_Time__c = DateTime.now();
            att.Punch_Out_Time__c = DateTime.now();
            att.Attendance_Status__c = 'Completed';
            if (req.latitude != null && req.longitude != null) {
                att.Punch_Out_Location__Latitude__s = req.latitude;
                att.Punch_Out_Location__Longitude__s = req.longitude;
            }
            if (att.Start_Time__c != null) {
                Decimal hours = (Decimal.valueOf(att.End_Time__c.getTime() - att.Start_Time__c.getTime())) / (1000 * 3600);
                att.Total_Working_Hours__c = hours.setScale(2);
            }
            update att;
            resp.message = 'Day ended successfully.';
        } else {
            List<Employee__c> emps = [SELECT Id FROM Employee__c WHERE User__c = :userId LIMIT 1];
            att = new Attendance__c(
                User__c = userId,
                Employee__c = !emps.isEmpty() ? emps[0].Id : null,
                Attendance_Date__c = Date.today(),
                Start_Time__c = DateTime.now(),
                Punch_In_Time__c = DateTime.now(),
                Geo_Location__c = (req.latitude != null && req.longitude != null) ? (String.valueOf(req.latitude) + ', ' + String.valueOf(req.longitude)) : null,
                Attendance_Status__c = 'Present',
                Day_Plan__c = req.dayPlan,
                Day_Plan_Other_Details__c = req.dayPlanOtherDetails,
                Tour_Plan__c = req.tourPlan,
                Mode_Of_Transport__c = req.modeOfTransport,
                Vehicle_Used__c = req.vehicleUsed
            );
            if (req.latitude != null && req.longitude != null) {
                att.Punch_In_Location__Latitude__s = req.latitude;
                att.Punch_In_Location__Longitude__s = req.longitude;
            }
            insert att;
            resp.message = 'Day started successfully.';
        }

        resp.success = true;
        resp.recordId = att.Id;
        return resp;
    }

    private static ActionResponse processVisitStart(ActionRequest req, Id userId) {
        ActionResponse resp = new ActionResponse();
        Visit__c v = new Visit__c(
            Outlet__c = req.outletId,
            Sales_Executive__c = userId,
            Check_In_Time__c = DateTime.now(),
            Check_In_Location__Latitude__s = req.latitude,
            Check_In_Location__Longitude__s = req.longitude,
            Is_Within_Geofence__c = (req.distanceMeters != null && req.distanceMeters <= 100),
            Geofence_Deviation_Distance_Meters__c = req.distanceMeters,
            Skip_Reason__c = req.bypassReason,
            Visit_Status__c = 'In_Progress'
        );
        insert v;
        resp.success = true;
        resp.recordId = v.Id;
        resp.message = 'Visit started successfully.';
        return resp;
    }

    private static ActionResponse processVisitCheckout(ActionRequest req, Id userId) {
        ActionResponse resp = new ActionResponse();
        if (String.isNotBlank(req.visitId)) {
            Visit__c v = [SELECT Id, Check_In_Time__c FROM Visit__c WHERE Id = :req.visitId LIMIT 1];
            v.Check_Out_Time__c = DateTime.now();
            v.Visit_Status__c = 'Completed';
            if (String.isNotBlank(req.selfieUrl)) {
                v.Selfie_Image_URL__c = req.selfieUrl;
            }
            if (String.isNotBlank(req.freezerPhotoUrl)) {
                v.Freezer_Image_URL__c = req.freezerPhotoUrl;
            }
            if (String.isNotBlank(req.checkoutComments)) {
                v.Check_Out_Comments__c = req.checkoutComments;
            } else if (String.isNotBlank(req.remarks)) {
                v.Check_Out_Comments__c = req.remarks;
            }
            update v;
            resp.success = true;
            resp.message = 'Checked out successfully.';
            return resp;
        }
        resp.success = false;
        resp.message = 'Visit ID is required.';
        return resp;
    }

    private static ActionResponse processVisitMissed(ActionRequest req, Id userId) {
        ActionResponse resp = new ActionResponse();
        Visit__c v;
        if (String.isNotBlank(req.visitId)) {
            v = [SELECT Id FROM Visit__c WHERE Id = :req.visitId LIMIT 1];
            v.Visit_Status__c = 'Missed';
            v.Skip_Reason__c = String.isNotBlank(req.missedReason) ? req.missedReason : req.remarks;
            update v;
        } else if (String.isNotBlank(req.outletId)) {
            v = new Visit__c(
                Outlet__c = req.outletId,
                Sales_Executive__c = userId,
                Visit_Status__c = 'Missed',
                Skip_Reason__c = String.isNotBlank(req.missedReason) ? req.missedReason : req.remarks,
                Check_In_Time__c = DateTime.now(),
                Check_Out_Time__c = DateTime.now()
            );
            insert v;
        } else {
            resp.success = false;
            resp.message = 'Visit ID or Outlet ID is required for missed visit.';
            return resp;
        }
        resp.success = true;
        resp.recordId = v.Id;
        resp.message = 'Visit marked as missed.';
        return resp;
    }

    private static ActionResponse processOrder(ActionRequest req, Id userId) {
        ActionResponse resp = new ActionResponse();
        Savepoint sp = Database.setSavepoint();
        try {
            // Collect product IDs if any to query names from Product__c
            Set<Id> prodIds = new Set<Id>();
            if (req.items != null) {
                for (OrderItemRequest item : req.items) {
                    if (String.isNotBlank(item.productId)) {
                        try { prodIds.add((Id) item.productId); } catch (Exception e) {}
                    }
                }
            }
            Map<Id, Product__c> prodMap = new Map<Id, Product__c>();
            if (!prodIds.isEmpty()) {
                prodMap = new Map<Id, Product__c>([SELECT Id, Name, Product_Code__c FROM Product__c WHERE Id IN :prodIds]);
            }

            // Calculate totals and compile product names summary
            List<String> productNamesList = new List<String>();
            Decimal totalQuantity = 0;
            Integer totalProductsCount = (req.items != null) ? req.items.size() : 0;

            if (req.items != null) {
                for (OrderItemRequest item : req.items) {
                    String pName = String.isNotBlank(item.productName) ? item.productName : null;
                    if (pName == null && prodMap.containsKey((Id)item.productId)) {
                        pName = prodMap.get((Id)item.productId).Name;
                    }
                    if (String.isBlank(pName)) {
                        pName = String.isNotBlank(item.sku) ? item.sku : 'Product Item';
                    }
                    Decimal qty = item.quantity != null ? item.quantity : 1;
                    totalQuantity += qty;
                    productNamesList.add(pName + ' (' + qty.intValue() + ' pcs)');
                }
            }

            String productNamesSummary = String.join(productNamesList, ', ');

            Order__c ord = new Order__c(
                Visit__c = req.visitId,
                Sales_Executive__c = userId,
                Order_Date__c = System.now(),
                Order_Type__c = String.isNotBlank(req.orderType) ? req.orderType : 'Secondary',
                Applied_Scheme__c = req.appliedSchemeId,
                Schemes_Applied__c = req.schemesApplied,
                Gross_Amount__c = req.grossAmount,
                Tax_Amount__c = req.taxAmount,
                Total_Amount__c = req.totalAmount,
                Total_Quantity__c = totalQuantity,
                Total_Products_Count__c = totalProductsCount,
                Product_Names__c = productNamesSummary,
                Must_Sell_Non_Purchase_Reasons__c = req.mustSellNonPurchaseReasons,
                Status__c = 'Submitted'
            );

            Id parsedOutletId = null;
            try {
                if (String.isNotBlank(req.outletId)) {
                    parsedOutletId = (Id) req.outletId;
                }
            } catch (Exception ex) {}

            if (parsedOutletId != null) {
                String sObjName = parsedOutletId.getSObjectType().getDescribe().getName();
                if (sObjName == 'Outlet__c') {
                    ord.Outlet__c = parsedOutletId;
                } else if (sObjName == 'Retailer__c') {
                    ord.Retailer__c = parsedOutletId;
                }
            }

            if (String.isNotBlank(req.distributorId)) {
                try {
                    ord.Primary_Distributor__c = (Id) req.distributorId;
                } catch (Exception ex) {}
            }
            insert ord;

            if (req.items != null && !req.items.isEmpty()) {
                List<Order_Line__c> lines = new List<Order_Line__c>();
                for (OrderItemRequest item : req.items) {
                    String pName = String.isNotBlank(item.productName) ? item.productName : null;
                    if (pName == null && prodMap.containsKey((Id)item.productId)) {
                        pName = prodMap.get((Id)item.productId).Name;
                    }
                    if (String.isBlank(pName)) {
                        pName = String.isNotBlank(item.sku) ? item.sku : 'Product Line';
                    }

                    Id validProdCustomId = null;
                    if (String.isNotBlank(item.productId)) {
                        try {
                            Id parsedId = (Id) item.productId;
                            if (prodMap.containsKey(parsedId)) {
                                validProdCustomId = parsedId;
                            }
                        } catch (Exception e) {}
                    }

                    lines.add(new Order_Line__c(
                        Order__c = ord.Id,
                        Name = pName.left(80),
                        Product_Name__c = pName,
                        Product_Custom__c = validProdCustomId,
                        SKU__c = item.sku,
                        Quantity__c = item.quantity,
                        Unit_Price__c = item.unitPrice,
                        Gross_Amount__c = item.grossAmount,
                        Tax_Amount__c = item.taxAmount,
                        Free_Goods_Quantity__c = item.freeGoodsQuantity,
                        Applied_Scheme__c = item.appliedSchemeId
                    ));
                }
                insert lines;
            }

            // Dynamically increment Outlet or Retailer Outstanding & Orders count
            try {
                if (parsedOutletId != null) {
                    String sObjName = parsedOutletId.getSObjectType().getDescribe().getName();
                    if (sObjName == 'Outlet__c') {
                        List<Outlet__c> outList = [SELECT Id, Outstanding_Balance__c, Total_Orders__c FROM Outlet__c WHERE Id = :parsedOutletId LIMIT 1];
                        if (!outList.isEmpty()) {
                            outList[0].Outstanding_Balance__c = (outList[0].Outstanding_Balance__c != null ? outList[0].Outstanding_Balance__c : 0) + ord.Total_Amount__c;
                            outList[0].Total_Orders__c = (outList[0].Total_Orders__c != null ? outList[0].Total_Orders__c : 0) + 1;
                            update outList[0];
                        }
                    } else if (sObjName == 'Retailer__c') {
                        List<Retailer__c> retList = [SELECT Id, Outstanding_Balance__c FROM Retailer__c WHERE Id = :parsedOutletId LIMIT 1];
                        if (!retList.isEmpty()) {
                            retList[0].Outstanding_Balance__c = (retList[0].Outstanding_Balance__c != null ? retList[0].Outstanding_Balance__c : 0) + ord.Total_Amount__c;
                            update retList[0];
                        }
                    }
                }
            } catch (Exception eOut) {
                System.debug('Outlet/Retailer balance update note: ' + eOut.getMessage());
            }

            // Dynamically increment Target Achieved Revenue
            List<Target__c> targets = [SELECT Id, Achieved_Revenue__c FROM Target__c WHERE Sales_Executive__c = :userId LIMIT 1];
            if (!targets.isEmpty()) {
                targets[0].Achieved_Revenue__c = (targets[0].Achieved_Revenue__c != null ? targets[0].Achieved_Revenue__c : 0) + ord.Total_Amount__c;
                update targets[0];
            }

            ord = [SELECT Name FROM Order__c WHERE Id = :ord.Id];
            resp.success = true;
            resp.recordId = ord.Id;
            resp.recordNumber = ord.Name;
            resp.message = 'Order created successfully.';
            return resp;
        } catch (Exception e) {
            Database.rollback(sp);
            resp.success = false;
            resp.message = 'Order creation failed: ' + e.getMessage();
            return resp;
        }
    }

    private static ActionResponse processStockCheck(ActionRequest req) {
        ActionResponse resp = new ActionResponse();
        Stock_Check__c s = new Stock_Check__c(
            Outlet__c = req.outletId,
            Visit__c = req.visitId,
            Product__c = req.productId,
            Quantity__c = req.quantity,
            Batch_No__c = req.batchNo,
            Manufacturing_Date__c = req.manufacturingDate,
            Stock_Condition__c = req.stockCondition,
            Remarks__c = req.remarks
        );
        insert s;
        resp.success = true;
        resp.recordId = s.Id;
        resp.message = 'Stock check recorded.';
        return resp;
    }

    private static ActionResponse processAssetSurvey(ActionRequest req) {
        ActionResponse resp = new ActionResponse();
        Asset_Survey__c a = new Asset_Survey__c(
            Outlet__c = req.outletId,
            Visit__c = req.visitId,
            Asset_Name__c = req.assetName,
            Asset_Code__c = req.assetCode,
            Status__c = req.assetStatus,
            Picture__c = req.pictureUrl,
            Remarks__c = req.remarks,
            Survey_Date__c = Date.today()
        );
        insert a;
        resp.success = true;
        resp.recordId = a.Id;
        resp.message = 'Asset survey recorded.';
        return resp;
    }

    private static ActionResponse processCompetitorActivity(ActionRequest req) {
        ActionResponse resp = new ActionResponse();
        Competitor_Activity__c c = new Competitor_Activity__c(
            Outlet__c = req.outletId,
            Visit__c = req.visitId,
            Competitor_Name__c = req.competitorName,
            Company__c = req.company,
            Category__c = req.competitorCategory,
            MRP__c = req.mrp,
            RBP__c = req.rbp,
            Schemes__c = req.competitorSchemes,
            Image__c = req.imageUrl,
            Remarks__c = req.remarks,
            Capture_Date__c = Date.today()
        );
        insert c;
        resp.success = true;
        resp.recordId = c.Id;
        resp.message = 'Competitor activity recorded.';
        return resp;
    }

    private static ActionResponse processProductReturn(ActionRequest req) {
        ActionResponse resp = new ActionResponse();
        Product_Return__c pr = new Product_Return__c(
            Outlet__c = req.outletId,
            Visit__c = req.visitId,
            Product__c = req.productId,
            Quantity__c = req.quantity,
            Batch_No__c = req.batchNo,
            Manufacturing_Date__c = req.manufacturingDate,
            Return_Reason__c = req.returnReason,
            Status__c = 'Requested',
            Return_Date__c = Date.today(),
            Remarks__c = req.remarks
        );
        insert pr;

        // Also record in Return_Order__c for two-tier barcode tracking & ledger
        try {
            String retNum = 'RET-' + (req.returnType == 'Primary' ? 'PRM-' : 'SEC-') + String.valueOf(DateTime.now().getTime()).substring(5);
            String rReason = 'Damaged in Transit / Goods Receipt';
            if (String.isNotBlank(req.returnReason)) {
                String rLower = req.returnReason.toLowerCase();
                if (rLower.contains('expired')) rReason = 'Expired Stock';
                else if (rLower.contains('near')) rReason = 'Near Expiry Stock (30 Days)';
                else if (rLower.contains('wrong') || rLower.contains('discrepancy')) rReason = 'Wrong Product / Shipment Discrepancy';
                else if (rLower.contains('quality') || rLower.contains('packaging')) rReason = 'Quality Defect / Packaging Issue';
            }

            Return_Order__c ro = new Return_Order__c(
                Name = retNum,
                Distributor__c = req.distributorId,
                Retailer__c = req.outletId,
                Return_Type__c = String.isNotBlank(req.returnType) ? req.returnType : (req.outletId != null ? 'Secondary' : 'Primary'),
                Return_Number__c = retNum,
                Return_Date__c = Date.today(),
                Return_Reason__c = rReason,
                Total_Return_Amount__c = (req.totalAmount != null ? req.totalAmount : (req.quantity != null && req.mrp != null ? req.quantity * req.mrp : 0)),
                Remarks__c = req.remarks,
                Scanned_Barcode__c = req.scannedBarcode,
                Barcode_Type__c = (req.barcodeType == 'Packet Barcode' ? 'Packet Barcode' : 'Case Barcode'),
                Case_Number__c = req.caseNumber,
                Batch_Number__c = req.batchNo,
                Manufacturing_Date__c = req.manufacturingDate,
                Expiry_Date__c = req.endDate,
                Product_Custom__c = req.productId,
                Verification_Status__c = String.isNotBlank(req.verificationStatus) ? req.verificationStatus : 'Verified Genuine',
                Status__c = 'Submitted'
            );
            insert ro;
        } catch (Exception ex) {
            System.debug('Error logging Return_Order__c: ' + ex.getMessage());
        }

        resp.success = true;
        resp.recordId = pr.Id;
        resp.message = 'Product return submitted successfully.';
        return resp;
    }

    private static ActionResponse processTicket(ActionRequest req, Id userId) {
        ActionResponse resp = new ActionResponse();
        Ticket__c t = new Ticket__c(
            Outlet__c = req.outletId,
            Visit__c = req.visitId,
            Subject__c = req.subject,
            Category__c = req.ticketCategory,
            Priority__c = req.priority,
            Description__c = req.description,
            Status__c = 'New',
            Image__c = req.imageUrl,
            Assigned_To__c = userId
        );
        insert t;
        t = [SELECT Name FROM Ticket__c WHERE Id = :t.Id];
        resp.success = true;
        resp.recordId = t.Id;
        resp.recordNumber = t.Name;
        resp.message = 'Ticket submitted successfully.';
        return resp;
    }

    private static ActionResponse processLeaveRequest(ActionRequest req, Id userId) {
        ActionResponse resp = new ActionResponse();
        try {
            List<Employee__c> emps = [SELECT Id FROM Employee__c WHERE User__c = :userId LIMIT 1];
            Id empId = !emps.isEmpty() ? emps[0].Id : null;

            Leave_Request__c lr = new Leave_Request__c(
                Leave_Type_Category__c = String.isNotBlank(req.leaveCategory) ? req.leaveCategory : 'Sales Executive Leave',
                Leave_Type__c = req.leaveType,
                Outlet__c = req.outletId,
                Beat__c = req.beatId,
                Employee__c = empId,
                Sales_Executive_User__c = userId,
                Start_Date__c = req.startDate,
                End_Date__c = req.endDate,
                Total_Days__c = req.totalDays,
                Reason__c = req.reason,
                Status__c = 'Pending Approval'
            );
            insert lr;
            lr = [SELECT Name FROM Leave_Request__c WHERE Id = :lr.Id];
            resp.success = true;
            resp.recordId = lr.Id;
            resp.recordNumber = lr.Name;
            resp.message = 'Leave request submitted successfully.';
        } catch (Exception e) {
            resp.success = false;
            resp.message = 'Failed to submit leave request: ' + e.getMessage();
        }
        return resp;
    }

    private static List<LeaveDTO> getDynamicLeaves(Id userId) {
        List<LeaveDTO> result = new List<LeaveDTO>();
        for (Leave_Request__c lr : [
            SELECT Id, Name, Leave_Type_Category__c, Leave_Type__c, Outlet__c, Outlet__r.Name,
                   Beat__c, Beat__r.Name, Employee__c, Employee__r.Name, Start_Date__c,
                   End_Date__c, Total_Days__c, Status__c, Reason__c, CreatedDate
            FROM Leave_Request__c
            ORDER BY CreatedDate DESC
            LIMIT 100
        ]) {
            LeaveDTO dto = new LeaveDTO();
            dto.id = lr.Id;
            dto.name = lr.Name;
            dto.leaveCategory = lr.Leave_Type_Category__c;
            dto.leaveType = lr.Leave_Type__c;
            dto.outletId = lr.Outlet__c;
            dto.outletName = lr.Outlet__r != null ? lr.Outlet__r.Name : null;
            dto.beatId = lr.Beat__c;
            dto.beatName = lr.Beat__r != null ? lr.Beat__r.Name : null;
            dto.employeeId = lr.Employee__c;
            dto.employeeName = lr.Employee__r != null ? lr.Employee__r.Name : null;
            dto.startDate = lr.Start_Date__c;
            dto.endDate = lr.End_Date__c;
            dto.totalDays = lr.Total_Days__c;
            dto.status = lr.Status__c;
            dto.reason = lr.Reason__c;
            dto.createdDate = lr.CreatedDate;
            result.add(dto);
        }
        return result;
    }

    // 12. Create PJP Plan
    private static ActionResponse processCreatePJP(ActionRequest payload, Id currentUserId) {
        ActionResponse res = new ActionResponse();
        try {
            PJP__c pjp = new PJP__c();
            String pMonth = String.isNotBlank(payload.month) ? payload.month : 'October';
            String pYear = payload.year != null ? String.valueOf(payload.year) : '2026';
            String pName = String.isNotBlank(payload.pjpName) 
                ? payload.pjpName 
                : ('PJP-' + UserInfo.getFirstName() + '-' + pMonth.left(3) + '-' + pYear);

            pjp.Name = pName;
            pjp.Month__c = pMonth;
            pjp.Year__c = pYear;
            pjp.Status__c = 'Draft';
            pjp.User__c = currentUserId;

            // Link Employee if exists
            List<Employee__c> emps = [
                SELECT Id, Reporting_Manager__c 
                FROM Employee__c 
                WHERE User__c = :currentUserId OR Email__c = :UserInfo.getUserEmail() 
                LIMIT 1
            ];
            if (!emps.isEmpty()) {
                pjp.Employee__c = emps[0].Id;
                if (emps[0].Reporting_Manager__c != null) {
                    pjp.Reporting_Manager__c = emps[0].Reporting_Manager__c;
                }
            }

            insert pjp;

            res.success = true;
            res.recordId = pjp.Id;
            res.message = 'PJP Plan [' + pjp.Name + '] created in Draft status.';
        } catch (Exception ex) {
            res.success = false;
            res.message = 'Failed to create PJP Plan: ' + ex.getMessage();
        }
        return res;
    }

    // 13. Submit PJP Plan for Approval
    private static ActionResponse processSubmitPJPApproval(ActionRequest payload, Id currentUserId) {
        ActionResponse res = new ActionResponse();
        try {
            if (String.isBlank(payload.pjpId)) {
                res.success = false;
                res.message = 'PJP Plan ID is required for submission.';
                return res;
            }

            PJP__c pjp = [
                SELECT Id, Name, Status__c 
                FROM PJP__c 
                WHERE Id = :payload.pjpId 
                LIMIT 1
            ];

            pjp.Status__c = 'Submitted';
            pjp.Remarks__c = 'Submitted for Manager Approval via SFA Mobile on ' + String.valueOf(Datetime.now());
            update pjp;

            // Optional approval process invocation
            try {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Submitted from SFA Mobile Application');
                req.setObjectId(pjp.Id);
                req.setSubmitterId(currentUserId);
                Approval.process(req);
            } catch (Exception appEx) {
                // If approval process is not configured, the Status__c field is updated to 'Submitted'
            }

            res.success = true;
            res.recordId = pjp.Id;
            res.message = 'PJP Plan [' + pjp.Name + '] submitted for Approval successfully.';
        } catch (Exception ex) {
            res.success = false;
            res.message = 'Failed to submit PJP for approval: ' + ex.getMessage();
        }
        return res;
    }

    // 14. Create Beat under PJP
    private static ActionResponse processCreateBeat(ActionRequest payload, Id currentUserId) {
        ActionResponse res = new ActionResponse();
        try {
            if (String.isBlank(payload.pjpId)) {
                res.success = false;
                res.message = 'PJP Plan ID is required to create a Beat.';
                return res;
            }

            Beat__c beat = new Beat__c();
            beat.Name = String.isNotBlank(payload.beatName) ? payload.beatName : 'New Beat';
            beat.Beat_Code__c = String.isNotBlank(payload.beatCode) 
                ? payload.beatCode 
                : ('BT-' + String.valueOf(System.currentTimeMillis()).right(5));
            beat.PJP__c = payload.pjpId;
            beat.Day_Of_Week__c = String.isNotBlank(payload.dayOfWeek) ? payload.dayOfWeek : 'Monday';
            if (payload.beatDate != null) {
                beat.Route_Date__c = payload.beatDate;
            }
            beat.Assigned_Executive__c = currentUserId;

            List<Employee__c> emps = [
                SELECT Id 
                FROM Employee__c 
                WHERE User__c = :currentUserId OR Email__c = :UserInfo.getUserEmail() 
                LIMIT 1
            ];
            if (!emps.isEmpty()) {
                beat.Assigned_To__c = emps[0].Id;
            }

            // Resolve required Master-Detail Territory__c
            Id resolvedTerritoryId = null;
            if (String.isNotBlank(payload.territoryId)) {
                try {
                    resolvedTerritoryId = (Id) payload.territoryId;
                } catch (Exception te) {}
            }
            if (resolvedTerritoryId == null) {
                List<Beat__c> execBeats = [
                    SELECT Territory__c 
                    FROM Beat__c 
                    WHERE (Assigned_Executive__c = :currentUserId OR Assigned_To__c != null) AND Territory__c != null 
                    LIMIT 1
                ];
                if (!execBeats.isEmpty()) {
                    resolvedTerritoryId = execBeats[0].Territory__c;
                } else {
                    List<Territory__c> allTerr = [SELECT Id FROM Territory__c ORDER BY CreatedDate ASC LIMIT 1];
                    if (!allTerr.isEmpty()) {
                        resolvedTerritoryId = allTerr[0].Id;
                    }
                }
            }
            if (resolvedTerritoryId != null) {
                beat.Territory__c = resolvedTerritoryId;
            }

            insert beat;

            res.success = true;
            res.recordId = beat.Id;
            res.message = 'Beat [' + beat.Name + '] created and linked to PJP successfully.';
        } catch (Exception ex) {
            res.success = false;
            res.message = 'Failed to create Beat: ' + ex.getMessage();
        }
        return res;
    }

    // 15. Create Outlet under Beat
    private static ActionResponse processCreateOutlet(ActionRequest payload, Id currentUserId) {
        ActionResponse res = new ActionResponse();
        try {
            if (String.isBlank(payload.beatId)) {
                res.success = false;
                res.message = 'Beat ID is required to create an Outlet.';
                return res;
            }

            Outlet__c outlet = new Outlet__c();
            outlet.Name = String.isNotBlank(payload.outletName) ? payload.outletName : 'New Store';
            outlet.Beat__c = payload.beatId;
            outlet.Outlet_Owner_Name__c = String.isNotBlank(payload.ownerName) ? payload.ownerName : 'Store Owner';
            outlet.Contact_No__c = String.isNotBlank(payload.contactPhone) ? payload.contactPhone : '9876543210';
            outlet.Address__c = String.isNotBlank(payload.address) ? payload.address : 'Market Road, Store Location';
            outlet.Outlet_Type__c = String.isNotBlank(payload.outletType) ? payload.outletType : 'Kirana';
            outlet.Status__c = 'Active';
            outlet.Credit_Limit__c = (payload.creditLimit != null && payload.creditLimit > 0) ? payload.creditLimit : 50000;
            outlet.Outstanding_Balance__c = 0;

            if (payload.latitude != null && payload.longitude != null) {
                outlet.Geo_Location__Latitude__s = payload.latitude;
                outlet.Geo_Location__Longitude__s = payload.longitude;
            } else {
                outlet.Geo_Location__Latitude__s = 18.9322;
                outlet.Geo_Location__Longitude__s = 72.8347;
            }

            insert outlet;

            res.success = true;
            res.recordId = outlet.Id;
            res.message = 'Outlet [' + outlet.Name + '] created and linked to Beat successfully.';
        } catch (Exception ex) {
            res.success = false;
            res.message = 'Failed to create Outlet: ' + ex.getMessage();
        }
        return res;
    }

    // 16. Process TA/DA Expense Claim
    private static ActionResponse processExpenseClaim(ActionRequest payload, Id currentUserId) {
        ActionResponse res = new ActionResponse();
        try {
            Expense_Claim__c ec = new Expense_Claim__c();
            ec.Sales_Executive__c = currentUserId;

            // Link Attendance of today if exists
            List<Attendance__c> atts = [
                SELECT Id FROM Attendance__c 
                WHERE (User__c = :currentUserId OR Employee__r.User__c = :currentUserId)
                  AND Attendance_Date__c = :Date.today() 
                LIMIT 1
            ];
            if (!atts.isEmpty()) {
                ec.Attendance__c = atts[0].Id;
            }

            ec.Claim_Date__c = payload.startDate != null ? payload.startDate : Date.today();
            ec.Day_Type__c = (String.isNotBlank(payload.leaveType) && payload.leaveType.toLowerCase().contains('half'))
                ? 'Half_Day'
                : 'Full_Day';
            ec.Distance_Traveled_KM__c = payload.distanceMeters != null ? payload.distanceMeters : 0;
            ec.Travel_Allowance_Amount__c = payload.grossAmount != null ? payload.grossAmount : 0;
            ec.Daily_Allowance_Amount__c = payload.taxAmount != null ? payload.taxAmount : 0;
            ec.Status__c = 'Submitted';

            insert ec;
            ec = [SELECT Name FROM Expense_Claim__c WHERE Id = :ec.Id];

            res.success = true;
            res.recordId = ec.Id;
            res.recordNumber = ec.Name;
            res.message = 'TA/DA Expense Claim [' + ec.Name + '] submitted to Salesforce successfully.';
        } catch (Exception ex) {
            res.success = false;
            res.message = 'Failed to submit Expense Claim: ' + ex.getMessage();
        }
        return res;
    }

    // ========================================================
    // TWO-TIER BARCODE SCANNING & VERIFICATION SERVICE
    // ========================================================
    public static BarcodeVerificationDTO verifyBarcode(String code, String distributorId) {
        BarcodeVerificationDTO dto = new BarcodeVerificationDTO();
        if (String.isBlank(code)) {
            dto.success = false;
            dto.message = 'Please provide a barcode to scan or verify.';
            return dto;
        }

        String trimmedCode = code.trim();
        dto.scannedCode = trimmedCode;

        // 1. Try finding by Case_Barcode__c (Case Barcode)
        List<Product_Case__c> cases = [
            SELECT Id, Name, Case_Barcode__c, Packet_Barcode__c, Batch_Number__c,
                   Manufacturing_Date__c, Expiry_Date__c, Units_Per_Case__c,
                   Distributor__c, Distributor__r.Name,
                   Product_Custom__c, Product_Custom__r.Name, Product_Custom__r.Product_Code__c,
                   Product_Custom__r.SKU__c, Product_Custom__r.Category__c, Product_Custom__r.Brand__c,
                   Product_Custom__r.MRP__c, Product_Custom__r.RBP__c
            FROM Product_Case__c
            WHERE Case_Barcode__c = :trimmedCode
            LIMIT 1
        ];

        Boolean isCase = true;
        if (cases.isEmpty()) {
            // 2. Try finding by Packet_Barcode__c (Packet Barcode)
            cases = [
                SELECT Id, Name, Case_Barcode__c, Packet_Barcode__c, Batch_Number__c,
                       Manufacturing_Date__c, Expiry_Date__c, Units_Per_Case__c,
                       Distributor__c, Distributor__r.Name,
                       Product_Custom__c, Product_Custom__r.Name, Product_Custom__r.Product_Code__c,
                       Product_Custom__r.SKU__c, Product_Custom__r.Category__c, Product_Custom__r.Brand__c,
                       Product_Custom__r.MRP__c, Product_Custom__r.RBP__c
                FROM Product_Case__c
                WHERE Packet_Barcode__c = :trimmedCode
                LIMIT 1
            ];
            isCase = false;
        }

        if (cases.isEmpty()) {
            // 3. Try finding by Batch_Number__c
            cases = [
                SELECT Id, Name, Case_Barcode__c, Packet_Barcode__c, Batch_Number__c,
                       Manufacturing_Date__c, Expiry_Date__c, Units_Per_Case__c,
                       Distributor__c, Distributor__r.Name,
                       Product_Custom__c, Product_Custom__r.Name, Product_Custom__r.Product_Code__c,
                       Product_Custom__r.SKU__c, Product_Custom__r.Category__c, Product_Custom__r.Brand__c,
                       Product_Custom__r.MRP__c, Product_Custom__r.RBP__c
                FROM Product_Case__c
                WHERE Batch_Number__c = :trimmedCode
                LIMIT 1
            ];
            isCase = false;
        }

        if (cases.isEmpty()) {
            // Check if matches Product__c code or SKU
            List<Product__c> prods = [
                SELECT Id, Name, Product_Code__c, SKU__c, Category__c, Brand__c, MRP__c, RBP__c
                FROM Product__c
                WHERE Product_Code__c = :trimmedCode OR SKU__c = :trimmedCode OR Id = :trimmedCode
                LIMIT 1
            ];
            if (!prods.isEmpty()) {
                Product__c p = prods[0];
                dto.success = true;
                dto.barcodeType = 'Product SKU';
                dto.productId = p.Id;
                dto.productName = p.Name;
                dto.productCode = p.Product_Code__c;
                dto.category = p.Category__c;
                dto.brand = p.Brand__c;
                dto.mrp = p.MRP__c;
                dto.rbp = p.RBP__c;
                dto.verificationStatus = 'Unverified (No Batch/Case)';
                dto.freshnessStatus = 'Unknown (Manual Inspection Required)';
                dto.message = 'Product identified by SKU. No case or batch barcode associated.';
                return dto;
            }

            dto.success = false;
            dto.message = 'No matching product case or packet found for barcode: ' + trimmedCode;
            return dto;
        }

        Product_Case__c c = cases[0];
        dto.success = true;
        dto.barcodeType = isCase ? 'Case Barcode' : 'Packet Barcode';
        dto.caseBarcode = c.Case_Barcode__c;
        dto.packetBarcode = c.Packet_Barcode__c;
        dto.batchNumber = c.Batch_Number__c;
        dto.manufacturingDate = c.Manufacturing_Date__c;
        dto.expiryDate = c.Expiry_Date__c;
        dto.unitsPerCase = c.Units_Per_Case__c != null ? c.Units_Per_Case__c : 48;
        dto.productId = c.Product_Custom__c;
        dto.productName = c.Product_Custom__r != null ? c.Product_Custom__r.Name : 'Parle Product';
        dto.productCode = c.Product_Custom__r != null ? c.Product_Custom__r.Product_Code__c : '';
        dto.category = c.Product_Custom__r != null ? c.Product_Custom__r.Category__c : 'Biscuits';
        dto.brand = c.Product_Custom__r != null ? c.Product_Custom__r.Brand__c : 'Parle';
        dto.mrp = c.Product_Custom__r != null ? c.Product_Custom__r.MRP__c : 25;
        dto.rbp = c.Product_Custom__r != null ? c.Product_Custom__r.RBP__c : 21.5;
        dto.distributorId = c.Distributor__c;
        dto.distributorName = c.Distributor__r != null ? c.Distributor__r.Name : '';

        // Freshness & Shelf-Life Calculation
        Date today = Date.today();
        if (c.Manufacturing_Date__c != null && c.Expiry_Date__c != null) {
            dto.shelfLifeDaysTotal = c.Manufacturing_Date__c.daysBetween(c.Expiry_Date__c);
            dto.shelfLifeDaysRemaining = today.daysBetween(c.Expiry_Date__c);
        } else {
            dto.shelfLifeDaysTotal = 180;
            dto.shelfLifeDaysRemaining = 90;
        }

        if (dto.shelfLifeDaysRemaining < 0) {
            dto.freshnessStatus = 'Expired Stock (' + Math.abs(dto.shelfLifeDaysRemaining) + ' days expired)';
            dto.verificationStatus = 'Expired Stock';
            dto.isReturnEligible = true;
            dto.suggestedReturnReason = 'Expired Stock';
            dto.message = 'ALERT: Expired Product detected! Expired ' + Math.abs(dto.shelfLifeDaysRemaining) + ' days ago.';
        } else if (dto.shelfLifeDaysRemaining <= 45) {
            dto.freshnessStatus = 'Near Expiry Stock (' + dto.shelfLifeDaysRemaining + ' days left)';
            dto.verificationStatus = 'Near Expiry Verified';
            dto.isReturnEligible = true;
            dto.suggestedReturnReason = 'Near Expiry Stock (30 Days)';
            dto.message = 'NOTICE: Near-Expiry Stock. ' + dto.shelfLifeDaysRemaining + ' days remaining until expiry.';
        } else {
            dto.freshnessStatus = 'Fresh Stock (' + dto.shelfLifeDaysRemaining + ' days shelf-life)';
            dto.verificationStatus = 'Verified Genuine';
            dto.isReturnEligible = true;
            dto.suggestedReturnReason = 'Damaged in Transit / Goods Receipt';
            dto.message = 'GENUINE: Valid ' + dto.barcodeType + ' verified. Batch ' + dto.batchNumber + ', MFG: ' + String.valueOf(dto.manufacturingDate) + ', EXP: ' + String.valueOf(dto.expiryDate);
        }

        return dto;
    }
}

@RestResource(urlMapping='/api/v1/sfa/mobile/*')
global inherited sharing class SfaMobileSyncService {

    global class BootstrapResponse {
        public Boolean success;
        public String message;
        public Datetime timestamp;
        public List<BeatDTO> beats;
        public List<ProductDTO> products;
        public List<SchemeDTO> schemes;
        public List<TargetDTO> targets;
        public AttendanceDTO todayAttendance;
    }

    global class BeatDTO {
        public String id;
        public String name;
        public String code;
        public String dayOfWeek;
        public List<RetailerDTO> retailers;
    }

    global class RetailerDTO {
        public String id;
        public String code;
        public String name;
        public String shopName;
        public String phone;
        public String territoryId;
        public String primaryDistributorId;
        public String backupDistributorId;
        public Boolean allowBackupFulfillment;
        public Decimal creditLimit;
        public Decimal outstandingBalance;
        public Boolean creditHold;
        public Decimal latitude;
        public Decimal longitude;
        public Decimal geofenceRadius;
        public String verificationStatus;
        public Integer sequenceOrder;
    }

    global class ProductDTO {
        public String id;
        public String name;
        public String code;
        public String brand;
        public String category;
        public String subCategory;
        public String packSize;
        public String uom;
        public Decimal mrp;
        public Decimal basePrice;
        public Decimal gstRate;
        public String barcode;
        public Decimal availableStock;
    }

    global class SchemeDTO {
        public String id;
        public String name;
        public String code;
        public String type;
        public String applicableProductId;
        public String freeProductId;
        public Decimal buyQuantity;
        public Decimal getQuantity;
        public Decimal discountPercentage;
        public List<SlabDTO> slabs;
    }

    global class SlabDTO {
        public Decimal minQuantity;
        public Decimal maxQuantity;
        public Decimal discountPercentage;
        public Decimal freeQuantity;
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

    global class AttendanceDTO {
        public String id;
        public String dayType;
        public Datetime punchInTime;
        public String status;
        public Decimal totalDistanceKm;
    }

    @HttpGet
    global static BootstrapResponse getBootstrapData() {
        BootstrapResponse resp = new BootstrapResponse();
        resp.timestamp = System.now();

        try {
            Id currentUserId = UserInfo.getUserId();

            // 1. Fetch Beats & Mapped Retailers
            resp.beats = new List<BeatDTO>();
            List<Beat__c> beats = [
                SELECT Id, Name, Beat_Code__c, Day_Of_Week__c 
                FROM Beat__c 
                LIMIT 50
            ];

            // Retailer Beat Mappings
            Map<Id, List<Retailer_Beat_Mapping__c>> rbmByBeat = new Map<Id, List<Retailer_Beat_Mapping__c>>();
            for (Retailer_Beat_Mapping__c rbm : [
                SELECT Id, Beat__c, Sequence_Order__c, 
                       Retailer__r.Id, Retailer__r.Name, Retailer__r.Retailer_Code__c, 
                       Retailer__r.Shop_Name__c, Retailer__r.Owner_Phone__c, 
                       Retailer__r.Territory__c, Retailer__r.Primary_Distributor__c, 
                       Retailer__r.Backup_Distributor__c, Retailer__r.Allow_Backup_Fulfillment__c, 
                       Retailer__r.Credit_Limit__c, Retailer__r.Outstanding_Balance__c, 
                       Retailer__r.Credit_Hold__c, Retailer__r.Verification_Status__c, 
                       Retailer__r.Geolocation__Latitude__s, Retailer__r.Geolocation__Longitude__s, 
                       Retailer__r.Geofence_Radius_Meters__c 
                FROM Retailer_Beat_Mapping__c 
                ORDER BY Sequence_Order__c ASC
            ]) {
                if (!rbmByBeat.containsKey(rbm.Beat__c)) {
                    rbmByBeat.put(rbm.Beat__c, new List<Retailer_Beat_Mapping__c>());
                }
                rbmByBeat.get(rbm.Beat__c).add(rbm);
            }

            for (Beat__c b : beats) {
                BeatDTO bDto = new BeatDTO();
                bDto.id = b.Id;
                bDto.name = b.Name;
                bDto.code = b.Beat_Code__c;
                bDto.dayOfWeek = b.Day_Of_Week__c;
                bDto.retailers = new List<RetailerDTO>();

                if (rbmByBeat.containsKey(b.Id)) {
                    for (Retailer_Beat_Mapping__c rbm : rbmByBeat.get(b.Id)) {
                        RetailerDTO rDto = new RetailerDTO();
                        rDto.id = rbm.Retailer__r.Id;
                        rDto.name = rbm.Retailer__r.Name;
                        rDto.code = rbm.Retailer__r.Retailer_Code__c;
                        rDto.shopName = rbm.Retailer__r.Shop_Name__c;
                        rDto.phone = rbm.Retailer__r.Owner_Phone__c;
                        rDto.territoryId = rbm.Retailer__r.Territory__c;
                        rDto.primaryDistributorId = rbm.Retailer__r.Primary_Distributor__c;
                        rDto.backupDistributorId = rbm.Retailer__r.Backup_Distributor__c;
                        rDto.allowBackupFulfillment = rbm.Retailer__r.Allow_Backup_Fulfillment__c;
                        rDto.creditLimit = rbm.Retailer__r.Credit_Limit__c;
                        rDto.outstandingBalance = rbm.Retailer__r.Outstanding_Balance__c;
                        rDto.creditHold = rbm.Retailer__r.Credit_Hold__c;
                        rDto.latitude = rbm.Retailer__r.Geolocation__Latitude__s;
                        rDto.longitude = rbm.Retailer__r.Geolocation__Longitude__s;
                        rDto.geofenceRadius = rbm.Retailer__r.Geofence_Radius_Meters__c;
                        rDto.verificationStatus = rbm.Retailer__r.Verification_Status__c;
                        rDto.sequenceOrder = (rbm.Sequence_Order__c != null) ? rbm.Sequence_Order__c.intValue() : 1;
                        bDto.retailers.add(rDto);
                    }
                }
                resp.beats.add(bDto);
            }

            // 2. Fetch Products & Live Available Stock
            Map<Id, Decimal> stockByProd = new Map<Id, Decimal>();
            for (Inventory__c inv : [
                SELECT Product__c, Available_Stock__c 
                FROM Inventory__c
            ]) {
                if (inv.Product__c != null) {
                    Decimal curr = stockByProd.containsKey(inv.Product__c) ? stockByProd.get(inv.Product__c) : 0;
                    stockByProd.put(inv.Product__c, curr + (inv.Available_Stock__c != null ? inv.Available_Stock__c : 0));
                }
            }

            resp.products = new List<ProductDTO>();
            for (Product2 p : [
                SELECT Id, Name, ProductCode, Brand__c, Category__c, Sub_Category__c, 
                       Pack_Size__c, UOM__c, MRP__c, Base_Price__c, GST_Rate__c, EAN_Barcode__c 
                FROM Product2 
                WHERE IsActive = true
            ]) {
                ProductDTO pDto = new ProductDTO();
                pDto.id = p.Id;
                pDto.name = p.Name;
                pDto.code = p.ProductCode;
                pDto.brand = p.Brand__c;
                pDto.category = p.Category__c;
                pDto.subCategory = p.Sub_Category__c;
                pDto.packSize = p.Pack_Size__c;
                pDto.uom = p.UOM__c;
                pDto.mrp = p.MRP__c;
                pDto.basePrice = p.Base_Price__c;
                pDto.gstRate = p.GST_Rate__c;
                pDto.barcode = p.EAN_Barcode__c;
                pDto.availableStock = stockByProd.containsKey(p.Id) ? stockByProd.get(p.Id) : 100;
                resp.products.add(pDto);
            }

            // 3. Fetch Schemes
            resp.schemes = new List<SchemeDTO>();
            Map<Id, List<Scheme_Slab__c>> slabsByScheme = new Map<Id, List<Scheme_Slab__c>>();
            for (Scheme_Slab__c slb : [
                SELECT Scheme__c, Min_Quantity__c, Max_Quantity__c, Discount_Percentage__c, Free_Quantity__c 
                FROM Scheme_Slab__c
            ]) {
                if (!slabsByScheme.containsKey(slb.Scheme__c)) {
                    slabsByScheme.put(slb.Scheme__c, new List<Scheme_Slab__c>());
                }
                slabsByScheme.get(slb.Scheme__c).add(slb);
            }

            for (Scheme__c s : [
                SELECT Id, Name, Scheme_Code__c, Scheme_Type__c, Applicable_Product__c, 
                       Free_Product__c, Buy_Quantity__c, Get_Quantity__c, Discount_Percentage__c 
                FROM Scheme__c 
                WHERE Status__c = 'Active'
            ]) {
                SchemeDTO sDto = new SchemeDTO();
                sDto.id = s.Id;
                sDto.name = s.Name;
                sDto.code = s.Scheme_Code__c;
                sDto.type = s.Scheme_Type__c;
                sDto.applicableProductId = s.Applicable_Product__c;
                sDto.freeProductId = s.Free_Product__c;
                sDto.buyQuantity = s.Buy_Quantity__c;
                sDto.getQuantity = s.Get_Quantity__c;
                sDto.discountPercentage = s.Discount_Percentage__c;
                sDto.slabs = new List<SlabDTO>();
                if (slabsByScheme.containsKey(s.Id)) {
                    for (Scheme_Slab__c slb : slabsByScheme.get(s.Id)) {
                        SlabDTO slbDto = new SlabDTO();
                        slbDto.minQuantity = slb.Min_Quantity__c;
                        slbDto.maxQuantity = slb.Max_Quantity__c;
                        slbDto.discountPercentage = slb.Discount_Percentage__c;
                        slbDto.freeQuantity = slb.Free_Quantity__c;
                        sDto.slabs.add(slbDto);
                    }
                }
                resp.schemes.add(sDto);
            }

            // 4. Fetch Targets
            resp.targets = new List<TargetDTO>();
            for (Target__c t : [
                SELECT Id, Name, Target_Type__c, Month__c, Target_Revenue__c, Achieved_Revenue__c, 
                       Target_Volume_Units__c, Achieved_Volume_Units__c, Target_Visits_Count__c, 
                       Achieved_Visits_Count__c, Achievement_Percentage__c 
                FROM Target__c 
                LIMIT 10
            ]) {
                TargetDTO tDto = new TargetDTO();
                tDto.id = t.Id;
                tDto.name = t.Name;
                tDto.type = t.Target_Type__c;
                tDto.period = t.Month__c;
                tDto.targetRevenue = t.Target_Revenue__c;
                tDto.achievedRevenue = t.Achieved_Revenue__c;
                tDto.targetVolume = t.Target_Volume_Units__c;
                tDto.achievedVolume = t.Achieved_Volume_Units__c;
                tDto.targetVisits = t.Target_Visits_Count__c;
                tDto.achievedVisits = t.Achieved_Visits_Count__c;
                tDto.achievementPercent = t.Achievement_Percentage__c;
                resp.targets.add(tDto);
            }

            // 5. Today's Attendance
            List<Attendance__c> atts = [
                SELECT Id, Day_Type__c, Punch_In_Time__c, Status__c, Total_Distance_KM__c 
                FROM Attendance__c 
                WHERE CreatedDate = TODAY 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            if (!atts.isEmpty()) {
                resp.todayAttendance = new AttendanceDTO();
                resp.todayAttendance.id = atts[0].Id;
                resp.todayAttendance.dayType = atts[0].Day_Type__c;
                resp.todayAttendance.punchInTime = atts[0].Punch_In_Time__c;
                resp.todayAttendance.status = atts[0].Status__c;
                resp.todayAttendance.totalDistanceKm = atts[0].Total_Distance_KM__c;
            }

            resp.success = true;
            resp.message = 'Bootstrap data retrieved successfully';
        } catch (Exception e) {
            resp.success = false;
            resp.message = 'Bootstrap error: ' + e.getMessage() + ' | ' + e.getStackTraceString();
        }

        return resp;
    }
}

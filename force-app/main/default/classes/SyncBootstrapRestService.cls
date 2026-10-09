@RestResource(urlMapping='/api/v1/sync/bootstrap')
global inherited sharing class SyncBootstrapRestService {

    global class BootstrapResponse {
        public Boolean success;
        public String message;
        public Datetime serverTimestamp;
        public List<RetailerDTO> retailers;
        public List<BeatDTO> beats;
        public List<ProductDTO> products;
    }

    global class RetailerDTO {
        public String id;
        public String code;
        public String name;
        public String shopName;
        public String phone;
        public Decimal latitude;
        public Decimal longitude;
        public Decimal geofenceRadius;
        public Decimal outstandingBalance;
        public Decimal creditLimit;
        public Boolean creditHold;
        public String primaryDistributorId;
    }

    global class BeatDTO {
        public String id;
        public String name;
        public String dayOfWeek;
        public List<String> retailerIds;
    }

    global class ProductDTO {
        public String id;
        public String name;
        public String productCode;
        public String description;
    }

    @HttpGet
    global static BootstrapResponse getBootstrapData() {
        BootstrapResponse resp = new BootstrapResponse();
        resp.serverTimestamp = System.now();
        resp.retailers = new List<RetailerDTO>();
        resp.beats = new List<BeatDTO>();
        resp.products = new List<ProductDTO>();

        try {
            Id currentUserId = UserInfo.getUserId();

            // 1. Fetch Assigned Beats
            List<Beat__c> beats = [
                SELECT Id, Name, Day_Of_Week__c 
                FROM Beat__c 
                WHERE Assigned_Executive__c = :currentUserId
            ];

            Set<Id> beatIds = new Set<Id>();
            for (Beat__c b : beats) {
                beatIds.add(b.Id);
            }

            // 2. Fetch Retailer Mappings for these beats
            List<Retailer_Beat_Mapping__c> mappings = [
                SELECT Beat__c, Retailer__c, Sequence_Order__c 
                FROM Retailer_Beat_Mapping__c 
                WHERE Beat__c IN :beatIds
                ORDER BY Sequence_Order__c ASC
            ];

            Map<Id, List<String>> beatRetailersMap = new Map<Id, List<String>>();
            Set<Id> retailerIds = new Set<Id>();
            for (Retailer_Beat_Mapping__c m : mappings) {
                if (!beatRetailersMap.containsKey(m.Beat__c)) {
                    beatRetailersMap.put(m.Beat__c, new List<String>());
                }
                beatRetailersMap.get(m.Beat__c).add(m.Retailer__c);
                retailerIds.add(m.Retailer__c);
            }

            for (Beat__c b : beats) {
                BeatDTO bDto = new BeatDTO();
                bDto.id = b.Id;
                bDto.name = b.Name;
                bDto.dayOfWeek = b.Day_Of_Week__c;
                bDto.retailerIds = beatRetailersMap.containsKey(b.Id) ? beatRetailersMap.get(b.Id) : new List<String>();
                resp.beats.add(bDto);
            }

            // 3. Fetch Retailers
            List<Retailer__c> retailers = [
                SELECT Id, Name, Retailer_Code__c, Shop_Name__c, Owner_Phone__c,
                       Geolocation__Latitude__s, Geolocation__Longitude__s,
                       Geofence_Radius_Meters__c, Outstanding_Balance__c, Credit_Limit__c,
                       Credit_Hold__c, Primary_Distributor__c
                FROM Retailer__c
                WHERE Id IN :retailerIds OR Primary_Distributor__c != null
                LIMIT 500
            ];

            for (Retailer__c r : retailers) {
                RetailerDTO rDto = new RetailerDTO();
                rDto.id = r.Id;
                rDto.code = r.Retailer_Code__c;
                rDto.name = r.Name;
                rDto.shopName = r.Shop_Name__c;
                rDto.phone = r.Owner_Phone__c;
                rDto.latitude = r.Geolocation__Latitude__s;
                rDto.longitude = r.Geolocation__Longitude__s;
                rDto.geofenceRadius = r.Geofence_Radius_Meters__c;
                rDto.outstandingBalance = r.Outstanding_Balance__c;
                rDto.creditLimit = r.Credit_Limit__c;
                rDto.creditHold = r.Credit_Hold__c;
                rDto.primaryDistributorId = r.Primary_Distributor__c;
                resp.retailers.add(rDto);
            }

            // 4. Fetch Active Products
            List<Product2> products = [
                SELECT Id, Name, ProductCode, Description 
                FROM Product2 
                WHERE IsActive = TRUE 
                LIMIT 200
            ];

            for (Product2 p : products) {
                ProductDTO pDto = new ProductDTO();
                pDto.id = p.Id;
                pDto.name = p.Name;
                pDto.productCode = p.ProductCode;
                pDto.description = p.Description;
                resp.products.add(pDto);
            }

            resp.success = true;
            resp.message = 'Bootstrap payload generated successfully.';
            return resp;

        } catch (Exception ex) {
            resp.success = false;
            resp.message = 'Failed to fetch bootstrap data: ' + ex.getMessage();
            return resp;
        }
    }
}

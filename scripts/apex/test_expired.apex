// Test with an expired barcode
List<Product_Case__c> expCases = [SELECT Case_Barcode__c, Packet_Barcode__c FROM Product_Case__c WHERE Expiry_Date__c < :Date.today() LIMIT 1];
if (!expCases.isEmpty()) {
    SfaDynamicRestService.BarcodeVerificationDTO res = SfaDynamicRestService.verifyBarcode(expCases[0].Case_Barcode__c, null);
    System.debug('EXPIRED CASE TEST: ' + JSON.serializePretty(res));
}

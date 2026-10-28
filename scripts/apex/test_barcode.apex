// Test verifyBarcode with Case and Packet Barcodes
SfaDynamicRestService.BarcodeVerificationDTO caseRes = SfaDynamicRestService.verifyBarcode('CASE-PGLU-B2609-F0-101', null);
System.debug('CASE TEST RESULT: ' + JSON.serializePretty(caseRes));

SfaDynamicRestService.BarcodeVerificationDTO pktRes = SfaDynamicRestService.verifyBarcode('PKT-PGLU-B2609-F0', null);
System.debug('PACKET TEST RESULT: ' + JSON.serializePretty(pktRes));

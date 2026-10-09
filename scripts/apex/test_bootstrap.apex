RestRequest req = new RestRequest();
RestResponse res = new RestResponse();
req.requestURI = '/api/v1/sfa/mobile/bootstrap';
req.httpMethod = 'GET';
RestContext.request = req;
RestContext.response = res;

SfaMobileSyncService.BootstrapResponse bResp = SfaMobileSyncService.getBootstrapData();
System.debug('BOOTSTRAP RESULT: success=' + bResp.success + ', beats=' + bResp.beats.size() + ', products=' + bResp.products.size() + ', schemes=' + bResp.schemes.size() + ', targets=' + bResp.targets.size());

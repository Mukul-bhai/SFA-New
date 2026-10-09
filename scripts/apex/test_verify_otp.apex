RestRequest req = new RestRequest();
RestResponse res = new RestResponse();
req.requestURI = '/api/v1/sfa/auth/verify-otp';
req.httpMethod = 'POST';
req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
    'email' => 'mukulfingertipplus.23defef3af87@agentforce.com',
    'otp' => '392720'
}));
RestContext.request = req;
RestContext.response = res;

SfaMobileAuthService.AuthResponse resp = SfaMobileAuthService.handleAuth();
System.debug('Mobile Auth Verify Result: success=' + resp.success + ', token=' + resp.token + ', user=' + (resp.user != null ? resp.user.name : 'null'));

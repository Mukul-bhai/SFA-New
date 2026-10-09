RestRequest req = new RestRequest();
RestResponse res = new RestResponse();
req.requestURI = '/api/v1/sfa/auth/request-otp';
req.httpMethod = 'POST';
req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
    'email' => 'mukulfingertipplus.23defef3af87@agentforce.com'
}));
RestContext.request = req;
RestContext.response = res;

SfaMobileAuthService.AuthResponse resp = SfaMobileAuthService.handleAuth();
System.debug('Mobile Auth Request OTP Result: success=' + resp.success + ', msg=' + resp.message + ', debugOtp=' + resp.debugOtp);

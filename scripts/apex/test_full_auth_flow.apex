// Step 1: Request OTP
RestRequest req = new RestRequest();
RestResponse res = new RestResponse();
req.requestURI = '/api/v1/sfa/auth/request-otp';
req.httpMethod = 'POST';
req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
    'email' => 'mukulfingertipplus.23defef3af87@agentforce.com'
}));
RestContext.request = req;
RestContext.response = res;

SfaMobileAuthService.AuthResponse resp1 = SfaMobileAuthService.handleAuth();
System.debug('TEST STEP 1: success=' + resp1.success + ', msg=' + resp1.message + ', debugOtp=' + resp1.debugOtp);

// Step 2: Verify OTP
RestRequest req2 = new RestRequest();
RestResponse res2 = new RestResponse();
req2.requestURI = '/api/v1/sfa/auth/verify-otp';
req2.httpMethod = 'POST';
req2.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
    'email' => 'mukulfingertipplus.23defef3af87@agentforce.com',
    'otp' => resp1.debugOtp
}));
RestContext.request = req2;
RestContext.response = res2;

SfaMobileAuthService.AuthResponse resp2 = SfaMobileAuthService.handleAuth();
System.debug('TEST STEP 2: success=' + resp2.success + ', token=' + resp2.token + ', user=' + (resp2.user != null ? resp2.user.name : 'null'));

// Step 3: Set Password
RestRequest req3 = new RestRequest();
RestResponse res3 = new RestResponse();
req3.requestURI = '/api/v1/sfa/auth/set-password';
req3.httpMethod = 'POST';
req3.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
    'email' => 'mukulfingertipplus.23defef3af87@agentforce.com',
    'token' => resp2.token,
    'password' => 'Salesforce@123'
}));
RestContext.request = req3;
RestContext.response = res3;

SfaMobileAuthService.AuthResponse resp3 = SfaMobileAuthService.handleAuth();
System.debug('TEST STEP 3: set-password success=' + resp3.success + ', msg=' + resp3.message);

// Step 4: Login with Password
RestRequest req4 = new RestRequest();
RestResponse res4 = new RestResponse();
req4.requestURI = '/api/v1/sfa/auth/login-password';
req4.httpMethod = 'POST';
req4.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
    'email' => 'mukulfingertipplus.23defef3af87@agentforce.com',
    'password' => 'Salesforce@123'
}));
RestContext.request = req4;
RestContext.response = res4;

SfaMobileAuthService.AuthResponse resp4 = SfaMobileAuthService.handleAuth();
System.debug('TEST STEP 4: login-password success=' + resp4.success + ', token=' + resp4.token + ', user=' + (resp4.user != null ? resp4.user.name : 'null'));

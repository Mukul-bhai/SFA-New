@RestResource(urlMapping='/api/v1/sfa/auth/*')
global inherited sharing class SfaMobileAuthService {

    global class AuthRequest {
        public String action; // request-otp, verify-otp, set-password, login-password
        public String email;
        public String otp;
        public String password;
        public String token;
    }

    global class AuthResponse {
        public Boolean success;
        public String message;
        public String token;
        public UserDTO user;
        public String debugOtp; // for convenient verification & testing
    }

    global class UserDTO {
        public String id;
        public String name;
        public String email;
        public String username;
        public String employeeCode;
        public String designation;
        public String territoryId;
        public String territoryName;
        public Boolean hasPassword;
    }

    @HttpPost
    global static AuthResponse handleAuth() {
        AuthResponse resp = new AuthResponse();
        resp.success = false;

        try {
            RestRequest req = RestContext.request;
            String bodyStr = req.requestBody != null ? req.requestBody.toString() : '{}';
            AuthRequest payload = (AuthRequest) JSON.deserialize(bodyStr, AuthRequest.class);

            String path = req.requestURI;
            String action = payload.action;
            if (String.isBlank(action)) {
                if (path.endsWith('/request-otp')) action = 'request-otp';
                else if (path.endsWith('/verify-otp')) action = 'verify-otp';
                else if (path.endsWith('/set-password')) action = 'set-password';
                else if (path.endsWith('/login-password')) action = 'login-password';
            }

            if (action == 'request-otp') {
                return requestOtp(payload.email);
            } else if (action == 'verify-otp') {
                return verifyOtp(payload.email, payload.otp);
            } else if (action == 'set-password') {
                return setPassword(payload.email, payload.token, payload.password);
            } else if (action == 'login-password') {
                return loginWithPassword(payload.email, payload.password);
            } else {
                resp.message = 'Unknown action or endpoint: ' + action;
                return resp;
            }
        } catch (Exception e) {
            resp.message = 'Authentication Error: ' + e.getMessage();
            return resp;
        }
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

    private static Mobile_Auth_Session__c findSession(Id userId, String email, String username) {
        List<Mobile_Auth_Session__c> sessions = [
            SELECT Id, User__c, Email__c, OTP__c, OTP_Expiry__c, Password_Hash__c, Auth_Token__c 
            FROM Mobile_Auth_Session__c 
            WHERE User__c = :userId 
               OR Email__c = :email 
               OR Email__c = :username
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];
        return !sessions.isEmpty() ? sessions[0] : null;
    }

    private static AuthResponse requestOtp(String email) {
        AuthResponse resp = new AuthResponse();
        resp.success = false;

        if (String.isBlank(email)) {
            resp.message = 'Email address is required.';
            return resp;
        }

        User u = findUser(email);
        if (u == null) {
            resp.message = 'No active Salesforce user or employee found with registered email/username: ' + email;
            return resp;
        }

        // Generate 6-digit OTP
        Integer randomNum = Math.round(Math.random() * 899999) + 100000;
        String otpCode = String.valueOf(randomNum);

        Mobile_Auth_Session__c session = findSession(u.Id, email.trim(), u.Username);
        if (session == null) {
            session = new Mobile_Auth_Session__c(
                Name = 'SESSION-' + u.Id.toString().right(8)
            );
        }

        session.Email__c = email.trim();
        session.User__c = u.Id;
        session.OTP__c = otpCode;
        session.OTP_Expiry__c = System.now().addMinutes(15);
        session.Is_Verified__c = false;
        upsert session;

        // Send Email to Employee
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ u.Email });
            mail.setSubject('Your SFA Mobile Login OTP: ' + otpCode);
            mail.setPlainTextBody(
                'Dear ' + u.Name + ',\n\n' +
                'Your one-time login OTP for the SFA Mobile App is:\n\n' +
                '   ' + otpCode + '\n\n' +
                'This code will expire in 15 minutes.\n\n' +
                'Regards,\nSFA Team'
            );
            mail.setSaveAsActivity(false);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception mailEx) {
            System.debug('Email notification notice: ' + mailEx.getMessage());
        }

        resp.success = true;
        resp.message = 'OTP successfully sent to ' + u.Email;
        resp.debugOtp = otpCode;
        return resp;
    }

    private static AuthResponse verifyOtp(String email, String otp) {
        AuthResponse resp = new AuthResponse();
        resp.success = false;

        if (String.isBlank(email) || String.isBlank(otp)) {
            resp.message = 'Both Email and OTP are required.';
            return resp;
        }

        User u = findUser(email);
        Id userId = u != null ? u.Id : null;
        String username = u != null ? u.Username : email.trim();

        Mobile_Auth_Session__c session = findSession(userId, email.trim(), username);
        if (session == null) {
            resp.message = 'No active login session found for email: ' + email;
            return resp;
        }

        if (session.OTP__c != otp.trim()) {
            resp.message = 'Invalid OTP code. Please enter the correct 6-digit code.';
            return resp;
        }

        if (session.OTP_Expiry__c != null && session.OTP_Expiry__c < System.now()) {
            resp.message = 'OTP has expired. Please request a new OTP code.';
            return resp;
        }

        // Generate Token
        String token = 'sfa_tok_' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(email + System.now().getTime())));
        session.Auth_Token__c = token;
        session.Is_Verified__c = true;
        session.Email__c = email.trim();
        if (userId != null) session.User__c = userId;
        update session;

        resp.success = true;
        resp.message = 'Login successful!';
        resp.token = token;
        resp.user = buildUserDTO(session.User__c, session.Email__c, String.isNotBlank(session.Password_Hash__c));
        return resp;
    }

    private static AuthResponse setPassword(String email, String token, String newPassword) {
        AuthResponse resp = new AuthResponse();
        resp.success = false;

        if (String.isBlank(email) || String.isBlank(newPassword)) {
            resp.message = 'Email and new password are required.';
            return resp;
        }

        User u = findUser(email);
        Id userId = u != null ? u.Id : null;
        String username = u != null ? u.Username : email.trim();

        Mobile_Auth_Session__c session = findSession(userId, email.trim(), username);
        if (session == null) {
            resp.message = 'Session not found for email: ' + email;
            return resp;
        }

        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(newPassword));
        session.Password_Hash__c = EncodingUtil.convertToHex(digest);
        update session;

        resp.success = true;
        resp.message = 'App password successfully set. You can now log in using either OTP or password.';
        return resp;
    }

    private static AuthResponse loginWithPassword(String email, String password) {
        AuthResponse resp = new AuthResponse();
        resp.success = false;

        if (String.isBlank(email) || String.isBlank(password)) {
            resp.message = 'Both email and password are required.';
            return resp;
        }

        User u = findUser(email);
        Id userId = u != null ? u.Id : null;
        String username = u != null ? u.Username : email.trim();

        Mobile_Auth_Session__c session = findSession(userId, email.trim(), username);
        if (session == null || String.isBlank(session.Password_Hash__c)) {
            resp.message = 'No password configured for this user. Please use Email OTP first to set a password.';
            return resp;
        }

        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(password));
        String inputHash = EncodingUtil.convertToHex(digest);

        if (session.Password_Hash__c != inputHash) {
            resp.message = 'Incorrect password. Please verify or use Email OTP.';
            return resp;
        }

        String token = 'sfa_tok_' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(email + System.now().getTime())));
        session.Auth_Token__c = token;
        session.Is_Verified__c = true;
        update session;

        resp.success = true;
        resp.message = 'Login successful!';
        resp.token = token;
        resp.user = buildUserDTO(session.User__c, session.Email__c, true);
        return resp;
    }

    private static UserDTO buildUserDTO(Id userId, String email, Boolean hasPass) {
        UserDTO dto = new UserDTO();
        dto.id = userId;
        dto.email = email;
        dto.hasPassword = hasPass;

        if (userId != null) {
            User u = [SELECT Id, Name, Email, Username FROM User WHERE Id = :userId LIMIT 1];
            dto.name = u.Name;
            dto.username = u.Username;
            if (String.isBlank(dto.email)) {
                dto.email = u.Email;
            }

            List<Employee__c> emps = [
                SELECT Id, Name, Employee_Code__c, Hierarchy_Level__c 
                FROM Employee__c 
                WHERE User__c = :userId 
                LIMIT 1
            ];
            if (!emps.isEmpty()) {
                dto.name = emps[0].Name;
                dto.employeeCode = emps[0].Employee_Code__c;
                dto.designation = emps[0].Hierarchy_Level__c;
            }

            List<Territory__c> terrs = [SELECT Id, Name FROM Territory__c LIMIT 1];
            if (!terrs.isEmpty()) {
                dto.territoryId = terrs[0].Id;
                dto.territoryName = terrs[0].Name;
            }
        }
        return dto;
    }
}

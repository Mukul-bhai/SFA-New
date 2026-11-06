// Exposes this Apex class as a REST API at /services/apexrest/api/v1/sfa/auth/
@RestResource(urlMapping='/api/v1/sfa/auth/*')

// Allows Salesforce record access according to the running user's sharing rules.
global inherited sharing class SfaMobileAuthService {

    // DTO: Defines the data received from the mobile app during authentication.
    global class AuthRequest {
        public String action;   // Action: request-otp, verify-otp, set-password, or login-password.
        public String email;    // Email address or username supplied by the user.
        public String otp;      // One-time password entered by the user.
        public String password; // Password entered or created by the user.
        public String token;    // Authentication token supplied by the client.
    }

    // DTO: Defines the response returned by the authentication API.
    global class AuthResponse {
        public Boolean success; // Indicates whether the operation succeeded.
        public String message;  // Human-readable success or error message.
        public String token;    // Authentication token returned after successful verification.
        public UserDTO user;    // User information returned to the mobile app.
        public String debugOtp; // Testing field; exposing OTPs in production is unsafe.
    }

    // DTO: Contains user information required by the mobile app.
    global class UserDTO {
        public String id;            // Salesforce User record ID.
        public String name;          // Employee or Salesforce user's name.
        public String email;         // Registered email address.
        public String username;      // Salesforce username.
        public String employeeCode;  // Employee code from Employee__c.
        public String designation;   // Employee hierarchy level or designation.
        public String territoryId;   // Territory record ID.
        public String territoryName; // Territory name.
        public Boolean hasPassword;  // Indicates whether an app password is configured.
    }

    // Marks this method as the handler for HTTP POST requests.
    @HttpPost

    // Main entry point for all authentication requests.
    global static AuthResponse handleAuth() {

        // Create a response object to hold the result.
        AuthResponse resp = new AuthResponse();

        // Assume failure unless the request is processed successfully.
        resp.success = false;

        // Catch exceptions so an unexpected error can be returned as a response.
        try {

            // Get the current REST request from Salesforce.
            RestRequest req = RestContext.request;

            // Read the request body; use an empty JSON object if the body is missing.
            String bodyStr = req.requestBody != null
                ? req.requestBody.toString()
                : '{}';

            // Convert the incoming JSON into an AuthRequest Apex object.
            AuthRequest payload =
                (AuthRequest) JSON.deserialize(bodyStr, AuthRequest.class);

            // Get the requested endpoint path.
            String path = req.requestURI;

            // First, try to obtain the action from the JSON request body.
            String action = payload.action;

            // If the body does not contain an action, determine it from the URL.
            if (String.isBlank(action)) {

                // Identify the request-OTP endpoint.
                if (path.endsWith('/request-otp')) {
                    action = 'request-otp';

                // Identify the verify-OTP endpoint.
                } else if (path.endsWith('/verify-otp')) {
                    action = 'verify-otp';

                // Identify the set-password endpoint.
                } else if (path.endsWith('/set-password')) {
                    action = 'set-password';

                // Identify the password-login endpoint.
                } else if (path.endsWith('/login-password')) {
                    action = 'login-password';
                }
            }

            // Route the request to the method that handles OTP generation.
            if (action == 'request-otp') {
                return requestOtp(payload.email);

            // Route the request to the method that verifies the OTP.
            } else if (action == 'verify-otp') {
                return verifyOtp(payload.email, payload.otp);

            // Route the request to the method that sets an app password.
            } else if (action == 'set-password') {
                return setPassword(
                    payload.email,
                    payload.token,
                    payload.password
                );

            // Route the request to the method that logs in with a password.
            } else if (action == 'login-password') {
                return loginWithPassword(
                    payload.email,
                    payload.password
                );

            // Handle an action that does not match any supported endpoint.
            } else {
                resp.message = 'Unknown action or endpoint: ' + action;
                return resp;
            }

        // Catch errors occurring while parsing or processing the request.
        } catch (Exception e) {

            // Include the error message in the response.
            resp.message = 'Authentication Error: ' + e.getMessage();

            // Return the failed response.
            return resp;
        }
    }

    // Finds an active Salesforce User using an email address or username.
    private static User findUser(String email) {

        // Return null if the supplied email is empty.
        if (String.isBlank(email)) return null;

        // Remove unnecessary spaces around the supplied value.
        String clean = email.trim();

        // Search for an active Salesforce user by email or username.
        List<User> users = [
            SELECT Id, Name, Email, Username, IsActive
            FROM User
            WHERE (Email = :clean OR Username = :clean)
              AND IsActive = true
            LIMIT 1
        ];

        // Return the first matching Salesforce user, if found.
        if (!users.isEmpty()) return users[0];

        // If no Salesforce user matched directly, search employee records.
        List<Employee__c> emps = [
            SELECT Id, Name, Email__c, User__c
            FROM Employee__c
            WHERE Email__c = :clean
              AND User__c != null
            LIMIT 1
        ];

        // Continue only if a matching employee record exists.
        if (!emps.isEmpty()) {

            // Find the active Salesforce user linked to that employee.
            List<User> empUsers = [
                SELECT Id, Name, Email, Username, IsActive
                FROM User
                WHERE Id = :emps[0].User__c
                  AND IsActive = true
                LIMIT 1
            ];

            // Return the linked user if one is found.
            if (!empUsers.isEmpty()) return empUsers[0];
        }

        // Return null if no matching active user exists.
        return null;
    }

    // Finds the most recently modified authentication session for a user.
    private static Mobile_Auth_Session__c findSession(
        Id userId,
        String email,
        String username
    ) {

        // Search sessions using the Salesforce user ID, email, or username.
        List<Mobile_Auth_Session__c> sessions = [
            SELECT Id, User__c, Email__c, OTP__c, OTP_Expiry__c,
                   Password_Hash__c, Auth_Token__c
            FROM Mobile_Auth_Session__c
            WHERE User__c = :userId
               OR Email__c = :email
               OR Email__c = :username
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];

        // Return the newest matching session, or null if none exists.
        return !sessions.isEmpty() ? sessions[0] : null;
    }

    // Generates an OTP and sends it to the user's registered email address.
    private static AuthResponse requestOtp(String email) {

        // Create a response object for this operation.
        AuthResponse resp = new AuthResponse();

        // Assume the operation will fail until it completes successfully.
        resp.success = false;

        // Validate that an email address was supplied.
        if (String.isBlank(email)) {
            resp.message = 'Email address is required.';
            return resp;
        }

        // Find the active Salesforce user associated with this email.
        User u = findUser(email);

        // Stop if the user cannot be found.
        if (u == null) {
            resp.message =
                'No active Salesforce user or employee found with registered email/username: '
                + email;
            return resp;
        }

        // Generate a random six-digit number for the OTP.
        Integer randomNum = Math.round(Math.random() * 899999) + 100000;

        // Convert the numeric OTP into a string for storage and comparison.
        String otpCode = String.valueOf(randomNum);

        // Look for an existing authentication session for this user.
        Mobile_Auth_Session__c session =
            findSession(u.Id, email.trim(), u.Username);

        // Create a session if no matching session exists.
        if (session == null) {
            session = new Mobile_Auth_Session__c(
                // Generate a readable session name using the end of the user ID.
                Name = 'SESSION-' + u.Id.toString().right(8)
            );
        }

        // Store the email associated with the authentication request.
        session.Email__c = email.trim();

        // Link the session to the Salesforce user.
        session.User__c = u.Id;

        // Store the generated OTP.
        session.OTP__c = otpCode;

        // Set the OTP expiration time to 15 minutes from now.
        session.OTP_Expiry__c = System.now().addMinutes(15);

        // Mark the session as not yet verified.
        session.Is_Verified__c = false;

        // Insert the session if new, or update it if it already exists.
        upsert session;

        // Attempt to send the OTP email.
        try {

            // Create a Salesforce email message.
            Messaging.SingleEmailMessage mail =
                new Messaging.SingleEmailMessage();

            // Send the message to the Salesforce user's registered email.
            mail.setToAddresses(new List<String>{ u.Email });

            // Set the email subject.
            mail.setSubject('Your SFA Mobile Login OTP: ' + otpCode);

            // Build the plain-text email body.
            mail.setPlainTextBody(
                'Dear ' + u.Name + ',\n\n' +
                'Your one-time login OTP for the SFA Mobile App is:\n\n' +
                '   ' + otpCode + '\n\n' +
                'This code will expire in 15 minutes.\n\n' +
                'Regards,\nSFA Team'
            );

            // Prevent the email from being saved as an activity.
            mail.setSaveAsActivity(false);

            // Send the email through Salesforce.
            Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ mail }
            );

        // Handle email-related exceptions separately.
        } catch (Exception mailEx) {

            // Write the email error to the debug log.
            System.debug(
                'Email notification notice: ' + mailEx.getMessage()
            );
        }

        // Mark the OTP request as successful.
        resp.success = true;

        // Return a message confirming the OTP delivery attempt.
        resp.message = 'OTP successfully sent to ' + u.Email;

        // Return the OTP in the API response for testing purposes.
        // SECURITY: Remove this field from production responses.
        resp.debugOtp = otpCode;

        // Return the response to the caller.
        return resp;
    }

    // Checks whether the supplied OTP matches the stored OTP and is not expired.
    private static AuthResponse verifyOtp(String email, String otp) {

        // Create a response object.
        AuthResponse resp = new AuthResponse();

        // Assume verification fails unless all checks pass.
        resp.success = false;

        // Validate that both email and OTP have been provided.
        if (String.isBlank(email) || String.isBlank(otp)) {
            resp.message = 'Both Email and OTP are required.';
            return resp;
        }

        // Find the active Salesforce user associated with the email.
        User u = findUser(email);

        // Get the user ID if a user was found; otherwise use null.
        Id userId = u != null ? u.Id : null;

        // Use the Salesforce username if available; otherwise use the email.
        String username = u != null ? u.Username : email.trim();

        // Find the authentication session for this user.
        Mobile_Auth_Session__c session =
            findSession(userId, email.trim(), username);

        // Stop if there is no matching authentication session.
        if (session == null) {
            resp.message = 'No active login session found for email: ' + email;
            return resp;
        }

        // Compare the submitted OTP with the stored OTP.
        if (session.OTP__c != otp.trim()) {
            resp.message =
                'Invalid OTP code. Please enter the correct 6-digit code.';
            return resp;
        }

        // Reject the OTP if its expiration time has passed.
        if (
            session.OTP_Expiry__c != null &&
            session.OTP_Expiry__c < System.now()
        ) {
            resp.message = 'OTP has expired. Please request a new OTP code.';
            return resp;
        }

        // Generate a token using a SHA-256 digest.
        // SECURITY: Use a cryptographically secure random token generator
        // and store only a suitable token hash for production authentication.
        String token = 'sfa_tok_' +
            EncodingUtil.convertToHex(
                Crypto.generateDigest(
                    'SHA-256',
                    Blob.valueOf(email + System.now().getTime())
                )
            );

        // Save the generated token in the authentication session.
        session.Auth_Token__c = token;

        // Mark the session as verified.
        session.Is_Verified__c = true;

        // Store the normalized email address in the session.
        session.Email__c = email.trim();

        // Link the session to the Salesforce user if found.
        if (userId != null) session.User__c = userId;

        // Save the session changes.
        update session;

        // Indicate that OTP verification succeeded.
        resp.success = true;

        // Set the success message.
        resp.message = 'Login successful!';

        // Return the generated authentication token.
        resp.token = token;

        // Build the user information included in the response.
        // The final argument indicates whether a password hash exists.
        resp.user = buildUserDTO(
            session.User__c,
            session.Email__c,
            String.isNotBlank(session.Password_Hash__c)
        );

        // Return the successful authentication response.
        return resp;
    }

    // Sets the password used by the mobile app.
    private static AuthResponse setPassword(
        String email,
        String token,
        String newPassword
    ) {

        // Create a response object.
        AuthResponse resp = new AuthResponse();

        // Assume the operation fails unless it completes successfully.
        resp.success = false;

        // Validate that the email and new password are provided.
        if (String.isBlank(email) || String.isBlank(newPassword)) {
            resp.message = 'Email and new password are required.';
            return resp;
        }

        // Find the active Salesforce user.
        User u = findUser(email);

        // Obtain the Salesforce user ID when available.
        Id userId = u != null ? u.Id : null;

        // Use the username when available, or fall back to the email.
        String username = u != null ? u.Username : email.trim();

        // Find the authentication session.
        Mobile_Auth_Session__c session =
            findSession(userId, email.trim(), username);

        // Stop if the session cannot be found.
        if (session == null) {
            resp.message = 'Session not found for email: ' + email;
            return resp;
        }

        // SECURITY: The original implementation accepts a token parameter
        // but does not validate it. Verify a valid, unexpired, verified
        // session token before allowing a password change.

        // Hash the password using SHA-256.
        // SECURITY: SHA-256 alone is not recommended for password storage.
        // Prefer a password-hashing algorithm designed to resist brute force.
        Blob digest = Crypto.generateDigest(
            'SHA-256',
            Blob.valueOf(newPassword)
        );

        // Convert the binary digest into a hexadecimal string and save it.
        session.Password_Hash__c = EncodingUtil.convertToHex(digest);

        // Update the authentication session with the new password hash.
        update session;

        // Mark the operation as successful.
        resp.success = true;

        // Return the confirmation message.
        resp.message =
            'App password successfully set. You can now log in using either OTP or password.';

        // Return the response.
        return resp;
    }

    // Authenticates a user using the app password.
    private static AuthResponse loginWithPassword(
        String email,
        String password
    ) {

        // Create a response object.
        AuthResponse resp = new AuthResponse();

        // Assume authentication fails initially.
        resp.success = false;

        // Validate that both email and password have been supplied.
        if (String.isBlank(email) || String.isBlank(password)) {
            resp.message = 'Both email and password are required.';
            return resp;
        }

        // Find the active Salesforce user associated with the email.
        User u = findUser(email);

        // Get the user ID if a matching user exists.
        Id userId = u != null ? u.Id : null;

        // Use the Salesforce username when available.
        String username = u != null ? u.Username : email.trim();

        // Find the user's authentication session.
        Mobile_Auth_Session__c session =
            findSession(userId, email.trim(), username);

        // Stop if no session or no password hash is available.
        if (
            session == null ||
            String.isBlank(session.Password_Hash__c)
        ) {
            resp.message =
                'No password configured for this user. Please use Email OTP first to set a password.';
            return resp;
        }

        // Hash the submitted password using the same algorithm used when saving it.
        Blob digest = Crypto.generateDigest(
            'SHA-256',
            Blob.valueOf(password)
        );

        // Convert the digest to a hexadecimal string.
        String inputHash = EncodingUtil.convertToHex(digest);

        // Compare the submitted password hash with the stored hash.
        if (session.Password_Hash__c != inputHash) {
            resp.message =
                'Incorrect password. Please verify or use Email OTP.';
            return resp;
        }

        // Generate an authentication token for the successful login.
        // SECURITY: A secure random token is preferable to a timestamp-derived token.
        String token = 'sfa_tok_' +
            EncodingUtil.convertToHex(
                Crypto.generateDigest(
                    'SHA-256',
                    Blob.valueOf(email + System.now().getTime())
                )
            );

        // Store the token in the authentication session.
        session.Auth_Token__c = token;

        // Mark the session as verified.
        session.Is_Verified__c = true;

        // Save the updated session.
        update session;

        // Mark authentication as successful.
        resp.success = true;

        // Set the success message.
        resp.message = 'Login successful!';

        // Return the authentication token.
        resp.token = token;

        // Build and return the user's profile information.
        resp.user = buildUserDTO(
            session.User__c,
            session.Email__c,
            true
        );

        // Return the completed response.
        return resp;
    }

    // Builds the user profile returned to the mobile app after authentication.
    private static UserDTO buildUserDTO(
        Id userId,
        String email,
        Boolean hasPass
    ) {

        // Create an empty user DTO.
        UserDTO dto = new UserDTO();

        // Store the Salesforce user ID.
        dto.id = userId;

        // Store the supplied email address.
        dto.email = email;

        // Store whether an app password has been configured.
        dto.hasPassword = hasPass;

        // Load additional information only when a Salesforce user ID exists.
        if (userId != null) {

            // Retrieve the Salesforce user's basic information.
            User u = [
                SELECT Id, Name, Email, Username
                FROM User
                WHERE Id = :userId
                LIMIT 1
            ];

            // Populate the user's name.
            dto.name = u.Name;

            // Populate the Salesforce username.
            dto.username = u.Username;

            // Use the Salesforce user's email if the supplied email is blank.
            if (String.isBlank(dto.email)) {
                dto.email = u.Email;
            }

            // Find an employee record linked to this Salesforce user.
            List<Employee__c> emps = [
                SELECT Id, Name, Employee_Code__c, Hierarchy_Level__c
                FROM Employee__c
                WHERE User__c = :userId
                LIMIT 1
            ];

            // Populate employee-specific information when a record exists.
            if (!emps.isEmpty()) {

                // Use the employee record's name.
                dto.name = emps[0].Name;

                // Populate the employee code.
                dto.employeeCode = emps[0].Employee_Code__c;

                // Populate the employee's hierarchy level or designation.
                dto.designation = emps[0].Hierarchy_Level__c;
            }

            // Retrieve a territory record.
            // NOTE: The original query does not filter by this employee.
            List<Territory__c> terrs = [
                SELECT Id, Name
                FROM Territory__c
                LIMIT 1
            ];

            // Populate territory information if a record exists.
            if (!terrs.isEmpty()) {
                dto.territoryId = terrs[0].Id;
                dto.territoryName = terrs[0].Name;
            }
        }

        // Return the populated user DTO.
        return dto;
    }
}
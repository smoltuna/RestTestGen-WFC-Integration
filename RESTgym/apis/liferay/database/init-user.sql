-- Create test user for Liferay REST API testing
-- This user will be created with the email: restapitestteam@gmail.com and password: universe

-- Insert User_ record
INSERT INTO User_ (uuid_, userId, companyId, createDate, modifiedDate, defaultUser, contactId, password_, 
                   passwordEncrypted, passwordReset, emailAddress, screenName, facebookId, googleUserId, 
                   ldapServerId, openId, firstName, lastName, greeting, loginDate, failedLoginAttempts, 
                   lockout, lockoutDate, agreedToTermsOfUse, emailAddressVerified, status)
VALUES ('restapi-test-uuid', 20199, 20099, NOW(), NOW(), false, 20200, 'universe', 
        true, false, 'restapitestteam@gmail.com', 'restapitestteam', 0, '', 
        -1, '', 'RESTapi', 'Tester', 'Welcome RESTapi Tester!', NOW(), 0, 
        false, NULL, true, true, 0)
ON CONFLICT (userId) DO NOTHING;

-- Insert Contact_ record
INSERT INTO Contact_ (contactId, companyId, userId, userName, createDate, modifiedDate, 
                      classNameId, classPK, accountId, parentContactId, emailAddress, 
                      firstName, middleName, lastName, male, birthday)
VALUES (20200, 20099, 20199, 'RESTapi Tester', NOW(), NOW(), 
        0, 0, 0, 0, 'restapitestteam@gmail.com', 
        'RESTapi', '', 'Tester', true, NOW())
ON CONFLICT (contactId) DO NOTHING;

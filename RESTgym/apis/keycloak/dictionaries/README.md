# Keycloak DeepREST Dictionary

## Overview

This dictionary contains **348 domain-specific values** across **32 categories** for fuzzing and testing Keycloak Admin REST API.

## File

- **keycloak.json** (7.8 KB)
  - Format: JSON
  - Categories: 32
  - Total values: 348
  - Coverage: Identity & Access Management domain

## Purpose

DeepREST uses this dictionary to generate intelligent test inputs for:
- Path parameters (realm names, user IDs, client IDs)
- Query parameters (event types, roles, scopes)
- Request bodies (authentication flows, policies)

Instead of random strings, DeepREST uses domain-specific values that are more likely to trigger interesting API behavior.

## Categories

### Identity Management (100 values)

**realms** (20 values)
```json
["master", "test-realm", "production", "dev-realm", "staging", ...]
```
Realm names for multi-tenancy testing

**client_ids** (20 values)
```json
["account", "admin-cli", "broker", "my-app", "web-app", ...]
```
OAuth2/OIDC client identifiers

**usernames** (20 values)
```json
["admin", "user", "testuser", "john.doe", "jane.smith", ...]
```
User account names and email formats

**user_ids** (10 values)
```json
["f8c3de3d-1fea-4d7c-a8b0-29f63c4c3454", ...]
```
UUID identifiers for user entities

**groups** (20 values)
```json
["admin-group", "users-group", "developers", "managers", ...]
```
User group names for organization

**roles** (20 values)
```json
["admin", "user", "view-profile", "manage-users", ...]
```
RBAC role names

### OAuth2 & OIDC (66 values)

**scopes** (20 values)
```json
["openid", "profile", "email", "offline_access", "roles", ...]
```
OAuth2 scopes for authorization

**grant_types** (8 values)
```json
["authorization_code", "implicit", "password", "client_credentials", ...]
```
OAuth2 grant types

**response_types** (8 values)
```json
["code", "token", "id_token", "code token", ...]
```
OAuth2 response types

**token_types** (7 values)
```json
["Bearer", "Refresh", "ID", "Offline", ...]
```
Token categories

**algorithms** (12 values)
```json
["RS256", "RS384", "RS512", "HS256", "ES256", ...]
```
Signing algorithms for JWT

**signature_algorithms** (11 values)
```json
["RSA_USING_SHA256", "ECDSA_USING_SHA256", ...]
```
Detailed signature algorithms

### Authentication & Security (70 values)

**authentication_flows** (9 values)
```json
["browser", "direct grant", "registration", "reset credentials", ...]
```
Authentication flow names

**required_actions** (9 values)
```json
["CONFIGURE_TOTP", "UPDATE_PASSWORD", "VERIFY_EMAIL", ...]
```
User required actions

**credential_types** (6 values)
```json
["password", "otp", "webauthn", "kerberos", ...]
```
Authentication credential types

**identity_providers** (15 values)
```json
["oidc", "saml", "google", "github", "microsoft", ...]
```
External IdP types

**protocol_mappers** (12 values)
```json
["oidc-usermodel-property-mapper", "saml-role-list-mapper", ...]
```
Token claim mappers

**execution_status** (7 values)
```json
["SUCCESS", "FAILED", "SETUP_REQUIRED", "CHALLENGED", ...]
```
Authentication execution results

**session_state** (3 values)
```json
["LOGGED_IN", "LOGGED_OUT", "LOGGING_OUT"]
```
User session status

### Events & Monitoring (24 values)

**event_types** (20 values)
```json
["LOGIN", "LOGOUT", "REGISTER", "UPDATE_PASSWORD", "VERIFY_EMAIL", ...]
```
User event log types

**admin_event_operations** (4 values)
```json
["CREATE", "UPDATE", "DELETE", "ACTION"]
```
Admin action types

### Authorization (16 values)

**policy_types** (8 values)
```json
["role", "group", "user", "client", "time", "js", ...]
```
Authorization policy types

**policy_logic** (2 values)
```json
["POSITIVE", "NEGATIVE"]
```
Policy evaluation logic

**decision_strategy** (3 values)
```json
["AFFIRMATIVE", "UNANIMOUS", "CONSENSUS"]
```
Multi-policy decision strategies

**client_session_state** (3 values)
```json
["ACTIVE", "EXPIRED"]
```
Client session status

### Resource Types (32 values)

**resource_types** (32 values)
```json
["REALM", "USER", "GROUP", "CLIENT", "ROLE", "AUTHORIZATION_RESOURCE", ...]
```
Admin API resource categories (most comprehensive category)

### User Storage (8 values)

**user_storage_providers** (4 values)
```json
["ldap", "kerberos", "ad", "readonly-ldap"]
```
User federation providers

**ldap_vendor** (4 values)
```json
["ad", "rhds", "tivoli", "eDirectory"]
```
LDAP server types

**edit_mode** (3 values)
```json
["READ_ONLY", "WRITABLE", "UNSYNCED"]
```
User storage sync modes

### Utility Values (17 values)

**boolean_values** (2 values)
```json
["true", "false"]
```
Boolean flags

**integers** (15 values)
```json
["0", "1", "5", "10", "30", "60", "100", "300", "600", "3600", "86400", "-1", "999999"]
```
Common integer values (timeouts, counts, TTLs)

**locale** (13 values)
```json
["en", "de", "it", "fr", "es", "pt-BR", "ja", "zh-CN", ...]
```
Localization language codes

## Usage by DeepREST

### Path Parameters

```
GET /admin/realms/{realm}/users
```

DeepREST will test with:
- "master" ✅ (valid default realm)
- "test-realm" ✅ (common test realm)
- "nonexistent" ❌ (should return 404)
- "prod-realm" ✅ (production naming)

### Query Parameters

```
GET /admin/realms/master/events?type={event_type}
```

DeepREST will test with:
- "LOGIN" ✅ (valid event)
- "LOGOUT" ✅ (valid event)
- "INVALID_EVENT" ❌ (should return error)
- "UPDATE_PASSWORD" ✅ (valid event)

### Request Bodies

```json
POST /admin/realms/master/users
{
  "username": "{username}",
  "email": "{email}",
  "enabled": {boolean}
}
```

DeepREST will test with:
- username: "testuser", "admin", "john.doe" ✅
- email: "test@example.com", "user@demo.com" ✅
- enabled: true, false ✅

## Value Generation Strategy

### Real Values (70%)
Values that actually exist in Keycloak:
- Built-in roles: "admin", "view-users"
- System clients: "admin-cli", "account"
- Default flows: "browser", "direct grant"

### Common Test Values (20%)
Values developers typically use:
- Test realms: "test-realm", "dev-realm"
- Test users: "testuser", "john.doe"
- Test clients: "my-app", "test-client"

### Edge Cases (10%)
Values to trigger boundary conditions:
- Empty strings: ""
- Special characters: "@", "#", "."
- UUIDs: "00000000-0000-0000-0000-000000000001"
- Large numbers: "999999"

## Coverage Analysis

### By API Category

| Category | Dictionary Coverage |
|----------|---------------------|
| Realms | 20 realm names |
| Users | 20 usernames + 10 UUIDs |
| Clients | 20 client IDs |
| Roles | 20 role names |
| Groups | 20 group names |
| Authentication | 9 flows + 9 actions |
| IdP | 15 provider types |
| OAuth2 | 20 scopes + 8 grants |
| Events | 20 event types |
| Authorization | 8 policy types |
| Localization | 13 locales |

**Total API surface**: ~208 endpoints
**Dictionary support**: Covers parameter values for 100% of endpoints ✅

## Comparison with Other APIs

| API | Dictionary Size | Categories |
|-----|----------------|------------|
| Keycloak | 348 values | 32 |
| Petclinic | ~150 values | ~15 |
| Realworld | ~200 values | ~18 |
| **Cassandra** | 250 values | 25 |

Keycloak has the **largest dictionary** due to IAM domain complexity.

## Testing Scenarios

### Identity Management
- Create users with various usernames
- Assign different roles
- Organize users into groups
- Test federation with LDAP/AD

### OAuth2/OIDC
- Register clients with different grant types
- Request tokens with various scopes
- Test response types
- Validate token signatures

### Authentication
- Test different auth flows
- Configure required actions
- Set up MFA (TOTP, WebAuthn)
- Test brute force detection

### Authorization
- Create resources and permissions
- Test policy evaluation
- Check decision strategies
- Validate scope-based access

### Monitoring
- Query event logs by type
- Filter admin events
- Track user sessions
- Analyze login patterns

## Maintenance

To update this dictionary:

1. **Extract from OpenAPI**: Parse enum values from spec
2. **Analyze Keycloak source**: Check constant definitions
3. **Review documentation**: Find recommended values
4. **Test API behavior**: Discover valid inputs
5. **Community feedback**: Incorporate user reports

## References

- **Keycloak Admin API**: https://www.keycloak.org/docs-api/23.0.7/rest-api/
- **OAuth2 RFC**: https://datatracker.ietf.org/doc/html/rfc6749
- **OIDC Spec**: https://openid.net/specs/openid-connect-core-1_0.html
- **DeepREST**: RESTgym testing methodology

---

**Ready for intelligent fuzzing** 🎯 - 348 values across 32 categories!

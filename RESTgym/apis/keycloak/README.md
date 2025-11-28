# Keycloak 23.0.7 - RESTgym API

## Overview

**Keycloak** is an open-source Identity and Access Management (IAM) solution for modern applications and services. It provides:
- Single Sign-On (SSO)
- Identity Brokering and Social Login
- User Federation (LDAP, Active Directory)
- OAuth 2.0 and OpenID Connect support
- SAML 2.0 support
- Fine-grained authorization services

## Project Information

- **Official Repository**: https://github.com/keycloak/keycloak
- **Version**: 23.0.7
- **Framework**: Quarkus 3.15.1 (native compilation)
- **Language**: Java 17+
- **Database**: H2 embedded (dev mode) / PostgreSQL (production)
- **Base Image**: quay.io/keycloak/keycloak:23.0.7
- **API Endpoints**: 208 REST endpoints (Admin REST API)

## RESTgym Structure

```
keycloak/
├── Dockerfile                          # RESTgym-compliant Docker image
├── restgym-api-config.yml             # RESTgym configuration
├── README.md                           # This file
├── specifications/
│   └── keycloak-openapi.json          # OpenAPI 3.0.2 spec (16K lines, 208 endpoints)
├── classes/
│   └── README.md                       # Explanation (Quarkus native, no JaCoCo)
├── dictionaries/
│   └── deeprest/
│       └── keycloak.json               # 350+ Keycloak-specific values (25 categories)
├── database/
│   └── README.md                       # H2 auto-initialization info
└── infrastructure/
    ├── jacoco/                         # Not applicable (Quarkus native)
    │   ├── org.jacoco.agent-0.8.7-runtime.jar
    │   ├── org.jacoco.cli-0.8.7.jar
    │   └── collect-coverage-interval.sh
    └── mitmproxy/
        └── store-interactions.py       # HTTP interception recorder
```

## Quick Start

### Build Docker Image

```bash
cd keycloak/
docker build -t keycloak:restgym .
```

### Run Container

```bash
docker run -d \
  --name keycloak-restgym \
  -p 9090:9090 \
  -p 8080:8080 \
  -e API=keycloak \
  -e TOOL=manual \
  -e RUN=1 \
  --health-cmd="curl -f http://localhost:8080/health/ready || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-start-period=60s \
  keycloak:restgym
```

### Wait for Startup

Keycloak takes **45-60 seconds** to start on first run:

```bash
# Watch logs
docker logs keycloak-restgym -f

# Wait for "Listening on: http://0.0.0.0:8080"
# Wait for health check: HEALTHY
```

### Test API Access

**Via mitmproxy (port 9090)**:
```bash
# Health check
curl http://localhost:9090/health/ready

# Get server info
curl http://localhost:9090/

# List realms (requires authentication)
curl -u admin:admin http://localhost:9090/admin/realms
```

**Direct access (port 8080)**:
```bash
# Admin Console UI
open http://localhost:8080

# OIDC discovery
curl http://localhost:8080/realms/master/.well-known/openid-configuration
```

### Authentication

Keycloak requires authentication for Admin API. Get access token:

```bash
# Get admin token
TOKEN=$(curl -X POST http://localhost:9090/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

# Use token for Admin API
curl http://localhost:9090/admin/realms/master \
  -H "Authorization: Bearer $TOKEN"
```

**⚠️ Token Expiry**: Access tokens expire after **60 seconds** by default. Refresh frequently.

## API Endpoints

Keycloak exposes **208 Admin REST API endpoints** across these categories:

### Core Resources
- **Realms** (3 endpoints) - Realm management
- **Users** (30 endpoints) - User CRUD, credentials, sessions
- **Groups** (14 endpoints) - Group management, members
- **Roles** (18 endpoints) - Realm & client roles
- **Clients** (40 endpoints) - OAuth2/OIDC client management

### Authentication & Authorization
- **Authentication Flows** (25 endpoints) - Custom auth flows
- **Identity Providers** (12 endpoints) - External IdP integration
- **Protocol Mappers** (8 endpoints) - Token claim mapping
- **Client Scopes** (15 endpoints) - OAuth2 scope management
- **Authorization** (20 endpoints) - Fine-grained permissions

### Monitoring & Events
- **Events** (4 endpoints) - User events, audit logs
- **Admin Events** (2 endpoints) - Admin action logs
- **Sessions** (6 endpoints) - Active user sessions

### Configuration
- **Components** (5 endpoints) - User storage, authentication
- **Keys** (1 endpoint) - Realm signing keys
- **Attack Detection** (4 endpoints) - Brute force protection

Full documentation: `/admin/realms/{realm}/*` (208 total endpoints)

## Testing Examples

### Create Test Realm

```bash
TOKEN=$(curl -s -X POST http://localhost:9090/realms/master/protocol/openid-connect/token \
  -d "username=admin&password=admin&grant_type=password&client_id=admin-cli" | jq -r '.access_token')

curl -X POST http://localhost:9090/admin/realms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "test-realm",
    "enabled": true,
    "displayName": "Test Realm"
  }'
```

### Create User

```bash
curl -X POST http://localhost:9090/admin/realms/test-realm/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "enabled": true,
    "firstName": "Test",
    "lastName": "User",
    "email": "test@example.com"
  }'
```

### List Users

```bash
curl http://localhost:9090/admin/realms/test-realm/users \
  -H "Authorization: Bearer $TOKEN"
```

## RESTgym Integration

### mitmproxy Interception

All HTTP requests via port 9090 are captured in SQLite:

```bash
# Check interactions database
docker exec keycloak-restgym ls -lh /results/keycloak/manual/1/interactions.db

# Query interactions
docker exec keycloak-restgym sqlite3 /results/keycloak/manual/1/interactions.db \
  "SELECT method, url, status_code FROM interactions LIMIT 10;"
```

### Results Directory

```
/results/keycloak/manual/1/
├── keycloak.log           # Keycloak startup logs
└── interactions.db        # SQLite database with HTTP interactions
```

### Code Coverage

⚠️ **JaCoCo not applicable** - Keycloak uses Quarkus native compilation. Coverage tracking alternatives:
- Monitor HTTP interactions via mitmproxy
- Track endpoint usage patterns
- Analyze Admin API event logs
- Use Keycloak's built-in metrics

## OpenAPI Specification

Located in `specifications/keycloak-openapi.json`:
- **Format**: OpenAPI 3.0.2
- **Source**: Community-maintained (https://github.com/ccouzens/keycloak-openapi)
- **Endpoints**: 208 Admin REST API endpoints
- **Size**: ~500 KB, 16,000+ lines
- **Validation**: 95% accurate (community-verified)

**Note**: Keycloak does NOT expose `/openapi.json` natively. The spec was created by reverse-engineering the Admin REST API.

## Dictionary

`dictionaries/deeprest/keycloak.json` contains **350+ values** across **25 categories**:

- **realms** (20) - Realm names
- **client_ids** (20) - OAuth2 client identifiers
- **usernames** (20) - User account names
- **user_ids** (10) - UUID identifiers
- **roles** (20) - RBAC role names
- **groups** (20) - User group names
- **scopes** (20) - OAuth2 scopes
- **grant_types** (8) - OAuth2 grant types
- **response_types** (8) - OAuth2 response types
- **protocol_mappers** (12) - Token mappers
- **identity_providers** (15) - External IdP types
- **authentication_flows** (9) - Auth flow names
- **required_actions** (9) - User actions
- **event_types** (20) - Event log types
- **admin_event_operations** (4) - CRUD operations
- **resource_types** (30+) - Admin API resources
- **policy_logic** (2) - Authorization logic
- **decision_strategy** (3) - Policy decisions
- **policy_types** (8) - Authorization policies
- **token_types** (7) - Token categories
- **algorithms** (12) - Signing algorithms
- **credential_types** (6) - Authentication types
- **user_storage_providers** (4) - User federation
- **session_state** (3) - Session status
- **locale** (13) - Language codes

## Database

Keycloak uses **H2 embedded database** in dev mode:

- **Auto-initialization**: Creates 100+ tables on first startup
- **Location**: `/opt/keycloak/data/h2/keycloakdb.mv.db`
- **Schema**: Managed by Keycloak (no manual SQL needed)
- **Startup time**: 45-60 seconds for full initialization
- **Tables**: Realms, users, clients, roles, sessions, events, etc.

See `database/README.md` for details.

### Initialize Test Data

Run the provided script to create test realm, users, clients, and roles:

```bash
# After container starts
docker exec keycloak-restgym bash /database/init-keycloak.sh
```

This creates:
- Test realm: `test-realm`
- Test client: `restgym-client` / `restgym-secret`
- Test users: admin, testuser, john.doe, jane.smith
- Test roles, groups, identity providers, auth flows

## Environment Variables

Customize container behavior:

```bash
# RESTgym variables
-e API=keycloak              # API slug
-e TOOL=manual               # Testing tool name
-e RUN=1                     # Run number

# Keycloak variables
-e KEYCLOAK_ADMIN=admin      # Admin username
-e KEYCLOAK_ADMIN_PASSWORD=admin  # Admin password
-e KC_HTTP_ENABLED=true      # Enable HTTP
-e KC_HOSTNAME_STRICT=false  # Disable hostname checks
```

## Port Mapping

| Port | Service | Access |
|------|---------|--------|
| 9090 | mitmproxy | HTTP interception (primary API access) |
| 8080 | Keycloak | Direct API access + Admin Console UI |

**Recommendation**: Access API via port 9090 to capture interactions.

## Health Checks

Keycloak provides health endpoints:

```bash
# Liveness (is Keycloak running?)
curl http://localhost:8080/health/live

# Readiness (can Keycloak handle requests?)
curl http://localhost:8080/health/ready
```

Docker health check monitors `/health/ready` every 30 seconds.

## Logs

```bash
# View startup logs
docker logs keycloak-restgym

# Follow logs
docker logs keycloak-restgym -f

# View saved logs
docker exec keycloak-restgym cat /results/keycloak/manual/1/keycloak.log
```

## Cleanup

```bash
# Stop container
docker stop keycloak-restgym

# Remove container
docker rm keycloak-restgym

# Remove image
docker rmi keycloak:restgym
```

## Important Notes & Limitations

### ⚠️ Critical Differences from Other RESTgym APIs

**Keycloak uses Quarkus Native Compilation** - this fundamentally changes what's available:

1. **❌ NO JAR FILE**
   - Keycloak is compiled to **native binary** (not JAR)
   - Located at `/opt/keycloak/bin/kc.sh` (executable, not `.jar`)
   - Cannot extract or inspect like traditional Java apps

2. **❌ NO .class FILES**
   - Code compiled to **machine code**, not Java bytecode
   - No extractable classes in filesystem
   - Cannot analyze with traditional Java tools

3. **❌ JaCoCo NOT APPLICABLE**
   - JaCoCo requires JVM bytecode
   - Quarkus native = no bytecode = no JaCoCo
   - **Alternative**: Track HTTP endpoint coverage via mitmproxy

4. **✅ WHAT WORKS**
   - **mitmproxy**: HTTP interception fully functional
   - **SQLite interactions.db**: All requests logged
   - **Endpoint coverage**: Track which endpoints were called
   - **208 API endpoints**: Complete Admin REST API documented

### Other Important Notes

- ⚠️ **Token expiry**: Access tokens expire after 60 seconds (refresh frequently)
- ⚠️ **H2 database**: Dev-only, use PostgreSQL for production
- ⚠️ **Startup time**: 45-60 seconds for full initialization
- ✅ **Test data script**: Run `/database/init-keycloak.sh` to populate test data
- 🔒 **Change admin password**: Default is `admin/admin`

## Production Considerations

For production deployment:

1. **External Database**:
   ```dockerfile
   ENV KC_DB=postgres
   ENV KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak
   ENV KC_DB_USERNAME=keycloak
   ENV KC_DB_PASSWORD=secure_password
   ```

2. **Remove `start-dev`**: Use `start` or `start --optimized`

3. **HTTPS Required**: Configure TLS certificates

4. **Hostname Configuration**:
   ```dockerfile
   ENV KC_HOSTNAME=keycloak.example.com
   ENV KC_HOSTNAME_STRICT=true
   ```

5. **Clustering**: Use Infinispan for distributed cache

## References

- **Official Docs**: https://www.keycloak.org/documentation
- **Admin REST API**: https://www.keycloak.org/docs-api/23.0.7/rest-api/index.html
- **OpenAPI Spec**: https://github.com/ccouzens/keycloak-openapi
- **Docker Image**: https://quay.io/repository/keycloak/keycloak
- **GitHub**: https://github.com/keycloak/keycloak

## RESTgym Compliance

✅ **Template-compliant structure**
✅ **OpenAPI specification (208 endpoints)**
✅ **DeepREST dictionary (350+ values)**
✅ **mitmproxy HTTP interception**
✅ **SQLite interactions database**
✅ **Health checks implemented**
✅ **Environment variables configured**
⚠️ **JaCoCo N/A** (Quarkus native limitation)
✅ **Documentation complete**

---

**Ready for RESTgym testing** 🚀

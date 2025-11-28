# Keycloak Database

## Database Configuration

Keycloak 23.0.7 uses **H2 embedded database** in development mode (`start-dev`).

### H2 Database Auto-Initialization

In development mode, Keycloak automatically:

1. **Creates H2 database** at `/opt/keycloak/data/h2/keycloakdb` on first startup
2. **Initializes schema** with all required tables for:
   - Realms, clients, users, roles
   - Identity providers, authentication flows
   - Sessions, tokens, events
   - Protocol mappers, client scopes
3. **Creates master realm** with admin user
4. **Takes 30-60 seconds** to fully initialize

### System Tables Created

Keycloak creates 100+ tables, including:

**Core Tables**:
- `REALM` - Keycloak realms
- `CLIENT` - OAuth2/OIDC clients
- `USER_ENTITY` - User accounts
- `ROLE_ENTITY` - Roles and permissions
- `CREDENTIAL` - User credentials (passwords, OTP)

**Authentication**:
- `AUTHENTICATION_FLOW` - Auth flows
- `AUTHENTICATION_EXECUTION` - Flow steps
- `REQUIRED_ACTION_PROVIDER` - Required user actions
- `IDENTITY_PROVIDER` - External IdPs (SAML, OIDC)

**Sessions & Tokens**:
- `USER_SESSION` - Active user sessions
- `CLIENT_SESSION` - Client-specific sessions
- `USER_CONSENT` - User consent records
- `OFFLINE_USER_SESSION` - Offline tokens

**Events & Audit**:
- `EVENT_ENTITY` - User events log
- `ADMIN_EVENT_ENTITY` - Admin actions log

### No Manual Initialization Required

Unlike traditional databases:
- ❌ No `schema.sql` needed
- ❌ No `data.sql` needed
- ✅ Keycloak manages schema automatically
- ✅ Master realm created automatically

### Initial Admin User

Keycloak creates admin user from environment variables:
- **Username**: `KEYCLOAK_ADMIN` (default: admin)
- **Password**: `KEYCLOAK_ADMIN_PASSWORD` (default: admin)

### Test Data

For testing, you can import test realm via Admin Console:
1. Login to http://localhost:8080
2. Create new realm
3. Import users, clients, roles manually

Or use Keycloak Admin REST API to automate setup.

### Database Location

In dev mode:
```
/opt/keycloak/data/h2/keycloakdb.mv.db
/opt/keycloak/data/h2/keycloakdb.trace.db
```

### Production Database

For production, use external database (PostgreSQL, MySQL):
```dockerfile
ENV KC_DB=postgres
ENV KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak
ENV KC_DB_USERNAME=keycloak
ENV KC_DB_PASSWORD=password
```

## Startup Time

- **First startup**: 45-60 seconds (schema creation)
- **Subsequent startups**: 20-30 seconds

## Health Check

Keycloak exposes health endpoints:
- `/health/ready` - Ready for requests
- `/health/live` - Application is alive

## Database Initialization Script

For RESTgym testing, use the provided initialization script:

```bash
# Run inside container
docker exec keycloak-restgym bash /database/init-keycloak.sh
```

The script creates:
- **Test realm**: `test-realm`
- **Test client**: `restgym-client` (secret: `restgym-secret`)
- **Test users**: admin, testuser, john.doe, jane.smith, disableduser
- **Test roles**: admin, user, manager, developer, viewer
- **Test groups**: admins, users, developers, managers
- **Sample identity provider**: test-oidc
- **Sample authentication flow**: restgym-flow

This provides a complete test environment for RESTgym tools to test against.

### Manual Initialization

Alternatively, run the script during container startup by modifying the Dockerfile CMD to include:

```bash
/database/init-keycloak.sh &
```

## Important Notes

- ⚠️ **H2 is dev-only** - Not for production
- 🔒 **Change admin password** in production
- 📊 **208 API endpoints** via Admin REST API
- 🔑 **JWT tokens** expire after 60 seconds by default
- ✅ **init-keycloak.sh** - Run this script to populate test data

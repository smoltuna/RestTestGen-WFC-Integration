# Nexus Database

## Database Configuration

Sonatype Nexus Repository Manager uses **embedded databases** for data storage.

### Database Types

Nexus uses two embedded databases:

1. **OrientDB** (legacy) - Used in older versions for configuration and metadata
2. **H2 Database** (modern) - Used for components, assets, and repository metadata

### Auto-Initialization

Nexus automatically initializes its database on first startup:

1. **Creates database files** at `/nexus-data/db/` on first startup
2. **Initializes schema** with all required tables for:
   - Components and assets
   - Repositories configuration
   - Security (users, roles, privileges)
   - Blob stores
   - Tasks and scheduling
   - Audit logs
3. **Creates default admin user** with generated password
4. **Takes 60-120 seconds** to fully initialize

### Database Structure

Nexus creates the following data stores:

**Configuration**:
- `component` - Component metadata
- `security` - Users, roles, tokens
- `config` - Repository configurations

**Content**:
- Assets stored in blob stores (filesystem or cloud)
- Metadata stored in H2 database
- Search indexes (Elasticsearch embedded)

### No Manual Initialization Required

Unlike traditional databases:
- ❌ No `schema.sql` needed
- ❌ No `data.sql` needed
- ✅ Nexus manages schema automatically
- ✅ Admin user created automatically

### Initial Admin Access

Nexus creates admin user with generated password:
- **Username**: `admin`
- **Password**: Stored in `/nexus-data/admin.password` (first startup only)

**Retrieve password**:
```bash
docker exec nexus-restgym cat /opt/sonatype/sonatype-work/nexus3/admin.password
```

⚠️ **Important**: This file is **deleted after first login**. Change the password via UI or API after first access.

### Database Location

In container:
```
/nexus-data/
├── db/                    # H2 database files
├── elasticsearch/         # Search indexes
├── blobs/                 # Blob store (default)
├── log/                   # Application logs
└── admin.password        # Initial admin password (first startup only)
```

### Test Data

For testing, you can:
1. Create repositories via REST API
2. Upload components via REST API
3. Create users and roles via REST API
4. Configure blob stores

**Example: Create Maven repository**:
```bash
curl -X POST http://localhost:9090/service/rest/v1/repositories/maven/hosted \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "maven-test",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true
    }
  }'
```

### Backup and Persistence

For production:
- Mount `/nexus-data` as volume: `-v nexus-data:/nexus-data`
- Use blob store on external storage (S3, Azure Blob)
- Enable backup tasks via Nexus UI

### Database Migration

Nexus handles database migrations automatically:
- Schema upgrades applied on startup
- Automatic data migration between versions
- No manual intervention required

## Startup Time

- **First startup**: 90-120 seconds (database initialization + schema creation)
- **Subsequent startups**: 60-90 seconds

## Health Check

Nexus exposes health endpoints:
- `/service/rest/v1/status` - Server status
- `/service/rest/v1/status/writable` - Write operations available
- `/service/rest/v1/status/check` - Detailed health check

## Important Notes

- ⚠️ **Embedded database** - Not for high-traffic production
- ⚠️ **PostgreSQL support** - Available in Pro edition
- 📊 **300+ API endpoints** via REST API
- 🔒 **Change admin password** immediately after first login
- 💾 **Persistent storage** - Use volumes in production

## Production Database

For production deployments, Nexus Repository Pro supports:

**PostgreSQL** (recommended):
```properties
nexus.datastore.enabled=true
nexus.datastore.nexus.jdbcUrl=jdbc:postgresql://postgres:5432/nexus
nexus.datastore.nexus.username=nexus
nexus.datastore.nexus.password=nexus123
```

This requires Nexus Repository Pro license.

# Sonatype Nexus Repository Manager - RESTgym

Complete RESTgym containerization of Sonatype Nexus Repository Manager OSS.

## Overview

**Sonatype Nexus Repository Manager** is a universal repository manager supporting:
- **Maven, Gradle** - Java dependencies
- **npm** - Node.js packages
- **Docker** - Container images
- **PyPI** - Python packages
- **NuGet** - .NET packages
- **RubyGems, Helm, Go, Conan, Conda, Cargo, Composer**, and more

Nexus provides a centralized platform for managing binaries and components across the entire software development lifecycle.

## Project Information

| Property | Value |
|----------|-------|
| **API Name** | Sonatype Nexus Repository Manager |
| **Version** | 3.85.0-03 |
| **Base Image** | sonatype/nexus3:3.85.0 |
| **Language** | Java (OSGi/Apache Karaf) |
| **Framework** | Custom OSGi runtime |
| **Database** | Embedded (OrientDB + H2) |
| **Default Port** | 8081 (internal), 9090 (mitmproxy) |
| **Base Path** | `/service/rest` |
| **API Endpoints** | 300+ REST API endpoints |
| **License** | Eclipse Public License 1.0 |

## RESTgym Structure

```
nexus/
├── Dockerfile                          # Docker image configuration
├── restgym-api-config.yml             # RESTgym configuration
├── README.md                           # This file
├── specifications/                     # OpenAPI specification
│   └── nexus-openapi.yaml             # OpenAPI 3.0 (366 KB, 300+ endpoints)
├── classes/                            # Java classes (N/A - pre-built image)
│   └── README.md                      # Explanation of why no classes
├── dictionaries/                       # DeepREST fuzzing dictionaries
│   ├── deeprest/
│   │   └── nexus.json                 # Domain-specific values (600+ values)
│   └── README.md                      # Dictionary documentation
├── database/                           # Database initialization
│   └── README.md                      # Database auto-initialization info
└── infrastructure/                     # RESTgym monitoring tools
    ├── jacoco/                        # JaCoCo code coverage (N/A for pre-built)
    │   ├── org.jacoco.agent-0.8.7-runtime.jar
    │   ├── org.jacoco.cli-0.8.7.jar
    │   └── collect-coverage-interval.sh
    └── mitmproxy/                     # HTTP interception
        └── store-interactions.py      # SQLite interaction recorder
```

## Quick Start

### Build Docker Image

```bash
cd f:\Desktop\Tesi-RESTAPI\RESTgym\apis\nexus
docker build -t nexus:restgym .
```

**Build time**: ~3-5 minutes (downloads base image)

### Run Container

```bash
docker run -d \
  --name nexus-restgym \
  -p 9090:9090 \
  -p 8081:8081 \
  -e API=nexus \
  -e TOOL=manual \
  -e RUN=1 \
  nexus:restgym
```

### Wait for Startup

Nexus is a complex Java application. **Wait 90-120 seconds** for full initialization:

```bash
# Follow startup logs
docker logs nexus-restgym -f

# Wait for "Started Sonatype Nexus" message
# OR
# Check status endpoint
curl http://localhost:9090/service/rest/v1/status
```

**Startup phases**:
1. Karaf OSGi container initialization (30s)
2. Database schema creation (20s)
3. Repository indexing (20s)
4. REST API activation (20s)

### Get Admin Password

First-time admin password is auto-generated:

```bash
docker exec nexus-restgym cat /opt/sonatype/sonatype-work/nexus3/admin.password
```

**Example output**: `admin123` (random generated)

⚠️ **Important**: This file is **deleted after first login**. Save the password!

### Test API Access

```bash
# Get server status (no auth required)
curl http://localhost:9090/service/rest/v1/status

# List repositories (requires auth)
curl -u admin:admin123 http://localhost:9090/service/rest/v1/repositories

# Search components
curl -u admin:admin123 http://localhost:9090/service/rest/v1/search

# List users
curl -u admin:admin123 http://localhost:9090/service/rest/v1/security/users
```

## API Endpoints

Nexus provides **300+ REST API endpoints** across multiple categories:

### Repository Management (80+ endpoints)
- `/v1/repositories` - Repository CRUD operations
- `/v1/repositories/maven/*` - Maven repositories
- `/v1/repositories/docker/*` - Docker registries
- `/v1/repositories/npm/*` - npm registries
- `/v1/repositories/pypi/*` - PyPI indexes
- `/v1/repositories/nuget/*` - NuGet feeds
- `/v1/repositories/raw/*` - Raw storage
- `/v1/repositories/helm/*` - Helm charts
- `/v1/repositories/go/*` - Go modules
- `/v1/repositories/{repositoryName}/rebuild-index` - Rebuild search index
- `/v1/repositories/{repositoryName}/invalidate-cache` - Clear cache

### Components & Assets (30+ endpoints)
- `/v1/components` - Component management (GET, POST, DELETE)
- `/v1/components/{id}` - Component by ID
- `/v1/assets` - Asset management
- `/v1/assets/{id}` - Asset by ID
- `/v1/search` - Search components
- `/v1/search/assets` - Search assets
- `/v1/search/assets/download` - Download asset

### Security Management (70+ endpoints)
- `/v1/security/users` - User management
- `/v1/security/users/{userId}` - User by ID
- `/v1/security/users/{userId}/change-password` - Change password
- `/v1/security/roles` - Role management
- `/v1/security/roles/{id}` - Role by ID
- `/v1/security/privileges` - Privilege management
- `/v1/security/privileges/{privilegeName}` - Privilege by name
- `/v1/security/ldap` - LDAP configuration
- `/v1/security/realms/active` - Active security realms
- `/v1/security/anonymous` - Anonymous access
- `/v1/security/ssl` - SSL certificate management
- `/v1/security/content-selectors` - Content selectors

### Blob Stores (20+ endpoints)
- `/v1/blobstores` - Blob store management
- `/v1/blobstores/file` - File-based blob stores
- `/v1/blobstores/s3` - AWS S3 blob stores
- `/v1/blobstores/azure` - Azure Blob Storage
- `/v1/blobstores/google` - Google Cloud Storage
- `/v1/blobstores/{name}/quota-status` - Quota information

### Tasks & Automation (15+ endpoints)
- `/v1/tasks` - Task management
- `/v1/tasks/{id}` - Task by ID
- `/v1/tasks/{id}/run` - Run task
- `/v1/tasks/{id}/stop` - Stop task
- `/v1/script` - Groovy script execution

### System & Monitoring (30+ endpoints)
- `/v1/status` - Server status
- `/v1/status/writable` - Write mode status
- `/v1/status/check` - Health check
- `/v1/read-only` - Read-only mode management
- `/v1/lifecycle/phase` - Application lifecycle
- `/v1/system/node` - Node information
- `/beta/system/information` - System details
- `/beta/data-store` - Data store info

### Routing & Content (15+ endpoints)
- `/v1/routing-rules` - Routing rules
- `/v1/routing-rules/{name}` - Routing rule by name
- `/v1/security/content-selectors` - Content selectors
- `/v1/formats` - Supported formats
- `/v1/formats/upload-specs` - Upload specifications

### Additional Features
- Email configuration
- LDAP integration
- Repository health checks
- Cleanup policies
- Support ZIP generation
- License management (Pro)
- Malicious risk analysis (Pro)

## Testing Examples

### Create Maven Hosted Repository

```bash
curl -X POST http://localhost:9090/service/rest/v1/repositories/maven/hosted \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "maven-test",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true,
      "writePolicy": "ALLOW"
    },
    "maven": {
      "versionPolicy": "RELEASE",
      "layoutPolicy": "STRICT"
    }
  }'
```

### Create Docker Hosted Registry

```bash
curl -X POST http://localhost:9090/service/rest/v1/repositories/docker/hosted \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "docker-test",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true,
      "writePolicy": "ALLOW"
    },
    "docker": {
      "v1Enabled": false,
      "forceBasicAuth": true,
      "httpPort": 5000
    }
  }'
```

### Create User

```bash
curl -X POST http://localhost:9090/service/rest/v1/security/users \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "testuser",
    "firstName": "Test",
    "lastName": "User",
    "emailAddress": "test@example.com",
    "password": "test123",
    "status": "active",
    "roles": ["nx-anonymous"]
  }'
```

### Search Components

```bash
# Search by name
curl -u admin:admin123 \
  "http://localhost:9090/service/rest/v1/search?q=junit"

# Search in specific repository
curl -u admin:admin123 \
  "http://localhost:9090/service/rest/v1/search?repository=maven-central&q=spring"

# Search by format
curl -u admin:admin123 \
  "http://localhost:9090/service/rest/v1/search?format=maven2"
```

## RESTgym Integration

### HTTP Interception (mitmproxy)

All requests via port 9090 are captured by mitmproxy:

```bash
# Make API request (automatically captured)
curl -u admin:admin123 http://localhost:9090/service/rest/v1/repositories

# Check interactions database
docker exec nexus-restgym ls -lh /results/nexus/manual/1/interactions.db

# Query interactions
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT method, url, status_code FROM interactions ORDER BY id DESC LIMIT 10;"
```

**Interactions database schema**:
```sql
CREATE TABLE interactions (
    id INTEGER PRIMARY KEY,
    method TEXT,
    url TEXT,
    status_code INTEGER,
    request_body TEXT,
    response_body TEXT,
    timestamp DATETIME
);
```

### Query Examples

```bash
# Count total requests
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT COUNT(*) FROM interactions;"

# Count unique endpoints
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT COUNT(DISTINCT url) FROM interactions;"

# Status code distribution
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT status_code, COUNT(*) FROM interactions GROUP BY status_code;"

# Most called endpoints
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT url, COUNT(*) as calls FROM interactions GROUP BY url ORDER BY calls DESC LIMIT 10;"
```

## OpenAPI Specification

**File**: `specifications/nexus-openapi.yaml`
- **Format**: OpenAPI 3.0.1
- **Size**: 366 KB (~10,000 lines)
- **Endpoints**: 300+ documented endpoints
- **Source**: Converted from Swagger 2.0 (official Nexus `/service/rest/swagger.json`)

**Categories**:
- Assets (5 endpoints)
- Components (4 endpoints)
- Repository Management (80+ endpoints)
- Content selectors (4 endpoints)
- Routing rules (4 endpoints)
- Search (3 endpoints)
- Security privileges (15+ endpoints)
- Tasks (4 endpoints)
- Users (3 endpoints)
- Roles (4 endpoints)
- Scripts (5 endpoints)
- LDAP (5 endpoints)
- Status (3 endpoints)
- Blob stores (15+ endpoints)
- Email (2 endpoints)
- Formats (2 endpoints)
- Read-only mode (4 endpoints)
- Lifecycle (2 endpoints)
- System nodes (1 endpoint)
- Anonymous access (1 endpoint)
- Realms (2 endpoints)
- Capabilities (2 endpoints)
- And more...

**Note**: Nexus does NOT auto-generate OpenAPI at runtime. The spec was obtained from `/service/rest/swagger.json` and converted to OpenAPI 3.0 format.

## Dictionary

**File**: `dictionaries/deeprest/nexus.json`
- **Categories**: 30+
- **Total values**: 600+

**Key categories**:
- **repository_names** (20) - Repository identifiers
- **repository_formats** (20) - Supported formats (maven2, npm, docker, etc.)
- **repository_types** (3) - hosted, proxy, group
- **blob_store_names** (9) - Blob store identifiers
- **component_names** (20) - Common Java components
- **group_ids** (20) - Maven group IDs
- **artifact_ids** (20) - Maven artifact IDs
- **versions** (20) - Version strings
- **user_names** (20) - User identifiers
- **role_names** (20) - Nexus roles
- **privilege_names** (20) - Security privileges
- **docker_images** (20) - Docker image names
- **docker_tags** (16) - Docker tags
- **npm_packages** (20) - npm package names
- **pypi_packages** (20) - Python package names
- **task_types** (14) - Nexus task types
- **cleanup_policy_names** (6) - Cleanup policies
- **routing_rule_names** (5) - Routing rules
- **And more...**

## Database

Nexus uses **embedded databases**:
- **OrientDB** - Configuration and metadata (legacy)
- **H2** - Components, assets, search indexes (modern)

**Auto-initialization**: Database schema created automatically on first startup (90-120 seconds).

See `database/README.md` for details.

## Environment Variables

Customize container behavior:

```bash
# RESTgym variables
-e API=nexus              # API slug
-e TOOL=manual            # Testing tool name
-e RUN=1                  # Run number

# Nexus variables (optional)
-e NEXUS_CONTEXT=/        # Context path (default: /)
-e INSTALL4J_ADD_VM_PARAMS="-Xms2703m -Xmx2703m"  # JVM memory
```

## Port Mapping

| Port | Service | Access |
|------|---------|--------|
| 9090 | mitmproxy | HTTP interception (primary API access) |
| 8081 | Nexus | Direct API access + Web UI |
| 12345 | JaCoCo | Code coverage (N/A for pre-built image) |

**Recommendation**: Access API via port 9090 to capture interactions.

## Health Checks

Nexus provides health endpoints:

```bash
# Server status (no auth)
curl http://localhost:9090/service/rest/v1/status

# Write mode status (requires auth)
curl -u admin:admin123 http://localhost:9090/service/rest/v1/status/writable

# Detailed health check (requires auth)
curl -u admin:admin123 http://localhost:9090/service/rest/v1/status/check
```

Docker health check monitors `/service/rest/v1/status` every 30 seconds.

## Logs

```bash
# View startup logs
docker logs nexus-restgym

# Follow logs
docker logs nexus-restgym -f

# View saved logs
docker exec nexus-restgym cat /results/nexus/manual/1/nexus.log
```

## Cleanup

```bash
# Stop container
docker stop nexus-restgym

# Remove container
docker rm nexus-restgym

# Remove image
docker rmi nexus:restgym
```

## Important Notes & Limitations

### ⚠️ Critical Differences from Other RESTgym APIs

**Nexus uses official Docker image** - this has specific implications:

1. **❌ NO JAR FILE**
   - Nexus is distributed as pre-built Docker image
   - Uses Apache Karaf OSGi runtime (not single JAR)
   - Complex multi-module architecture

2. **❌ NO .class FILES**
   - Pre-built image, no extractable classes
   - Source code available on GitHub but complex build
   - OSGi bundles, not traditional JAR structure

3. **❌ JaCoCo NOT APPLICABLE**
   - Code coverage requires source build with instrumentation
   - Official image is optimized, not instrumented
   - **Alternative**: Track HTTP endpoint coverage via mitmproxy

4. **✅ WHAT WORKS**
   - **mitmproxy**: HTTP interception fully functional
   - **SQLite interactions.db**: All requests logged
   - **Endpoint coverage**: Track which of 300+ endpoints were called
   - **Complete REST API**: All endpoints documented in OpenAPI

### Other Important Notes

- ⚠️ **Startup time**: 90-120 seconds for full initialization
- ⚠️ **Admin password**: Auto-generated, file deleted after first login
- ⚠️ **Base path**: All endpoints under `/service/rest` (not root `/`)
- ⚠️ **Embedded database**: Not for high-traffic production (use PostgreSQL in Pro)
- ✅ **300+ endpoints**: Complete repository management API
- ✅ **20+ formats**: Maven, npm, Docker, PyPI, NuGet, and more
- 🔒 **Change admin password**: Immediately after first login
- 💾 **Persistent storage**: Use volumes for `/nexus-data` in production

## Production Considerations

For production deployment:

1. **External Database** (Nexus Pro):
   ```properties
   nexus.datastore.enabled=true
   nexus.datastore.nexus.jdbcUrl=jdbc:postgresql://postgres:5432/nexus
   nexus.datastore.nexus.username=nexus
   nexus.datastore.nexus.password=secure_password
   ```

2. **Persistent Storage**:
   ```bash
   docker run -v nexus-data:/nexus-data ...
   ```

3. **JVM Tuning**:
   ```bash
   -e INSTALL4J_ADD_VM_PARAMS="-Xms4g -Xmx4g -XX:MaxDirectMemorySize=6g"
   ```

4. **HTTPS**: Use reverse proxy (nginx, Traefik) for TLS termination

5. **Backup**: Regular backups of `/nexus-data` volume

6. **Monitoring**: Use `/v1/status/check` for health monitoring

## References

- **Official Documentation**: https://help.sonatype.com/repomanager3
- **REST API Docs**: https://help.sonatype.com/repomanager3/rest-and-integration-api
- **Source Code**: https://github.com/sonatype/nexus-public
- **Docker Hub**: https://hub.docker.com/r/sonatype/nexus3
- **OpenAPI Spec**: Generated from `/service/rest/swagger.json`

---

**Status**: Complete RESTgym containerization with comprehensive documentation

**Nexus Version**: 3.85.0-03  
**OpenAPI Endpoints**: 300+  
**Dictionary Values**: 600+  
**Supported Formats**: 20+

# Nexus OpenAPI Specification

This directory contains the OpenAPI specification for the Sonatype Nexus Repository Manager REST API.

## File Information

| Property | Value |
|----------|-------|
| **Filename** | nexus-openapi.yaml |
| **Format** | OpenAPI 3.0.1 |
| **Size** | 366 KB (~10,000 lines) |
| **Source** | Converted from Swagger 2.0 (`/service/rest/swagger.json`) |
| **Endpoints** | 300+ documented REST endpoints |
| **Generated** | From official Nexus 3.85.0 release |

## Overview

The OpenAPI specification documents all public REST API endpoints available in Nexus Repository Manager OSS (Open Source Software) version 3.85.0.

Nexus does **NOT** auto-generate OpenAPI specs at runtime. The specification was obtained by:
1. Accessing the Swagger 2.0 endpoint: `GET /service/rest/swagger.json`
2. Converting to OpenAPI 3.0.1 format
3. Manual validation and cleanup

## Endpoint Categories

The API is organized into 30+ functional categories:

### Repository Management (80+ endpoints)
- **Maven repositories** - `/v1/repositories/maven/*`
- **Docker registries** - `/v1/repositories/docker/*`
- **npm registries** - `/v1/repositories/npm/*`
- **PyPI indexes** - `/v1/repositories/pypi/*`
- **NuGet feeds** - `/v1/repositories/nuget/*`
- **Raw storage** - `/v1/repositories/raw/*`
- **Helm charts** - `/v1/repositories/helm/*`
- **Go modules** - `/v1/repositories/go/*`
- **RubyGems** - `/v1/repositories/rubygems/*`
- **Repository groups** - Combine multiple repositories
- **Repository health** - Health check and status
- **Repository rebuild** - Index rebuild operations
- **Repository invalidate** - Cache invalidation

### Components & Assets (30+ endpoints)
- `/v1/components` - Component CRUD operations (GET, POST, DELETE)
- `/v1/components/{id}` - Component by ID
- `/v1/assets` - Asset management
- `/v1/assets/{id}` - Asset by ID
- `/v1/search` - Component search with filters
- `/v1/search/assets` - Asset search
- `/v1/search/assets/download` - Direct asset download

### Security Management (70+ endpoints)
- **Users** - `/v1/security/users` (CRUD operations)
- **Roles** - `/v1/security/roles` (predefined and custom roles)
- **Privileges** - `/v1/security/privileges` (fine-grained permissions)
- **Content selectors** - `/v1/security/content-selectors` (content filtering)
- **LDAP** - `/v1/security/ldap` (LDAP integration)
- **Realms** - `/v1/security/realms/active` (authentication realms)
- **Anonymous access** - `/v1/security/anonymous` (anonymous config)
- **SSL certificates** - `/v1/security/ssl` (certificate management)
- **User tokens** - Token-based authentication

### Blob Stores (20+ endpoints)
- `/v1/blobstores` - Blob store management
- `/v1/blobstores/file` - File-based blob stores (local disk)
- `/v1/blobstores/s3` - AWS S3 blob stores
- `/v1/blobstores/azure` - Azure Blob Storage
- `/v1/blobstores/google` - Google Cloud Storage
- `/v1/blobstores/{name}/quota-status` - Quota monitoring

### Tasks & Automation (15+ endpoints)
- `/v1/tasks` - Task management (scheduled jobs)
- `/v1/tasks/{id}` - Task by ID
- `/v1/tasks/{id}/run` - Manual task execution
- `/v1/tasks/{id}/stop` - Stop running task
- `/v1/script` - Groovy script execution (admin only)

### System & Monitoring (30+ endpoints)
- `/v1/status` - Server status (health check)
- `/v1/status/writable` - Write mode status
- `/v1/status/check` - Detailed health check
- `/v1/read-only` - Read-only mode management
- `/v1/lifecycle/phase` - Application lifecycle
- `/v1/system/node` - Node information (clustering)
- `/beta/system/information` - System details
- `/beta/data-store` - Data store info

### Routing & Content (15+ endpoints)
- `/v1/routing-rules` - Routing rules management
- `/v1/routing-rules/{name}` - Routing rule by name
- `/v1/formats` - Supported repository formats
- `/v1/formats/upload-specs` - Upload specifications
- `/v1/security/content-selectors` - Content filtering rules

### Additional Categories
- **Email** - Email server configuration
- **Cleanup policies** - Automated cleanup rules
- **Support** - Support ZIP generation (Pro feature)
- **License** - License management (Pro feature)
- **Malicious risk** - Security analysis (Pro feature)

## Authentication

The API uses **HTTP Basic Authentication**:

```
Authorization: Basic base64(username:password)
```

**Default credentials**:
- Username: `admin`
- Password: Retrieved from `/opt/sonatype/sonatype-work/nexus3/admin.password` (first startup only)

**Important**: Change the admin password immediately after first login. The password file is deleted after successful authentication.

### Authentication Example

```bash
# Using curl
curl -u admin:admin123 http://localhost:9090/service/rest/v1/repositories

# Using Authorization header
curl -H "Authorization: Basic YWRtaW46YWRtaW4xMjM=" \
  http://localhost:9090/service/rest/v1/repositories
```

## Security Schemes

The OpenAPI spec defines one security scheme:

```yaml
securitySchemes:
  basicAuth:
    type: http
    scheme: basic
    description: HTTP Basic Authentication with username and password
```

Most endpoints require authentication (marked with `security: [basicAuth: []]`).

**Unauthenticated endpoints**:
- `GET /v1/status` - Server status check (public)

## Common Parameters

### Query Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `repository` | string | Filter by repository | `repository=maven-central` |
| `format` | string | Filter by format | `format=maven2` |
| `q` | string | Search query | `q=junit` |
| `group` | string | Maven group ID | `group=org.springframework` |
| `name` | string | Component name | `name=spring-boot` |
| `version` | string | Component version | `version=2.5.0` |
| `continuationToken` | string | Pagination token | (base64 string) |

### Path Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `{id}` | string | Component/asset ID | UUID format |
| `{repositoryName}` | string | Repository name | `maven-central` |
| `{userId}` | string | User ID | `testuser` |
| `{privilegeName}` | string | Privilege name | `nx-admin` |
| `{name}` | string | Generic name | Various |

## Response Codes

Common HTTP status codes used:

| Code | Description | Usage |
|------|-------------|-------|
| 200 | OK | Successful GET/PUT/DELETE |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE (no body) |
| 400 | Bad Request | Invalid parameters |
| 401 | Unauthorized | Missing/invalid authentication |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 500 | Internal Server Error | Server error |

## Schema Definitions

The specification includes comprehensive schema definitions for all request/response bodies:

### Repository Schemas
- `MavenHostedRepositoryApiRequest` - Maven hosted repository
- `MavenProxyRepositoryApiRequest` - Maven proxy repository
- `MavenGroupRepositoryApiRequest` - Maven group repository
- `DockerHostedRepositoryApiRequest` - Docker registry
- `NpmHostedRepositoryApiRequest` - npm registry
- `PypiHostedRepositoryApiRequest` - PyPI index
- `NugetHostedRepositoryApiRequest` - NuGet feed
- And 50+ more for all formats...

### Component Schemas
- `ComponentXO` - Component representation
- `AssetXO` - Asset representation
- `PageComponentXO` - Paginated component list
- `PageAssetXO` - Paginated asset list

### Security Schemas
- `ApiUser` - User representation
- `ApiRole` - Role representation
- `ApiPrivilege` - Privilege representation
- `ApiContentSelector` - Content selector

### Common Schemas
- `ApiSearchResult` - Search result wrapper
- `ApiError` - Error response
- `ApiPagedResponse` - Generic pagination

## Validation

The specification includes comprehensive validation rules:

### Required Fields
- `name` - Repository/user/role name
- `online` - Repository status
- `storage.blobStoreName` - Blob store name
- `storage.writePolicy` - Write policy (ALLOW, ALLOW_ONCE, DENY)

### Constraints
- Names: alphanumeric + hyphens, no spaces
- Passwords: minimum length requirements
- URLs: valid HTTP/HTTPS format
- Ports: 1-65535 range

### Examples

Request body example (create Maven repository):
```json
{
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
}
```

## Known Issues & Limitations

### Conversion from Swagger 2.0
- Some `$ref` paths may need adjustment for local validation
- Examples may not be present for all schemas
- Some Pro-only endpoints included (require Nexus Pro license)

### API Limitations
- **No GraphQL** - REST API only
- **No WebSocket** - HTTP request/response only
- **Rate limiting** - Not documented in spec (depends on configuration)
- **Pagination** - Uses continuation tokens (not page numbers)

### Format-Specific Endpoints
Some repository formats have unique endpoints not covered by generic repository APIs:
- Docker push/pull - Uses Docker Registry HTTP API v2 (separate spec)
- Maven deploy - Uses HTTP PUT to repository path (not REST API)
- npm publish - Uses npm registry protocol (not REST API)

**Note**: The OpenAPI spec documents **management APIs**, not artifact upload/download protocols.

## Using the Specification

### Swagger UI

View interactive documentation:
```bash
# Install Swagger UI
docker run -p 8080:8080 \
  -e SWAGGER_JSON=/spec/nexus-openapi.yaml \
  -v $(pwd)/specifications:/spec \
  swaggerapi/swagger-ui
```

Open: http://localhost:8080

### Postman

Import the specification:
1. Open Postman
2. Import → Upload file → Select `nexus-openapi.yaml`
3. Collection created with all 300+ endpoints
4. Configure environment: base URL = `http://localhost:9090/service/rest`

### Code Generation

Generate client libraries:
```bash
# Install OpenAPI Generator
npm install -g @openapitools/openapi-generator-cli

# Generate Python client
openapi-generator-cli generate \
  -i specifications/nexus-openapi.yaml \
  -g python \
  -o ./client-python

# Generate Java client
openapi-generator-cli generate \
  -i specifications/nexus-openapi.yaml \
  -g java \
  -o ./client-java
```

### Validation

Validate the specification:
```bash
# Using OpenAPI CLI
npm install -g @apidevtools/swagger-cli
swagger-cli validate specifications/nexus-openapi.yaml

# Using spectral
npm install -g @stoplight/spectral-cli
spectral lint specifications/nexus-openapi.yaml
```

## Testing Strategy

### Coverage Analysis

Track endpoint coverage during testing:

1. **Extract all endpoints** from OpenAPI:
   ```bash
   # Count total endpoints
   grep -c "      description:" specifications/nexus-openapi.yaml
   ```

2. **Query tested endpoints** from interactions.db:
   ```sql
   SELECT DISTINCT url FROM interactions;
   ```

3. **Calculate coverage**:
   ```
   Coverage = (Unique URLs tested / Total endpoints) × 100%
   ```

### Priority Endpoints (Testing Order)

1. **High priority** (core functionality):
   - `/v1/status` - Health check
   - `/v1/repositories` - Repository list
   - `/v1/search` - Component search
   - `/v1/security/users` - User management

2. **Medium priority** (important features):
   - Repository creation (all formats)
   - Component upload/delete
   - Asset management
   - Role/privilege management

3. **Low priority** (advanced features):
   - Blob store management
   - Task scheduling
   - Routing rules
   - Content selectors

## Maintenance

### Updating the Specification

When Nexus version updates:

1. **Fetch latest Swagger**:
   ```bash
   curl http://localhost:8081/service/rest/swagger.json > swagger-new.json
   ```

2. **Convert to OpenAPI 3.0**:
   ```bash
   npm install -g swagger2openapi
   swagger2openapi swagger-new.json -o nexus-openapi-new.yaml
   ```

3. **Validate**:
   ```bash
   swagger-cli validate nexus-openapi-new.yaml
   ```

4. **Compare versions**:
   ```bash
   diff nexus-openapi.yaml nexus-openapi-new.yaml
   ```

### Version History

| Nexus Version | Spec Version | Endpoints | Date |
|---------------|--------------|-----------|------|
| 3.85.0 | OpenAPI 3.0.1 | 300+ | 2024 |

## Additional Resources

- **Nexus REST API Docs**: https://help.sonatype.com/repomanager3/rest-and-integration-api
- **Swagger Endpoint**: `GET /service/rest/swagger.json` (Swagger 2.0)
- **API Explorer**: Available in Nexus UI (Admin → System → API)
- **GitHub Issues**: https://github.com/sonatype/nexus-public/issues

---

**Complete specification**: 300+ endpoints across 30+ categories for comprehensive repository management

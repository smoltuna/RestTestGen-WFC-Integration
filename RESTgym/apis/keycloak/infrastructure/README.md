# Keycloak Infrastructure

## Overview

This directory contains RESTgym tools for monitoring and analyzing Keycloak API behavior during testing.

## Structure

```
infrastructure/
├── jacoco/                             # Code coverage (not applicable)
│   ├── org.jacoco.agent-0.8.7-runtime.jar
│   ├── org.jacoco.cli-0.8.7.jar
│   └── collect-coverage-interval.sh
└── mitmproxy/                          # HTTP interception ✅
    └── store-interactions.py
```

## mitmproxy - HTTP Interception

### Purpose

Captures all HTTP requests/responses between RESTgym test tools and Keycloak Admin API.

### File

**store-interactions.py** (6 KB)
- mitmproxy addon
- Records HTTP interactions to SQLite database
- Stores: method, URL, status code, request body, response body

### How It Works

1. **mitmproxy runs** on port 9090 as reverse proxy
2. **API requests** go through mitmproxy: `http://localhost:9090/admin/realms/...`
3. **mitmproxy forwards** to Keycloak: `http://localhost:8080/admin/realms/...`
4. **Interactions captured** in SQLite database

### Database Location

```
/results/keycloak/{TOOL}/{RUN}/interactions.db
```

Example: `/results/keycloak/manual/1/interactions.db`

### Database Schema

```sql
CREATE TABLE interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    method TEXT,                    -- HTTP method (GET, POST, PUT, DELETE)
    url TEXT,                       -- Full URL
    status_code INTEGER,            -- HTTP status code
    request_body TEXT,              -- Request body (truncated to 5000 chars)
    response_body TEXT,             -- Response body (truncated to 5000 chars)
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Query Examples

```bash
# Connect to database
docker exec keycloak-restgym sqlite3 /results/keycloak/manual/1/interactions.db

# Count total interactions
SELECT COUNT(*) FROM interactions;

# List all endpoints tested
SELECT DISTINCT method, url FROM interactions ORDER BY method, url;

# Find failed requests
SELECT method, url, status_code FROM interactions WHERE status_code >= 400;

# Show recent interactions
SELECT method, url, status_code, timestamp FROM interactions ORDER BY timestamp DESC LIMIT 10;

# Count by HTTP method
SELECT method, COUNT(*) as count FROM interactions GROUP BY method;

# Count by status code
SELECT status_code, COUNT(*) as count FROM interactions GROUP BY status_code;
```

### Export Interactions

```bash
# Export to CSV
docker exec keycloak-restgym sqlite3 /results/keycloak/manual/1/interactions.db \
  -header -csv "SELECT * FROM interactions;" > interactions.csv

# Export to JSON
docker exec keycloak-restgym sqlite3 /results/keycloak/manual/1/interactions.db \
  -json "SELECT * FROM interactions;" > interactions.json
```

### Usage

mitmproxy is automatically started in the Dockerfile CMD:

```dockerfile
CMD mitmdump -p 9090 \
    --mode reverse:http://localhost:8080/ \
    -s /infrastructure/mitmproxy/store-interactions.py &
```

### Testing mitmproxy

```bash
# Make API request via mitmproxy
TOKEN=$(curl -s -X POST http://localhost:9090/realms/master/protocol/openid-connect/token \
  -d "username=admin&password=admin&grant_type=password&client_id=admin-cli" \
  | jq -r '.access_token')

curl http://localhost:9090/admin/realms/master \
  -H "Authorization: Bearer $TOKEN"

# Check if interaction was recorded
docker exec keycloak-restgym sqlite3 /results/keycloak/manual/1/interactions.db \
  "SELECT COUNT(*) FROM interactions;"
```

## JaCoCo - Code Coverage

### ❌ JaCoCo CANNOT BE USED

**Critical Understanding**: Keycloak is fundamentally incompatible with JaCoCo.

### Why JaCoCo Doesn't Work

Keycloak 23.0.7 uses **Quarkus 3.15.1 Native Compilation**:

1. **No JAR File**: Keycloak is compiled to native machine code (like C/C++)
   - Located at `/opt/keycloak/bin/kc.sh` (native binary)
   - NOT a `.jar` file with bytecode

2. **No Java Bytecode**: Classes compiled directly to machine code
   - JaCoCo requires JVM bytecode to instrument
   - Native code cannot be instrumented by Java agents

3. **No Java Agent Support**: Native images don't support `-javaagent`
   - JaCoCo agent (`org.jacoco.agent-*.jar`) requires JVM
   - Quarkus native runs without JVM

4. **Architectural Difference**:
   ```
   Traditional Java App: .java → .class (bytecode) → JVM → Execution [JaCoCo can instrument]
   Quarkus Native:       .java → native code → Direct CPU execution [JaCoCo CANNOT instrument]
   ```

### Why JaCoCo Files Are Still Present

The `infrastructure/jacoco/` directory exists for **RESTgym template consistency**:
- Other APIs (Spring Boot, Micronaut) CAN use JaCoCo
- RESTgym expects this directory structure
- Files are present but **not used** for Keycloak

### Alternative Coverage Metrics

For Keycloak, use these alternatives:

#### 1. HTTP Endpoint Coverage
Track which Admin API endpoints were tested:

```sql
-- Count unique endpoints
SELECT COUNT(DISTINCT url) FROM interactions;

-- List tested endpoints
SELECT DISTINCT method || ' ' || url FROM interactions ORDER BY url;
```

#### 2. Status Code Distribution
Analyze response patterns:

```sql
SELECT 
    CASE 
        WHEN status_code < 300 THEN 'Success (2xx)'
        WHEN status_code < 400 THEN 'Redirect (3xx)'
        WHEN status_code < 500 THEN 'Client Error (4xx)'
        ELSE 'Server Error (5xx)'
    END as category,
    COUNT(*) as count
FROM interactions
GROUP BY category;
```

#### 3. Keycloak Metrics
Keycloak exposes built-in metrics:

```bash
# Prometheus metrics
curl http://localhost:8080/metrics

# Health metrics
curl http://localhost:8080/health

# Readiness check
curl http://localhost:8080/health/ready

# Liveness check
curl http://localhost:8080/health/live
```

#### 4. Event Logs
Query Keycloak event database:

```bash
# User events
curl http://localhost:9090/admin/realms/master/events \
  -H "Authorization: Bearer $TOKEN"

# Admin events
curl http://localhost:9090/admin/realms/master/admin-events \
  -H "Authorization: Bearer $TOKEN"
```

### JaCoCo Files Included

JaCoCo files are included for template consistency:
- `org.jacoco.agent-0.8.7-runtime.jar` (285 KB) - Not used
- `org.jacoco.cli-0.8.7.jar` (554 KB) - Not used
- `collect-coverage-interval.sh` (0.3 KB) - Not used

**These files do not affect Keycloak operation** - They're present to maintain RESTgym template compatibility.

## RESTgym Integration

### Environment Variables

```bash
API=keycloak          # API slug
TOOL=manual           # Testing tool name (manual, deeprest, etc.)
RUN=1                 # Run number
```

### Results Directory Structure

```
/results/
└── keycloak/
    └── {TOOL}/
        └── {RUN}/
            ├── keycloak.log        # Keycloak startup logs
            └── interactions.db     # SQLite database with HTTP interactions
```

### Accessing Results

```bash
# List result files
docker exec keycloak-restgym ls -lh /results/keycloak/manual/1/

# View logs
docker exec keycloak-restgym cat /results/keycloak/manual/1/keycloak.log

# Query interactions
docker exec keycloak-restgym sqlite3 /results/keycloak/manual/1/interactions.db \
  "SELECT method, url, status_code FROM interactions LIMIT 10;"
```

## Testing Workflow

### 1. Start Container

```bash
docker run -d \
  --name keycloak-restgym \
  -p 9090:9090 \
  -p 8080:8080 \
  -e API=keycloak \
  -e TOOL=manual \
  -e RUN=1 \
  keycloak:restgym
```

### 2. Wait for Startup

```bash
# Wait for health check (45-60 seconds)
docker logs keycloak-restgym -f

# Check readiness
curl http://localhost:8080/health/ready
```

### 3. Run Tests

```bash
# Get admin token
TOKEN=$(curl -s -X POST http://localhost:9090/realms/master/protocol/openid-connect/token \
  -d "username=admin&password=admin&grant_type=password&client_id=admin-cli" \
  | jq -r '.access_token')

# Test Admin API endpoints
curl http://localhost:9090/admin/realms/master -H "Authorization: Bearer $TOKEN"
curl http://localhost:9090/admin/realms/master/users -H "Authorization: Bearer $TOKEN"
curl http://localhost:9090/admin/realms/master/clients -H "Authorization: Bearer $TOKEN"
```

### 4. Analyze Results

```bash
# Count interactions
docker exec keycloak-restgym sqlite3 /results/keycloak/manual/1/interactions.db \
  "SELECT COUNT(*) FROM interactions;"

# Export results
docker cp keycloak-restgym:/results/keycloak/manual/1/interactions.db ./
```

## Tools & Dependencies

### mitmproxy
- **Version**: Latest (installed via pip3)
- **Purpose**: HTTP/HTTPS proxy
- **Documentation**: https://mitmproxy.org

### SQLite
- **Version**: 3.x (pre-installed in Keycloak image)
- **Purpose**: Interactions database
- **Documentation**: https://www.sqlite.org

### Python 3
- **Version**: 3.x (pre-installed)
- **Purpose**: mitmproxy runtime
- **Required packages**: mitmproxy

## Troubleshooting

### mitmproxy not capturing

**Symptoms**: interactions.db empty or not created

**Solutions**:
1. Verify mitmproxy is running: `docker logs keycloak-restgym | grep mitmproxy`
2. Check port 9090 is accessible: `nc -zv localhost 9090`
3. Ensure requests go through port 9090 (not 8080)
4. Check Python script: `docker exec keycloak-restgym ls /infrastructure/mitmproxy/`

### Database errors

**Symptoms**: SQLite errors in logs

**Solutions**:
1. Check /results directory exists: `docker exec keycloak-restgym ls -la /results/`
2. Verify permissions: `docker exec keycloak-restgym ls -la /results/keycloak/`
3. Manually create DB: `docker exec keycloak-restgym mkdir -p /results/keycloak/manual/1`

### Logs not saved

**Symptoms**: keycloak.log missing

**Solutions**:
1. Check CMD redirects output: `docker inspect keycloak-restgym`
2. Verify directory exists: `docker exec keycloak-restgym ls /results/keycloak/manual/1/`
3. Check disk space: `docker exec keycloak-restgym df -h`

## References

- **mitmproxy Docs**: https://docs.mitmproxy.org/stable/
- **SQLite Docs**: https://www.sqlite.org/docs.html
- **JaCoCo Docs**: https://www.jacoco.org/jacoco/trunk/doc/
- **Quarkus Observability**: https://quarkus.io/guides/observability

---

**mitmproxy works** ✅ | **JaCoCo not applicable** ⚠️

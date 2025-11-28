# Nexus Infrastructure

This directory contains RESTgym monitoring and analysis tools for the Nexus Repository Manager container.

## Overview

Two monitoring tools are integrated:
1. **mitmproxy** - HTTP request/response interception
2. **JaCoCo** - Code coverage (❌ NOT APPLICABLE for pre-built image)

## Directory Structure

```
infrastructure/
├── mitmproxy/
│   └── store-interactions.py      # SQLite interaction recorder
└── jacoco/
    ├── org.jacoco.agent-0.8.7-runtime.jar
    ├── org.jacoco.cli-0.8.7.jar
    └── collect-coverage-interval.sh
```

## mitmproxy - HTTP Interception ✅

### Purpose

**mitmproxy** intercepts all HTTP requests/responses between test tools and the Nexus API, storing them in SQLite for analysis.

**Why it works**: HTTP-level interception, no source code or instrumentation required.

### How It Works

```
Test Tool → Port 9090 → mitmproxy → Port 8081 → Nexus API
                           ↓
                    store-interactions.py
                           ↓
                   interactions.db (SQLite)
```

### Configuration

Configured in `Dockerfile`:

```dockerfile
CMD mitmdump -p 9090 \
    --mode reverse:http://localhost:8081/ \
    -s /infrastructure/mitmproxy/store-interactions.py & \
    tail -f /results/$API/$TOOL/$RUN/nexus.log
```

- **Port 9090**: External mitmproxy port
- **Port 8081**: Internal Nexus port
- **Mode**: Reverse proxy (transparent to clients)
- **Script**: `store-interactions.py` captures all interactions

### Database Schema

SQLite database: `/results/nexus/$TOOL/$RUN/interactions.db`

```sql
CREATE TABLE interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    method TEXT NOT NULL,
    url TEXT NOT NULL,
    status_code INTEGER,
    request_headers TEXT,
    request_body TEXT,
    response_headers TEXT,
    response_body TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
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
  "SELECT status_code, COUNT(*) as count 
   FROM interactions 
   GROUP BY status_code 
   ORDER BY count DESC;"

# Most frequently called endpoints
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT url, COUNT(*) as calls 
   FROM interactions 
   GROUP BY url 
   ORDER BY calls DESC 
   LIMIT 10;"

# Endpoints by HTTP method
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT method, COUNT(*) as count 
   FROM interactions 
   GROUP BY method 
   ORDER BY count DESC;"

# Failed requests (4xx/5xx)
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT method, url, status_code 
   FROM interactions 
   WHERE status_code >= 400 
   ORDER BY timestamp DESC;"

# Request timeline
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT timestamp, method, url, status_code 
   FROM interactions 
   ORDER BY timestamp DESC 
   LIMIT 20;"

# Endpoint coverage (unique URLs tested)
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT DISTINCT url FROM interactions ORDER BY url;"
```

### Export Interactions

#### Export to CSV

```bash
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  -header -csv "SELECT * FROM interactions;" > nexus-interactions.csv
```

#### Export to JSON

```bash
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT json_group_array(
    json_object(
      'id', id,
      'method', method,
      'url', url,
      'status_code', status_code,
      'timestamp', timestamp
    )
  ) FROM interactions;" > nexus-interactions.json
```

### Coverage Analysis

Calculate REST API endpoint coverage:

```sql
-- Total endpoints in OpenAPI spec: 300+
-- Extract tested endpoints:
SELECT COUNT(DISTINCT url) as endpoints_tested FROM interactions;

-- Calculate coverage percentage:
-- Coverage = (endpoints_tested / 300) × 100%
```

Example:
- OpenAPI spec: 300 endpoints
- Tested endpoints: 150
- Coverage: 50%

### Filtering by Endpoint Category

```bash
# Repository management endpoints
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT DISTINCT url FROM interactions WHERE url LIKE '%/repositories%';"

# Security endpoints
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT DISTINCT url FROM interactions WHERE url LIKE '%/security%';"

# Component/asset endpoints
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT DISTINCT url FROM interactions WHERE url LIKE '%/components%' OR url LIKE '%/assets%';"

# Search endpoints
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT DISTINCT url FROM interactions WHERE url LIKE '%/search%';"
```

## JaCoCo - Code Coverage ❌ NOT APPLICABLE

### Why JaCoCo Doesn't Work

**JaCoCo is NOT compatible** with the Nexus pre-built Docker image:

1. **Pre-built Docker Image**
   - Nexus distributed as official Docker image (`sonatype/nexus3:3.85.0`)
   - Image built by Sonatype with optimizations
   - No source code included
   - No instrumentation hooks

2. **OSGi/Karaf Architecture**
   - 100+ OSGi bundles loaded dynamically
   - Apache Karaf container manages classloading
   - Complex dependency injection (Eclipse Sisu)
   - JaCoCo requires bytecode instrumentation at load time

3. **No Access to JVM Startup**
   - Image startup script (`/opt/sonatype/nexus/bin/nexus`) is pre-configured
   - JaCoCo agent requires `-javaagent:jacocoagent.jar` JVM argument
   - Official image doesn't expose JVM configuration
   - Modifying startup breaks Sonatype support

### JaCoCo Requirements vs Nexus Reality

| Requirement | JaCoCo Needs | Nexus Reality | Compatible? |
|-------------|-------------|---------------|-------------|
| Source code | Optional (for reports) | Not in image | ⚠️ |
| Class files | Required (instrumentation) | Inside OSGi bundles | ❌ |
| JVM agent | Required (runtime) | No access to JVM args | ❌ |
| Build process | Ideal (compile-time) | Pre-built image | ❌ |
| Classloading | Standard Java | OSGi dynamic loading | ❌ |

### Why JaCoCo Files Are Present

The JaCoCo JARs and scripts exist in this directory for **RESTgym template consistency**:
- All RESTgym API directories follow the same structure
- JaCoCo is applicable for source-built APIs (FlightSearchAPI, etc.)
- Nexus is an exception due to pre-built image architecture

**DO NOT attempt to use JaCoCo with Nexus** - it will not work.

### Alternative: HTTP Endpoint Coverage

Since code coverage is not possible, use **HTTP endpoint coverage** as a metric:

#### What to Measure

1. **Endpoint Coverage**
   - Total endpoints: 300+ (from OpenAPI spec)
   - Tested endpoints: Count unique URLs in interactions.db
   - Coverage = (Tested / Total) × 100%

2. **HTTP Method Coverage**
   - GET, POST, PUT, DELETE, PATCH operations
   - Different methods on same endpoint = different coverage

3. **Status Code Coverage**
   - 2xx success responses
   - 4xx client errors (validation testing)
   - 5xx server errors (robustness testing)

4. **Category Coverage**
   - Repository management (80+ endpoints)
   - Security (70+ endpoints)
   - Components/assets (30+ endpoints)
   - System/monitoring (30+ endpoints)
   - Tasks/automation (15+ endpoints)
   - Blob stores (20+ endpoints)

#### SQL Queries for Coverage

```sql
-- Endpoint coverage
SELECT COUNT(DISTINCT url) as unique_endpoints FROM interactions;

-- Method distribution
SELECT method, COUNT(*) as count 
FROM interactions 
GROUP BY method;

-- Category coverage (repositories)
SELECT COUNT(DISTINCT url) as repository_endpoints 
FROM interactions 
WHERE url LIKE '%/repositories%';

-- Category coverage (security)
SELECT COUNT(DISTINCT url) as security_endpoints 
FROM interactions 
WHERE url LIKE '%/security%';

-- Status code coverage
SELECT 
  CASE 
    WHEN status_code BETWEEN 200 AND 299 THEN '2xx Success'
    WHEN status_code BETWEEN 300 AND 399 THEN '3xx Redirect'
    WHEN status_code BETWEEN 400 AND 499 THEN '4xx Client Error'
    WHEN status_code BETWEEN 500 AND 599 THEN '5xx Server Error'
    ELSE 'Unknown'
  END as category,
  COUNT(*) as count
FROM interactions
GROUP BY category;

-- Unique method+URL combinations (most detailed coverage)
SELECT DISTINCT method || ' ' || url as endpoint
FROM interactions
ORDER BY endpoint;
```

## RESTgym Integration

### Environment Variables

```bash
docker run \
  -e API=nexus \          # API identifier
  -e TOOL=deeprest \      # Testing tool (manual, deeprest, restler, etc.)
  -e RUN=1 \              # Run number
  ...
```

### Results Directory Structure

```
/results/
└── nexus/
    └── $TOOL/
        └── $RUN/
            ├── interactions.db    # mitmproxy SQLite database
            ├── nexus.log         # Nexus startup/runtime logs
            └── *.exec            # (empty - JaCoCo not applicable)
```

### Accessing Results

```bash
# Copy interactions database to host
docker cp nexus-restgym:/results/nexus/manual/1/interactions.db ./

# View with SQLite browser
sqlite3 interactions.db

# Or use DB Browser for SQLite (GUI)
```

## Testing Workflow

### 1. Start Container

```bash
docker run -d \
  --name nexus-restgym \
  -p 9090:9090 \
  -e API=nexus \
  -e TOOL=manual \
  -e RUN=1 \
  nexus:restgym
```

### 2. Wait for Startup

```bash
# Wait 90-120 seconds
sleep 120

# Verify Nexus is ready
curl http://localhost:9090/service/rest/v1/status
```

### 3. Run Tests

```bash
# Get admin password
ADMIN_PASS=$(docker exec nexus-restgym cat /opt/sonatype/sonatype-work/nexus3/admin.password)

# Test API endpoints (via mitmproxy port 9090)
curl -u admin:$ADMIN_PASS http://localhost:9090/service/rest/v1/repositories
curl -u admin:$ADMIN_PASS http://localhost:9090/service/rest/v1/security/users
curl -u admin:$ADMIN_PASS http://localhost:9090/service/rest/v1/search
# ... more tests
```

All requests are automatically captured in `interactions.db`.

### 4. Analyze Results

```bash
# Check database size
docker exec nexus-restgym ls -lh /results/nexus/manual/1/interactions.db

# Query coverage
docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
  "SELECT COUNT(*) as total_requests, 
          COUNT(DISTINCT url) as unique_endpoints,
          COUNT(DISTINCT method) as methods_used
   FROM interactions;"

# Export results
docker cp nexus-restgym:/results/nexus/manual/1/interactions.db ./nexus-interactions.db
```

### 5. Cleanup

```bash
docker stop nexus-restgym
docker rm nexus-restgym
```

## Tools & Dependencies

### Installed in Container

- **Python 3** - mitmproxy runtime
- **mitmproxy** - HTTP interception (pip3 install mitmproxy)
- **SQLite 3** - Database for interactions
- **curl** - HTTP client for health checks
- **nc** (netcat) - Network testing

### Installation (already in Dockerfile)

```dockerfile
RUN yum install -y python3 python3-pip nc procps findutils
RUN pip3 install --no-cache-dir mitmproxy
```

## Troubleshooting

### mitmproxy Issues

**Problem**: Requests not captured in interactions.db

**Solutions**:
1. Verify mitmproxy is running:
   ```bash
   docker exec nexus-restgym ps aux | grep mitmdump
   ```

2. Check mitmproxy logs:
   ```bash
   docker logs nexus-restgym | grep mitmdump
   ```

3. Test mitmproxy directly:
   ```bash
   curl http://localhost:9090/service/rest/v1/status
   ```

4. Verify database exists:
   ```bash
   docker exec nexus-restgym ls -lh /results/nexus/manual/1/
   ```

**Problem**: Port 9090 connection refused

**Solutions**:
1. Check port mapping:
   ```bash
   docker port nexus-restgym
   ```

2. Verify Nexus started:
   ```bash
   docker logs nexus-restgym | grep "Started Sonatype Nexus"
   ```

3. Wait longer (90-120 seconds for full startup)

### Database Issues

**Problem**: interactions.db is empty

**Solutions**:
1. Verify Python script loaded:
   ```bash
   docker exec nexus-restgym cat /infrastructure/mitmproxy/store-interactions.py
   ```

2. Check SQLite permissions:
   ```bash
   docker exec nexus-restgym ls -la /results/nexus/manual/1/
   ```

3. Test database manually:
   ```bash
   docker exec nexus-restgym sqlite3 /results/nexus/manual/1/interactions.db \
     "SELECT COUNT(*) FROM interactions;"
   ```

**Problem**: Cannot query database

**Solutions**:
1. Install SQLite on host:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install sqlite3
   
   # macOS
   brew install sqlite3
   
   # Windows
   choco install sqlite
   ```

2. Copy database to host first:
   ```bash
   docker cp nexus-restgym:/results/nexus/manual/1/interactions.db ./
   sqlite3 interactions.db "SELECT * FROM interactions LIMIT 5;"
   ```

### Performance Issues

**Problem**: Container using excessive CPU/memory

**Solutions**:
1. Limit mitmproxy capture (large response bodies):
   - Modify `store-interactions.py` to truncate bodies
   - Set maximum body size

2. Monitor resource usage:
   ```bash
   docker stats nexus-restgym
   ```

3. Increase container limits:
   ```bash
   docker run --memory=4g --cpus=2 ...
   ```

## Logs

View logs for debugging:

```bash
# Combined logs (Nexus + mitmproxy)
docker logs nexus-restgym

# Follow logs
docker logs nexus-restgym -f

# Last 100 lines
docker logs nexus-restgym --tail 100

# Nexus application log
docker exec nexus-restgym cat /results/nexus/manual/1/nexus.log

# mitmproxy errors
docker logs nexus-restgym | grep -i error | grep -i mitmproxy
```

## Summary

| Tool | Status | Purpose | Output |
|------|--------|---------|--------|
| **mitmproxy** | ✅ Functional | HTTP interception | interactions.db (SQLite) |
| **JaCoCo** | ❌ Not applicable | Code coverage | N/A (pre-built image) |

**Recommendation**: Focus on HTTP endpoint coverage via mitmproxy as the primary testing metric for Nexus.

---

**Complete HTTP interception** with comprehensive SQLite database for RESTgym analysis

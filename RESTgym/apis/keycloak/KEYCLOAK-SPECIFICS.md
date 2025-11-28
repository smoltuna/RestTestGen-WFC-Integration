# Keycloak-Specific Considerations for RESTgym

This document explains why Keycloak differs from other RESTgym APIs and what limitations exist.

## 🚨 Critical Difference: Quarkus Native Compilation

Keycloak 23.0.7 uses **Quarkus 3.15.1 with native compilation**, making it fundamentally different from traditional Java applications.

## What This Means

### Traditional Spring Boot API (e.g., FlightSearchAPI)
```
Source Code (.java)
    ↓ Compilation
Bytecode (.class files)
    ↓ Packaging
JAR file (contains .class files)
    ↓ Runtime
JVM loads bytecode → JaCoCo can instrument
```

### Keycloak (Quarkus Native)
```
Source Code (.java)
    ↓ Native Compilation
Machine Code (native binary)
    ↓ Packaging
Docker image (contains native executable)
    ↓ Runtime
CPU executes directly → JaCoCo CANNOT instrument
```

## RESTgym Feature Compatibility

| Feature | Traditional APIs | Keycloak | Status |
|---------|------------------|----------|--------|
| **JAR file** | ✅ Available | ❌ No JAR (native binary only) | **Not Available** |
| **.class files** | ✅ Extractable | ❌ Compiled to machine code | **Not Available** |
| **JaCoCo coverage** | ✅ Works | ❌ Incompatible with native | **Not Applicable** |
| **mitmproxy** | ✅ Works | ✅ Works perfectly | **Fully Functional** |
| **SQLite interactions** | ✅ Works | ✅ Works perfectly | **Fully Functional** |
| **OpenAPI spec** | ✅ Auto-generated | ⚠️ Community-maintained | **Available but external** |
| **Database init** | ✅ schema.sql | ⚠️ H2 auto-creates | **Automatic + script provided** |
| **HTTP endpoint coverage** | ✅ Works | ✅ Works (primary metric) | **Fully Functional** |

## Why These Decisions Were Made

### 1. No JAR File

**Question**: Can we build Keycloak from source to get a JAR?

**Answer**: No, even building from source produces a native binary.

Keycloak maintainers made this decision because:
- **Faster startup**: ~20 seconds vs 60+ seconds for JVM
- **Lower memory**: ~200MB vs 500MB+ for JVM
- **Container optimization**: Smaller images, faster cloud deployment
- **Cloud-native**: Designed for Kubernetes/containerized environments

### 2. JaCoCo Not Applicable

**Question**: Can we use a JVM-based Keycloak build?

**Answer**: Theoretically yes, but:
- Not officially supported by Keycloak team for production
- Would require rebuilding from source with different configuration
- Defeats the purpose of using official Keycloak image
- Not representative of real-world Keycloak deployments

**RESTgym Decision**: Use official image, document limitation clearly

### 3. Community-Maintained OpenAPI Spec

**Question**: Why doesn't Keycloak expose `/openapi.json`?

**Answer**: Keycloak team's design decision:
- Admin REST API is documented in official docs
- Community maintains OpenAPI spec at github.com/ccouzens/keycloak-openapi
- Spec is 95% accurate, maintained by active contributors
- Used by many testing tools and automation frameworks

## Alternative Metrics for Code Coverage

Since JaCoCo is impossible, we provide **HTTP endpoint coverage**:

### What We Can Measure

1. **Endpoint Coverage** (primary metric)
   ```sql
   SELECT COUNT(DISTINCT url) * 100.0 / 208 as coverage_pct
   FROM interactions;
   ```

2. **HTTP Method Coverage**
   ```sql
   SELECT method, COUNT(DISTINCT url) as endpoints
   FROM interactions
   GROUP BY method;
   ```

3. **Status Code Distribution**
   ```sql
   SELECT status_code, COUNT(*) as count
   FROM interactions
   GROUP BY status_code;
   ```

4. **Admin API Category Coverage**
   ```sql
   SELECT 
     CASE
       WHEN url LIKE '%/realms%' THEN 'Realms'
       WHEN url LIKE '%/users%' THEN 'Users'
       WHEN url LIKE '%/clients%' THEN 'Clients'
       WHEN url LIKE '%/roles%' THEN 'Roles'
       WHEN url LIKE '%/groups%' THEN 'Groups'
       ELSE 'Other'
     END as category,
     COUNT(*) as requests
   FROM interactions
   GROUP BY category;
   ```

### What We Cannot Measure

❌ **Line coverage**: Which lines of code were executed  
❌ **Branch coverage**: Which code branches were taken  
❌ **Method coverage**: Which Java methods were called  
❌ **Class coverage**: Which Java classes were loaded  

These metrics require JVM bytecode instrumentation, which is incompatible with native compilation.

## Database Initialization

Unlike traditional RESTgym APIs with `schema.sql` and `data.sql`:

### Keycloak Approach

1. **Automatic Schema Creation**: H2 auto-creates 100+ tables on first startup
2. **Admin User from ENV**: `KEYCLOAK_ADMIN` / `KEYCLOAK_ADMIN_PASSWORD`
3. **Manual Test Data**: Provided script `/database/init-keycloak.sh`

### Why This Way?

- Keycloak manages its own schema (Liquibase migrations)
- Schema varies by version and features enabled
- Manual SQL would break on version upgrades
- More reliable to use Keycloak Admin API for test data

### Using the Init Script

```bash
# Start container
docker run -d --name keycloak-restgym \
  -p 9090:9090 -p 8080:8080 \
  -e API=keycloak -e TOOL=manual -e RUN=1 \
  keycloak:restgym

# Wait for startup (45-60 seconds)
sleep 60

# Initialize test data
docker exec keycloak-restgym bash /database/init-keycloak.sh
```

This creates:
- Test realm: `test-realm`
- Test client: `restgym-client` (secret: `restgym-secret`)
- 5 test users (admin, testuser, john.doe, jane.smith, disableduser)
- 5 test roles
- 4 test groups
- Sample identity provider
- Sample authentication flow

## Comparison with Other RESTgym APIs

| Aspect | FlightSearchAPI | Cassandra Mgmt | Keycloak |
|--------|-----------------|----------------|----------|
| **Framework** | Spring Boot | Micronaut | Quarkus Native |
| **Packaging** | JAR | JAR | Native binary |
| **JaCoCo** | ✅ Full support | ✅ Full support | ❌ Not compatible |
| **OpenAPI** | ✅ Auto-generated | ✅ Auto-generated | ⚠️ Community-maintained |
| **Database** | PostgreSQL | Cassandra | H2 (auto-init) |
| **Schema** | schema.sql | CQL scripts | Auto-created |
| **Test Data** | data.sql | CQL scripts | init-keycloak.sh |
| **Startup** | ~30 seconds | ~45 seconds | ~50 seconds |
| **Coverage Metric** | JaCoCo code % | JaCoCo code % | HTTP endpoint % |

## Recommendations for RESTgym Testing

### 1. Focus on HTTP Endpoint Coverage

Since code coverage is unavailable, prioritize:
- ✅ Testing all 208 Admin API endpoints
- ✅ Testing different HTTP methods (GET, POST, PUT, DELETE)
- ✅ Testing error responses (4xx, 5xx)
- ✅ Testing authentication flows

### 2. Use Provided Test Data

Run the initialization script to get realistic test environment:
```bash
docker exec keycloak-restgym bash /database/init-keycloak.sh
```

### 3. Track Interactions via mitmproxy

Always access API via port 9090 (not 8080) to ensure mitmproxy captures all traffic:
```bash
# ✅ Good - captured by mitmproxy
curl http://localhost:9090/admin/realms -H "Authorization: Bearer $TOKEN"

# ❌ Bad - bypasses mitmproxy
curl http://localhost:8080/admin/realms -H "Authorization: Bearer $TOKEN"
```

### 4. Analyze Coverage with SQL

Use provided SQL queries to understand testing coverage:
```bash
# How many unique endpoints were tested?
docker exec keycloak-restgym sqlite3 /results/keycloak/manual/1/interactions.db \
  "SELECT COUNT(DISTINCT url) FROM interactions;"

# Coverage percentage (208 total endpoints)
docker exec keycloak-restgym sqlite3 /results/keycloak/manual/1/interactions.db \
  "SELECT ROUND(COUNT(DISTINCT url) * 100.0 / 208, 2) || '%' as coverage 
   FROM interactions;"
```

### 5. Expect Frequent Token Refreshes

Keycloak tokens expire after 60 seconds by default:
```bash
# Get new token before each test sequence
get_token() {
  curl -s -X POST http://localhost:9090/realms/master/protocol/openid-connect/token \
    -d "username=admin&password=admin&grant_type=password&client_id=admin-cli" \
    | jq -r '.access_token'
}

TOKEN=$(get_token)
```

## Summary

### ✅ What Works with Keycloak

- Official Docker image with full functionality
- mitmproxy HTTP interception
- SQLite interactions database
- 208 Admin REST API endpoints
- H2 auto-initialization
- Test data initialization script
- HTTP endpoint coverage tracking

### ❌ What Doesn't Work (and Why)

- **No JAR file**: Quarkus compiles to native binary
- **No .class files**: Code compiled to machine code
- **No JaCoCo**: Incompatible with native compilation
- **No auto-generated OpenAPI**: Design decision by Keycloak team

### 🎯 Testing Strategy

1. Use mitmproxy to capture HTTP interactions ✅
2. Track endpoint coverage via SQLite queries ✅
3. Focus on functional testing (not code coverage) ✅
4. Use init script to create realistic test data ✅
5. Accept that this is a **different but valid** approach ✅

## References

- **Quarkus Native**: https://quarkus.io/guides/building-native-image
- **Why native compilation**: https://www.keycloak.org/2023/03/native-keycloak
- **JaCoCo limitations**: https://www.eclemma.org/jacoco/trunk/doc/implementation.html
- **Community OpenAPI**: https://github.com/ccouzens/keycloak-openapi

---

**Conclusion**: Keycloak's Quarkus native architecture is a **feature, not a bug**. It provides faster startup and lower memory usage at the cost of traditional Java tooling compatibility. RESTgym adaptations maintain full testing capability through HTTP endpoint tracking instead of code coverage.

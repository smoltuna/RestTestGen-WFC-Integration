# Keycloak Classes

## ⚠️ IMPORTANT: No JAR/Classes Available

Keycloak 23.0.7 is built on **Quarkus 3.15.1**, which uses **native compilation** - fundamentally different from traditional Java applications.

## Why No JAR/Classes

Unlike traditional Spring Boot applications that ship with `.jar` files and `.class` files:

### Keycloak Architecture:
1. **Quarkus Native Binary** - NOT a JAR file
   - Compiled to native machine code (like C/C++)
   - Located at `/opt/keycloak/bin/kc.sh` (native executable)
   - No `.jar` file exists in the distribution

2. **No Extractable Classes**
   - Classes are compiled directly to machine code
   - Not stored as Java `.class` files
   - Cannot be extracted or inspected like traditional JARs

3. **Official Docker Image**
   - Pre-built by Keycloak team
   - Contains only native binaries
   - Source code not included

### What This Means for RESTgym:

❌ **Cannot use JaCoCo** - Requires JVM bytecode, not compatible with native images  
❌ **No .jar file** - Only native binary exists  
❌ **No .class files** - Code compiled to machine code, not bytecode  
❌ **No Java agent support** - Native images don't support Java agents  

✅ **CAN use mitmproxy** - HTTP interception works perfectly  
✅ **CAN track API coverage** - Via HTTP endpoint monitoring  
✅ **CAN analyze interactions** - Via SQLite database  

This is **NOT a configuration issue** - it's a fundamental architectural difference of Quarkus native compilation.

## Keycloak Architecture

Keycloak uses:
- **Quarkus framework** - Fast startup, low memory
- **RESTEasy Reactive** - REST endpoints
- **Hibernate ORM** - Database access
- **SmallRye JWT** - Token handling
- **Infinispan** - Caching

## Code Coverage Alternatives

Since JaCoCo is **impossible** with Quarkus native, use these alternatives:

### 1. HTTP Endpoint Coverage (via mitmproxy)
```sql
-- Check which endpoints were tested
SELECT DISTINCT method, url, COUNT(*) as hits
FROM interactions
GROUP BY method, url
ORDER BY hits DESC;

-- Calculate coverage percentage
SELECT 
  COUNT(DISTINCT url) as tested_endpoints,
  208 as total_endpoints,
  ROUND(COUNT(DISTINCT url) * 100.0 / 208, 2) as coverage_percentage
FROM interactions;
```

### 2. Status Code Distribution
```sql
-- Analyze response codes
SELECT status_code, COUNT(*) as count
FROM interactions
GROUP BY status_code
ORDER BY count DESC;
```

### 3. Keycloak Event Logs
```bash
# Get user events
curl http://localhost:9090/admin/realms/test-realm/events \
  -H "Authorization: Bearer $TOKEN"

# Get admin events
curl http://localhost:9090/admin/realms/test-realm/admin-events \
  -H "Authorization: Bearer $TOKEN"
```

### 4. Prometheus Metrics
```bash
# Built-in Keycloak metrics
curl http://localhost:8080/metrics
```

These alternatives provide **functional coverage** (which endpoints were called) instead of **code coverage** (which lines were executed).

## Source Code

If you need to inspect Keycloak classes:
- **GitHub**: https://github.com/keycloak/keycloak/tree/23.0.7
- **Main packages**:
  - `org.keycloak.services.resources.admin.*` - Admin REST API
  - `org.keycloak.protocol.oidc.*` - OIDC endpoints
  - `org.keycloak.protocol.saml.*` - SAML endpoints
  - `org.keycloak.authentication.*` - Authentication flows

## RESTgym Adaptation

For RESTgym testing with Keycloak:
- ✅ HTTP interception via mitmproxy works
- ✅ SQLite interactions database works
- ❌ JaCoCo code coverage not applicable
- ✅ API specification coverage via OpenAPI

This is a limitation of Quarkus native images, not a missing configuration.

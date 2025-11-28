# Nexus Classes

## Important Note

Sonatype Nexus Repository Manager is distributed as a **pre-built Docker image** by Sonatype.

## Why No Classes Directory

Unlike typical RESTgym Java APIs:

1. **Official Docker Image** - Pre-built by Sonatype with all dependencies included
2. **Proprietary Build** - Source code available but complex multi-module Maven build
3. **OSGi/Karaf Runtime** - Uses Apache Karaf container with OSGi bundles
4. **No Standard JAR** - Application packaged as Karaf feature files, not single JAR

### Nexus Architecture

Nexus uses a complex architecture:
- **Apache Karaf** - OSGi runtime container
- **Eclipse Sisu** - Dependency injection framework
- **OrientDB/H2** - Embedded databases
- **Elasticsearch** - Search engine
- **Jetty** - Embedded web server
- **100+ OSGi bundles** - Modular architecture

### Code Coverage Alternative

For Nexus testing, instead of JaCoCo:
- ✅ **HTTP endpoint coverage** via mitmproxy (300+ REST API endpoints)
- ✅ **Status code distribution** analysis
- ✅ **API usage patterns** tracking
- ❌ **JaCoCo code coverage** - Not applicable for pre-built image

### Source Code

If you need to inspect Nexus source code:
- **GitHub**: https://github.com/sonatype/nexus-public
- **License**: Eclipse Public License 1.0
- **Build**: Complex multi-module Maven project (requires Sonatype infrastructure)

**Main packages**:
- `org.sonatype.nexus.repository.*` - Repository management
- `org.sonatype.nexus.security.*` - Security and authentication
- `org.sonatype.nexus.blobstore.*` - Blob storage
- `org.sonatype.nexus.rest.*` - REST API endpoints

### Building from Source (Advanced)

If you need to build Nexus from source:

```bash
# Clone repository
git clone https://github.com/sonatype/nexus-public.git
cd nexus-public

# Checkout release tag
git checkout release-3.85.0-03

# Build (requires Java 17+)
./mvnw clean install -Dpublic

# Extract classes (NOT recommended for RESTgym)
unzip -d target assemblies/nexus-base-template/target/nexus-base-template-*.zip
```

⚠️ **Note**: Building from source is **not necessary** for RESTgym testing. The official Docker image is sufficient.

### RESTgym Adaptation

For RESTgym testing with Nexus:
- ✅ HTTP interception via mitmproxy works
- ✅ SQLite interactions database works
- ❌ JaCoCo code coverage not applicable (pre-built image)
- ✅ API specification coverage via OpenAPI (300+ endpoints)

### Alternative Metrics

Since code coverage is unavailable, focus on:

#### 1. HTTP Endpoint Coverage
```sql
-- Count unique endpoints tested
SELECT COUNT(DISTINCT url) FROM interactions;

-- List tested endpoints
SELECT DISTINCT method || ' ' || url FROM interactions ORDER BY url;
```

#### 2. Status Code Distribution
```sql
SELECT status_code, COUNT(*) as count
FROM interactions
GROUP BY status_code
ORDER BY count DESC;
```

#### 3. API Category Coverage
```sql
SELECT 
  CASE
    WHEN url LIKE '%/repositories%' THEN 'Repositories'
    WHEN url LIKE '%/components%' THEN 'Components'
    WHEN url LIKE '%/assets%' THEN 'Assets'
    WHEN url LIKE '%/security%' THEN 'Security'
    WHEN url LIKE '%/blobstores%' THEN 'Blob Stores'
    WHEN url LIKE '%/tasks%' THEN 'Tasks'
    ELSE 'Other'
  END as category,
  COUNT(*) as requests
FROM interactions
GROUP BY category;
```

## Important Notes

- 🐳 **Docker-based** - Uses official `sonatype/nexus3` image
- 📦 **OSGi bundles** - Not traditional JAR structure
- ❌ **No extractable classes** - Complex Karaf runtime
- ✅ **300+ REST API endpoints** - Comprehensive API coverage available
- 🔧 **Complex build** - Requires Sonatype infrastructure for full build

## RESTgym Testing Strategy

1. ✅ Use mitmproxy to capture HTTP interactions
2. ✅ Track endpoint coverage via SQLite queries (300+ endpoints)
3. ✅ Focus on functional testing (not code coverage)
4. ✅ Test all major API categories (repositories, components, security, etc.)

This is a **valid approach** for testing pre-built Docker images where source code access is limited.

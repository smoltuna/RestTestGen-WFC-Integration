# Keycloak JVM Build for RESTgym Integration

## Overview
This document explains how Keycloak was built in JVM mode to enable JaCoCo code coverage integration with RESTgym. The original Keycloak setup used Quarkus native compilation which produces a native binary without Java bytecode, making it incompatible with JaCoCo.

## Why JVM Build Was Necessary

### Problem
- **Native Compilation**: Keycloak by default uses Quarkus native compilation (GraalVM)
- **No Bytecode**: Native binaries don't contain .class files or JAR files
- **JaCoCo Incompatibility**: JaCoCo requires Java bytecode (.class files) to instrument and measure code coverage
- **RESTgym Requirement**: RESTgym's testing infrastructure relies on JaCoCo for collecting coverage metrics

### Solution
Build Keycloak in **JVM mode** using Quarkus's `uber-jar` packaging type to produce:
1. Standard JAR files with bytecode
2. Extractable .class files for JaCoCo instrumentation
3. Full Java runtime compatibility

## Build Process

### 1. Clone Keycloak Source
```bash
cd /home/simone/work/temp
git clone https://github.com/keycloak/keycloak.git
cd keycloak
```

### 2. Build Keycloak Dependencies
```bash
./mvnw -f pom.xml clean install -DskipTestsuite -DskipExamples -DskipTests -Dmaven.javadoc.skip=true -T 2C
```

**Parameters:**
- `-DskipTestsuite`: Skip integration test suite (faster build)
- `-DskipExamples`: Skip example projects
- `-DskipTests`: Skip unit tests
- `-Dmaven.javadoc.skip=true`: Skip JavaDoc generation
- `-T 2C`: Use parallel builds (2 threads per CPU core)

**Build Time:** ~3-4 minutes on modern hardware

### 3. Build Quarkus Distribution in JVM Mode
```bash
cd quarkus/dist
mvn clean package -DskipTests -Dquarkus.package.jar.type=uber-jar
```

**Critical Parameter:**
- `-Dquarkus.package.jar.type=uber-jar`: Forces JVM packaging instead of native compilation

**Output Location:** `quarkus/dist/target/keycloak-999.0.0-SNAPSHOT.zip`

### 4. Extract Distribution
```bash
cd quarkus/dist/target
unzip -q keycloak-999.0.0-SNAPSHOT.zip
cd keycloak-999.0.0-SNAPSHOT
```

**Distribution Structure:**
```
keycloak-999.0.0-SNAPSHOT/
├── bin/                          # Startup scripts (kc.sh, kcadm.sh)
├── conf/                         # Configuration files
├── lib/
│   ├── app/
│   │   └── keycloak.jar         # Main application JAR (manifest only)
│   ├── quarkus/
│   │   ├── transformed-bytecode.jar   # Keycloak .class files (129 classes)
│   │   ├── generated-bytecode.jar     # Keycloak .class files (1116 classes)
│   │   └── quarkus-run.jar            # Quarkus runner
│   └── lib/main/                # Third-party dependencies
├── providers/                    # Keycloak provider JARs
└── themes/                       # UI themes
```

### 5. Extract .class Files
```bash
mkdir -p extracted-classes
cd extracted-classes
jar xf ../lib/quarkus/transformed-bytecode.jar
jar xf ../lib/quarkus/generated-bytecode.jar
```

**Result:** 1116 Keycloak .class files in `org/keycloak/` directory structure

### 6. Copy to RESTgym Structure
```bash
cd /home/simone/work/Tesi-RESTAPI/RESTgym/apis
mkdir -p keycloak/{classes,dictionaries,database,specifications}

# Copy .class files
cp -r extracted-classes/org keycloak/classes/

# Copy full distribution
cp -r lib keycloak/
cp -r conf keycloak/
cp -r bin keycloak/
cp -r providers keycloak/
cp -r themes keycloak/

# Copy OpenAPI specification
cp /home/simone/work/Tesi-RESTAPI/OAS/keycloak-openapi-23.0.7.json keycloak/specifications/keycloak-openapi.json

# Create placeholder dictionary
echo '{}' > keycloak/dictionaries/keycloak-llm.json
```

## Docker Integration

### Dockerfile Structure
The Dockerfile follows the RESTgym template pattern used by `realworld-backend-micronaut`:

```dockerfile
FROM ubuntu:22.04

ENV API=keycloak

# Install Java 17 and mitmproxy
RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk mitmproxy && \
    apt -y autoremove

# Copy Keycloak and infrastructure
COPY ./apis/keycloak/ /api/
COPY ./infrastructure/ /infrastructure/

# Keycloak environment
ENV JAVA_OPTS="-Xms256m -Xmx2048m"
ENV KC_HOME_DIR=/api
ENV KC_CONF_DIR=/api/conf

# Start with JaCoCo agent, MITM proxy, and Keycloak
CMD mkdir -p /results/$API/$TOOL/$RUN && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.keycloak.*,output=tcpserver,port=12345,address=* \
    $JAVA_OPTS \
    -Dkc.home.dir=$KC_HOME_DIR \
    -Djboss.server.config.dir=$KC_CONF_DIR \
    -Djava.util.logging.manager=org.jboss.logmanager.LogManager \
    -Dpicocli.disable.closures=true \
    -Dquarkus-log-max-startup-records=10000 \
    -Djava.util.concurrent.ForkJoinPool.common.threadFactory=io.quarkus.bootstrap.forkjoin.QuarkusForkJoinWorkerThreadFactory \
    -cp /api/lib/quarkus-run.jar \
    io.quarkus.bootstrap.runner.QuarkusEntryPoint start-dev --http-port=8080
```

### Key Components

#### 1. JaCoCo Agent
```bash
-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.keycloak.*,output=tcpserver,port=12345,address=*
```
- **includes=org.keycloak.***: Only instrument Keycloak classes (not dependencies)
- **output=tcpserver,port=12345**: JaCoCo agent listens for coverage collection requests
- **address=***: Accept connections from any IP (needed for Docker networking)

#### 2. MITM Proxy
```bash
mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py
```
- Intercepts HTTP requests on port 9090
- Forwards to Keycloak on localhost:8080
- Stores interactions in SQLite database for RESTgym analysis

#### 3. Coverage Collection
```bash
sh /infrastructure/jacoco/collect-coverage-interval.sh &
```
- Runs in background
- Collects coverage snapshots every 5 seconds
- Generates `jacoco_*.exec` and `jacoco_*.csv` files

#### 4. Quarkus Entry Point
```bash
java -cp /api/lib/quarkus-run.jar io.quarkus.bootstrap.runner.QuarkusEntryPoint start-dev --http-port=8080
```
- Uses Quarkus bootstrap runner
- Starts in development mode (`start-dev`)
- Listens on port 8080

## Build and Run

### Build Docker Image
```bash
cd /home/simone/work/Tesi-RESTAPI/RESTgym
docker build -t restgym/keycloak -f apis/keycloak/Dockerfile .
```

**Build Time:** ~1-2 minutes  
**Image Size:** ~1.03 GB

### Run with RESTgym
```bash
cd /home/simone/work/Tesi-RESTAPI/RESTgym
docker run -it --rm \
  -v $(pwd)/results:/results \
  -e TOOL=schemathesis \
  -e RUN=run1 \
  -p 8080:8080 \
  -p 9090:9090 \
  restgym/keycloak
```

**Environment Variables:**
- `TOOL`: Testing tool name (e.g., schemathesis, resttestgen, deeprest)
- `RUN`: Run identifier for this test execution

**Port Mappings:**
- `8080`: Keycloak HTTP API
- `9090`: MITM proxy (for testing tools)

### Results Structure
After running, results are stored in:
```
results/
└── keycloak/
    └── {TOOL}/
        └── {RUN}/
            ├── jacoco_0.exec           # JaCoCo coverage data
            ├── jacoco_0.csv            # Coverage metrics (line/branch)
            ├── jacoco_1.exec
            ├── jacoco_1.csv
            └── results.db              # SQLite: HTTP interactions
```

## Verification

### Check .class Files
```bash
find /home/simone/work/Tesi-RESTAPI/RESTgym/apis/keycloak/classes -name "*.class" | wc -l
```
**Expected:** 1116 files

### Check JAR Structure
```bash
ls -lh /home/simone/work/Tesi-RESTAPI/RESTgym/apis/keycloak/lib/quarkus/
```
**Expected Files:**
- `transformed-bytecode.jar`
- `generated-bytecode.jar`
- `quarkus-run.jar`

### Test JaCoCo Compatibility
```bash
# Extract and verify a sample class
cd /tmp
jar xf /home/simone/work/Tesi-RESTAPI/RESTgym/apis/keycloak/lib/quarkus/transformed-bytecode.jar
file org/keycloak/models/KeycloakSession.class
```
**Expected:** `Java class file, version 61.0 (Java 17)`

## Comparison: Native vs JVM Build

| Aspect | Native Build | JVM Build (This Approach) |
|--------|--------------|---------------------------|
| **Compilation** | GraalVM ahead-of-time (AOT) | Standard JVM bytecode |
| **Startup Time** | ~50ms | ~2-3s |
| **Memory Usage** | Lower (~200MB) | Higher (~512MB) |
| **JAR Files** | No | Yes (quarkus-run.jar) |
| **.class Files** | No (compiled to native) | Yes (1116 files) |
| **JaCoCo Support** | ❌ No | ✅ Yes |
| **Runtime Performance** | Faster after warmup | Standard JVM performance |
| **Image Size** | ~500MB | ~1.03GB |
| **RESTgym Compatible** | ❌ No | ✅ Yes |

## Troubleshooting

### Issue: "No bytecode found"
**Cause:** Native build was used instead of JVM mode  
**Solution:** Ensure `-Dquarkus.package.jar.type=uber-jar` is set during Maven build

### Issue: JaCoCo shows 0% coverage
**Cause:** Incorrect includes filter or JaCoCo agent not attached  
**Solution:** Verify `includes=org.keycloak.*` in Dockerfile and check JaCoCo is listening:
```bash
docker exec -it <container_id> netstat -tlnp | grep 12345
```

### Issue: "Class not found" errors on startup
**Cause:** Missing dependencies or incorrect classpath  
**Solution:** Ensure all lib directories (lib/, conf/, providers/, themes/) were copied to RESTgym structure

### Issue: Keycloak fails to start
**Cause:** Missing configuration or wrong Java version  
**Solution:** Check Docker logs and verify Java 17 is installed:
```bash
docker run --rm restgym/keycloak java -version
```

## Rebuild Instructions

If you need to rebuild Keycloak (e.g., for a new version):

1. **Update source:**
   ```bash
   cd /home/simone/work/temp/keycloak
   git pull
   git checkout <version-tag>  # e.g., 26.0.0
   ```

2. **Clean and rebuild:**
   ```bash
   ./mvnw clean install -DskipTestsuite -DskipExamples -DskipTests -Dmaven.javadoc.skip=true -T 2C
   cd quarkus/dist
   mvn clean package -DskipTests -Dquarkus.package.jar.type=uber-jar
   ```

3. **Extract and copy:**
   Follow steps 4-6 from "Build Process" section above

4. **Rebuild Docker image:**
   ```bash
   cd /home/simone/work/Tesi-RESTAPI/RESTgym
   docker build -t restgym/keycloak -f apis/keycloak/Dockerfile .
   ```

## References

- **Keycloak GitHub:** https://github.com/keycloak/keycloak
- **Quarkus Packaging:** https://quarkus.io/guides/maven-tooling#building-uber-jars
- **JaCoCo Documentation:** https://www.jacoco.org/jacoco/trunk/doc/agent.html
- **RESTgym Template:** `/home/simone/work/RESTgym/apis/#api-template/README.md`
- **Realworld Example:** `/home/simone/work/RESTgym/apis/realworld-backend-micronaut/RESTGYM_README.md`

## Success Criteria

✅ **Build completed:**
- Maven build succeeded without errors
- JVM mode distribution created (not native)
- 1116 .class files extracted

✅ **Docker integration:**
- Image builds successfully (~1.03GB)
- JaCoCo agent attaches to Java process
- MITM proxy intercepts HTTP traffic
- Coverage data generated in /results

✅ **RESTgym compatibility:**
- Standard directory structure maintained
- Classes available for instrumentation
- OpenAPI spec and dictionaries present
- Results database populated with interactions

## Author Notes

This documentation was created as part of the RESTgym integration project. The key insight was recognizing that Quarkus native compilation, while excellent for production deployments, is incompatible with JaCoCo's bytecode instrumentation requirements. By forcing JVM mode with the uber-jar packaging type, we maintain all the benefits of standard Java runtime while enabling comprehensive code coverage analysis.

The approach follows the same pattern successfully used for `realworld-backend-micronaut`, ensuring consistency across the RESTgym testing infrastructure.

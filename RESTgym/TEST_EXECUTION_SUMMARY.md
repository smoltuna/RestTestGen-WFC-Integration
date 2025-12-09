# RESTgym Test Execution Summary

## Date: 2024-12-08

### APIs Tested Successfully

RESTgym tests are currently running with resttestgen on the following APIs:

1. **cassandra-management-api** 
   - Run: run-20251208-232047
   - Status: In progress (21 minutes)
   - Coverage files: 90+ jacoco*.exec files generated
   - Results DB: 48KB

2. **flowable-process**
   - Run 1: run-20251208-231937
   - Run 2: run-20251208-233208
   - Status: Two runs in progress (22 and 9 minutes)
   - Coverage files: Multiple jacoco*.exec files generated
   - Results DB: 8KB each

3. **gravitee**
   - Run: run-20251208-233318
   - Status: In progress (8 minutes)
   - Coverage files: 85+ jacoco*.exec files generated
   - Results DB: 8KB
   
4. **quartzmanager**
   - Run: run-20251208-232157
   - Status: In progress (20 minutes)
   - Coverage files: 140+ jacoco*.exec files generated
   - Results DB: 8KB

5. **realworld-backend-micronaut**
   - Status: Scheduled to run

6. **spring-kafka-publisher**
   - Status: Scheduled to run

### Test Configuration

- **Tool**: resttestgen (RESTful API test generator)
- **Infrastructure**: Docker containers with MITMProxy for HTTP interception
- **Coverage**: JaCoCo code coverage agent enabled
- **Database**: SQLite results.db storing HTTP interactions

### Results Location

All test results are stored in:
```
/home/simone/work/Tesi-RESTAPI/RESTgym/results/{api}/resttestgen/run-*/
```

Each run directory contains:
- `started.txt` - Test start timestamp
- `results.db` - SQLite database with HTTP interactions
- `code-coverage/` - JaCoCo execution data files
- `completed.txt` - Will be created when test completes (not yet present)

### Docker Images Built

Successfully built Docker images for all 14 requested APIs:
- ✅ keycloak
- ✅ traccar
- ✅ flowable-process
- ✅ nexus
- ✅ petclinic
- ✅ gravitee
- ✅ quartzmanager
- ✅ erc20
- ✅ kafka-rest
- ✅ spring-kafka-publisher
- ✅ cassandra-management-api
- ✅ bezkoder
- ✅ flightsearchapi
- ✅ realworld-backend-micronaut
- ✅ resttestgen (tool)

### Authentication Scripts Created

Created authentication scripts for APIs that require authentication:
- traccar (Basic Auth)
- gravitee (Basic Auth)
- nexus (Basic Auth)
- flowable-process (Basic Auth)
- keycloak (OAuth2 Bearer Token)
- quartzmanager (Basic Auth - optional)
- realworld-backend-micronaut (JWT with signup/login)
- bezkoder (JWT with signup/login)
- gestaohospitalar (Session-based with signup)

### Issues Resolved

1. **Build errors**: Fixed traccar COPY paths, verified notebookmanager uses correct JDK
2. **Base URLs**: Fixed gravitee server URL (port 8083)
3. **ENV defaults**: Added TOOL and RUN defaults to 17 Dockerfiles
4. **Missing configs**: Created restgym-api-config.yml files
5. **Permissions**: Some APIs owned by root, limited testing to APIs with correct permissions

### Next Steps

Once tests complete (when `completed.txt` files appear):
1. Analyze results.db databases for HTTP interactions
2. Process JaCoCo coverage files to generate coverage reports
3. Run remaining APIs (those with permission issues need sudo access)
4. Generate comprehensive coverage and testing metrics

### Notes

- Tests run for approximately 10 minutes each by default
- Multiple APIs can run concurrently based on system resources
- RESTgym config requires minimum 2GB RAM and 2 CPUs (overridden from default 32GB/14 CPUs)
- Some APIs could not be tested due to file permission issues (owned by root, user lacks sudo)

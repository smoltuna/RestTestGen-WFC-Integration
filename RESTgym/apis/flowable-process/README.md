# Flowable Process API

> Flowable BPMN Process Engine REST API containerized for RESTgym testing

This container includes the Flowable REST API (v7.0.1) with Process API (BPMN) and IDM API modules.

## How it works

- **Framework**: Spring Boot + Flowable Engine
- **Database**: H2 in-memory
- **Authentication**: Basic Auth (admin/test)
- **OpenAPI**: 2 specifications (Process API + IDM API)
- **Monitoring**: JaCoCo coverage + mitmproxy logging

## Directory Structure

```
flowable-process/
├── Dockerfile                          # Docker image configuration
├── restgym-api-config.yml             # RESTgym enablement flag
├── application.properties             # Flowable configuration
├── flowable-rest.war                  # Flowable REST application (85.3MB)
├── specifications/                     # OpenAPI specs
│   ├── flowable-process-openapi.yaml  # Process API spec (BPMN)
│   └── flowable-idm-api-openapi.yaml  # IDM API spec
├── classes/                            # Extracted .class files for JaCoCo
│   └── WEB-INF/classes/org/flowable/  # Flowable classes
├── dictionaries/                       # Fuzzing dictionaries
│   └── deeprest/
│       └── flowable-process.json       # Domain values (process IDs, task IDs, etc.)
├── database/                           # Database initialization
│   ├── schema.sql                     # Flowable BPMN schema (H2)
│   └── data.sql                       # Sample data (minimal)
└── infrastructure/                     # RESTgym monitoring tools
    ├── jacoco/
    │   ├── org.jacoco.agent-0.8.7-runtime.jar
    │   ├── org.jacoco.cli-0.8.7.jar
    │   ├── collect-coverage-interval.sh
    │   └── collect-coverage.sh
    └── mitmproxy/
        └── store-interactions.py
```

## API Modules

1. **Process API (BPMN)** - `/flowable-rest/service/*`
   - Process definitions, instances, tasks, history
2. **IDM API** - `/flowable-rest/idm-api/*`
   - Users, groups, privileges management

## Getting started

Build and run:

```bash
docker build -t restgym/flowable-process .
docker run -d -p 9090:9090 -p 12345:12345 \
  -e API=flowable-process -e TOOL=manual -e RUN=1 \
  --name flowable-process restgym/flowable-process
```

## API Endpoints

Base URL: `http://localhost:9090/flowable-rest`

**Authentication**: Basic Auth (username: `admin`, password: `test`)

### Process API
- `/service/management/engine` - Engine info
- `/service/repository/process-definitions` - Process definitions
- `/service/runtime/process-instances` - Process instances
- `/service/runtime/tasks` - Tasks
- `/service/history/historic-process-instances` - History

### IDM API
- `/idm-api/users` - User management
- `/idm-api/groups` - Group management
- `/idm-api/privileges` - Privileges

Example:
```bash
curl -u admin:test http://localhost:9090/flowable-rest/service/management/engine
```

## RESTgym Testing

Results directory: `/results/flowable-process/manual/1/`
- `interactions.db` - HTTP interactions (SQLite)
- `code-coverage/*.exec` - JaCoCo coverage files

### JaCoCo Coverage
```bash
java -jar org.jacoco.cli-0.8.7.jar dump --address localhost --port 12345 --destfile coverage.exec
```

### Query Interactions
```bash
docker exec flowable-process sqlite3 /results/flowable-process/manual/1/interactions.db \
  "SELECT method, url, response_code FROM http_flows LIMIT 10"
```

## Resources

- [Flowable Documentation](https://www.flowable.com/open-source/docs)
- [Flowable REST API](https://www.flowable.com/open-source/docs/bpmn/ch15-REST.html)
- [RESTgym Template](https://github.com/SeUniVr/RESTgym)

# Infrastructure Directory

This directory contains monitoring and testing infrastructure for the RESTgym framework.

## Components

### JaCoCo (Code Coverage)

**Location**: `jacoco/`

JaCoCo is used to collect code coverage metrics during API testing.

#### Files:
- `org.jacoco.agent-0.8.7-runtime.jar` (0.28 MB) - JaCoCo agent for runtime coverage collection
- `org.jacoco.cli-0.8.7.jar` (0.54 MB) - JaCoCo CLI for coverage report generation
- `collect-coverage-interval.sh` - Script that periodically triggers coverage dumps

#### How it works:
1. The JaCoCo agent is attached to the Java process via `-javaagent` flag
2. It listens on port 12345 for coverage dump commands
3. The `collect-coverage-interval.sh` script sends "dump" command every 60 seconds
4. Coverage data is collected in real-time as API endpoints are exercised

#### Usage in Dockerfile:
```bash
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=\
includes=*,output=tcpserver,port=12345,address=* \
-jar /api/flightsearchapi.jar
```

### mitmproxy (HTTP Interaction Recording)

**Location**: `mitmproxy/`

mitmproxy is a reverse proxy that intercepts and records all HTTP traffic.

#### Files:
- `store-interactions.py` - Python addon that stores HTTP interactions in SQLite

#### How it works:
1. mitmproxy runs as a reverse proxy on port 9090
2. All API requests go through: `client → mitmproxy:9090 → API:8080`
3. The addon captures request/response pairs
4. Data is stored in SQLite database at `/results/{API}/{TOOL}/{RUN}/interactions.db`

#### Database Schema:
```sql
CREATE TABLE interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    method TEXT,                   -- HTTP method (GET, POST, etc.)
    url TEXT,                      -- Full request URL
    status_code INTEGER,           -- HTTP response status
    request_headers TEXT,          -- JSON of request headers
    request_body TEXT,             -- Request body (truncated to 5KB)
    response_headers TEXT,         -- JSON of response headers
    response_body TEXT,            -- Response body (truncated to 5KB)
    timestamp DATETIME             -- When interaction occurred
)
```

#### Usage in Dockerfile:
```bash
mitmdump -p 9090 \
--mode reverse:http://localhost:8080/ \
-s /infrastructure/mitmproxy/store-interactions.py
```

## RESTgym Integration

These components work together to provide comprehensive testing metrics:

1. **Code Coverage** (JaCoCo):
   - Which lines of code were executed
   - Which branches were taken
   - Coverage percentage per class/method

2. **HTTP Interactions** (mitmproxy):
   - What requests were sent
   - What responses were received
   - Complete request/response history
   - Used for test replay and debugging

## Port Configuration

| Port | Service | Description |
|------|---------|-------------|
| 8080 | FlightSearchAPI | Internal API port (not exposed) |
| 9090 | mitmproxy | Public-facing proxy (exposed) |
| 12345 | JaCoCo | Coverage data collection port |

## Environment Variables

The infrastructure scripts use these environment variables:

- `API` - API slug (e.g., "flightsearchapi")
- `TOOL` - Testing tool name (e.g., "manual", "deeprest", "restler")
- `RUN` - Test run number (e.g., "1", "2", "3")

These are used to organize results: `/results/{API}/{TOOL}/{RUN}/`

## RESTgym Template Compliance

This infrastructure setup follows the RESTgym API template requirements:
- ✅ JaCoCo agent on port 12345
- ✅ mitmproxy on port 9090
- ✅ Periodic coverage collection
- ✅ SQLite interaction storage
- ✅ Results organized by API/TOOL/RUN structure

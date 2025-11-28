# Spring Kafka Publisher API - RESTgym Integration

Docker containerization of the **publisher-api** from [spring-cloud-stream-kafka-elasticsearch](https://github.com/ivangfr/spring-cloud-stream-kafka-elasticsearch) for RESTgym fuzzing framework.

## Overview

This API queries news data from Elasticsearch and exposes it via REST endpoints with pagination and search capabilities.

**Function**: News query service
- Reads news from Elasticsearch index `news`
- Provides search with text matching
- Supports pagination and sorting
- Integrated with Eureka service discovery

## API Endpoints

### Main Endpoints
- **GET** `/api/news?page={page}&size={size}&sort={field,order}` - List news (paginated)
  - Response: `{"content": [...], "totalElements": N, "totalPages": M}`
  
- **PUT** `/api/news/search` - Search news by text
  - Request: `{"text": "search query", "page": {...}, "sort": {...}}`
  - Response: Paginated news matching search criteria
  
- **GET** `/api/news/{id}` - Get news by UUID
  - Response: Single news object or 404

### Spring Boot Actuator
- `/actuator/health` - Health check (includes Elasticsearch status)
- `/actuator/metrics` - Application metrics
- `/actuator/env` - Environment properties
- `/actuator/beans` - Spring beans
- `/actuator/mappings` - Request mappings

Full OpenAPI spec: `specifications/spring-kafka-publisher-openapi.json`

## Architecture

```
Client → [mitmproxy:9090] → [publisher-api:9083] → Elasticsearch:9200
                ↓                      ↓
          SQLite DB              JaCoCo TCP:12345
```

**Technology Stack**:
- Java 21
- Spring Boot 3.5.3
- Spring Data Elasticsearch (Reactive)
- Spring WebFlux
- Netflix Eureka Client

**Data Flow**:
1. `producer-api` creates news → Kafka
2. `categorizer-service` adds category → Kafka
3. `collector-service` saves to Elasticsearch
4. **publisher-api** reads from Elasticsearch

## Build Strategy

**Build-in-Container**: The application is compiled inside the Docker image to ensure Java 21 compatibility.

Build steps (automated in Dockerfile):
1. Clone GitHub repository
2. Build `commons-news` shared module
3. Build `publisher-api` module
4. Copy JAR to `/api/publisher-api.jar`

No local Java 21 installation required.

## RESTgym Integration

### Ports
- **9090**: Mitmproxy (API access point for RESTgym tools)
- **12345**: JaCoCo TCP server (code coverage collection)
- **9083**: Internal Spring Boot port (not exposed externally)

### Instrumentation
- **HTTP Proxy**: Mitmproxy intercepts all requests
- **Code Coverage**: JaCoCo agent instruments Java bytecode
- **Interaction Storage**: SQLite database in `/results/$API/$TOOL/$RUN/`

### Collected Metrics
1. **HTTP Interactions** (`interactions.db`):
   - Request/response pairs with pagination params
   - Search queries and results
   - Status codes and headers
   - Response times

2. **Code Coverage** (`jacoco-*.exec`):
   - Line coverage
   - Branch coverage
   - Method coverage
   - Dumps every 60 seconds

## Environment Variables

### Required Dependencies
```bash
ELASTICSEARCH_HOST=elasticsearch      # Elasticsearch hostname
ELASTICSEARCH_REST_PORT=9200         # Elasticsearch REST API port
```

### RESTgym Variables
```bash
API=spring-kafka-publisher           # API identifier
TOOL=<fuzzing-tool>                  # e.g., restler, evomaster, etc.
RUN=<run-id>                         # Unique run identifier
```

### Optional
```bash
EUREKA_HOST=eureka                   # Service discovery (optional)
ZIPKIN_HOST=zipkin                   # Distributed tracing (optional)
```

## Usage

### 1. Build Docker Image
```bash
cd f:\Desktop\Tesi-RESTAPI\RESTgym\apis\spring-kafka-publisher
docker build -t spring-kafka-publisher:latest .
```

**Build time**: ~8-10 minutes (downloads dependencies, compiles source)

### 2. Run with Dependencies

**Prerequisites**: Elasticsearch must be running with `news` index populated.

Example with docker-compose:
```yaml
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.1
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"

  publisher-api:
    image: spring-kafka-publisher:latest
    depends_on: [elasticsearch]
    ports:
      - "9090:9090"   # Mitmproxy (API access)
      - "12345:12345" # JaCoCo TCP
    environment:
      API: spring-kafka-publisher
      TOOL: manual-test
      RUN: "001"
      ELASTICSEARCH_HOST: elasticsearch
      ELASTICSEARCH_REST_PORT: 9200
    volumes:
      - ./results:/results
```

### 3. Populate Elasticsearch (if empty)

Use `producer-api` + `categorizer-service` + `collector-service` to populate data:
```bash
# Send some news via producer-api
curl -X POST http://localhost:9080/api/news \
  -H "Content-Type: application/json" \
  -d '{"title": "Test News", "text": "Sample content for testing."}'

# Wait for Kafka → Elasticsearch pipeline
sleep 5

# Verify data in Elasticsearch
curl http://localhost:9200/news/_search?pretty
```

### 4. Test API
```bash
# List all news (first page, 10 items)
curl "http://localhost:9090/api/news?page=0&size=10&sort=datetime,desc"

# Search news by text
curl -X PUT http://localhost:9090/api/news/search \
  -H "Content-Type: application/json" \
  -d '{"text": "technology", "page": {"page": 0, "size": 20}}'

# Get specific news by ID
curl http://localhost:9090/api/news/550e8400-e29b-41d4-a716-446655440000

# Health check (includes Elasticsearch connectivity)
curl http://localhost:9090/actuator/health
```

### 5. Collect Results
```bash
# View interactions
sqlite3 results/spring-kafka-publisher/manual-test/001/interactions.db \
  "SELECT method, path, status_code, duration_ms FROM interactions ORDER BY timestamp DESC LIMIT 10;"

# Analyze search queries
sqlite3 results/spring-kafka-publisher/manual-test/001/interactions.db \
  "SELECT request_body FROM interactions WHERE path LIKE '/api/news/search%';"

# Generate coverage report (after stopping container)
docker cp <container-id>:/results/spring-kafka-publisher/manual-test/001 ./results/
java -jar infrastructure/jacoco/org.jacoco.cli-0.8.7.jar report \
  results/spring-kafka-publisher/manual-test/001/jacoco-*.exec \
  --classfiles <path-to-classes> \
  --html results/coverage-report/
```

## RESTgym Configuration

**File**: `restgym-api-config.yml`
```yaml
enabled: true
```

**Dictionary**: `dictionaries/deeprest/spring-kafka-publisher.json`
- 50+ search text values (categories, keywords)
- 9 page numbers (0, 1, 2, 3, 5, 10, 20, 50, 100)
- 7 size values (1, 5, 10, 20, 50, 100, 200)
- 6 sort options (datetime/title/category, asc/desc)
- 17 UUIDs for GET by ID testing
- 20 news categories
- 5 Elasticsearch metrics
- 6 actuator paths

Total fuzzing values: **140+**

## Troubleshooting

### API doesn't start
**Symptom**: Container exits immediately
**Cause**: Elasticsearch not reachable
**Solution**: 
```bash
# Check Elasticsearch connectivity
docker exec <container> curl -f http://elasticsearch:9200/_cluster/health

# Check Elasticsearch index
curl http://localhost:9200/news/_count
```

### Empty search results
**Symptom**: All endpoints return empty arrays
**Cause**: Elasticsearch `news` index is empty
**Solution**: Run full microservices stack to populate data (producer → categorizer → collector)

### 404 errors on GET /api/news/{id}
**Symptom**: All UUIDs return 404
**Cause**: Dictionary UUIDs don't exist in Elasticsearch
**Solution**: 
- Query existing IDs: `curl http://localhost:9200/news/_search?size=10`
- Update dictionary with real UUIDs

### No coverage data
**Symptom**: Empty `jacoco-*.exec` files
**Cause**: JaCoCo agent not attached or no code executed
**Solution**: 
- Verify JaCoCo agent in startup logs
- Send requests to trigger code execution
- Check port 12345 is accessible

## Files Structure

```
spring-kafka-publisher/
├── Dockerfile                          # Multi-stage build with Java 21
├── restgym-api-config.yml             # RESTgym integration flag
├── specifications/
│   └── spring-kafka-publisher-openapi.json  # OpenAPI 3.0.3 spec
├── classes/
│   └── README.md                       # Notes about JAR packaging
├── dictionaries/
│   └── deeprest/
│       └── spring-kafka-publisher.json  # Fuzzing dictionary (140+ values)
├── database/
│   └── README.md                       # N/A (uses Elasticsearch)
└── infrastructure/
    ├── jacoco/
    │   ├── org.jacoco.agent-0.8.7-runtime.jar
    │   ├── org.jacoco.cli-0.8.7.jar
    │   └── collect-coverage-interval.sh
    └── mitmproxy/
        └── store-interactions.py        # SQLite interaction recorder
```

## Dependencies

**Required for Operation**:
- Elasticsearch 8.x (with `news` index)

**Optional**:
- Eureka Server (service discovery)
- Zipkin (distributed tracing)

**To populate Elasticsearch** (separate containers):
- Kafka + Zookeeper
- Schema Registry
- producer-api (creates news)
- categorizer-service (adds categories)
- collector-service (saves to Elasticsearch)

## Testing Considerations

### Search Functionality
- Text search uses Elasticsearch full-text matching
- Test with partial words, case variations
- Empty text returns all documents

### Pagination
- `page`: 0-indexed (page=0 is first page)
- `size`: Controls items per page (default: 10)
- `sort`: Format is `field,direction` (e.g., `datetime,desc`)

### UUID Format
- Must be valid UUID format (8-4-4-4-12 hex digits)
- Invalid UUIDs return 400 Bad Request
- Non-existent valid UUIDs return 404 Not Found

## Performance Notes

- Reactive WebFlux provides non-blocking I/O
- Elasticsearch queries can be slow for large datasets
- Consider indexing on frequently searched fields
- Pagination reduces memory footprint

## License

Same as original project: [Apache License 2.0](https://github.com/ivangfr/spring-cloud-stream-kafka-elasticsearch/blob/master/LICENSE)

## References

- Original project: https://github.com/ivangfr/spring-cloud-stream-kafka-elasticsearch
- Spring Data Elasticsearch: https://spring.io/projects/spring-data-elasticsearch
- Elasticsearch Query DSL: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html
- RESTgym framework: [RESTgym documentation]

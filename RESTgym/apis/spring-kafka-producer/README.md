# Spring Kafka Producer API - RESTgym Integration

Docker containerization of the **producer-api** from [spring-cloud-stream-kafka-elasticsearch](https://github.com/ivangfr/spring-cloud-stream-kafka-elasticsearch) for RESTgym fuzzing framework.

## Overview

This API creates news events and publishes them to Apache Kafka. It's part of a microservices architecture demonstrating Spring Cloud Stream with Kafka and Elasticsearch.

**Function**: News event producer
- Accepts news creation requests via REST
- Publishes to Kafka topic `producer.news`
- Uses Avro schema with Schema Registry
- Integrated with Eureka service discovery

## API Endpoints

### Main Endpoint
- **POST** `/api/news` - Create and publish news event
  - Request: `{"title": "string", "text": "string"}`
  - Response: `{"id": "uuid", "title": "string", "text": "string", "datetime": "date"}`

### Spring Boot Actuator
- `/actuator/health` - Health check
- `/actuator/metrics` - Application metrics
- `/actuator/env` - Environment properties
- `/actuator/beans` - Spring beans
- `/actuator/mappings` - Request mappings

Full OpenAPI spec: `specifications/spring-kafka-producer-openapi.json`

## Architecture

```
Client → [mitmproxy:9090] → [producer-api:9080] → Kafka → Schema Registry
                ↓                      ↓
          SQLite DB              JaCoCo TCP:12345
```

**Technology Stack**:
- Java 21
- Spring Boot 3.5.3
- Spring Cloud Stream 2025.0.0
- Apache Kafka (Avro serialization)
- Spring Cloud Schema Registry
- Netflix Eureka Client

## Build Strategy

**Build-in-Container**: The application is compiled inside the Docker image to ensure Java 21 compatibility.

Build steps (automated in Dockerfile):
1. Clone GitHub repository
2. Build `commons-news` shared module
3. Build `producer-api` module
4. Copy JAR to `/api/producer-api.jar`

No local Java 21 installation required.

## RESTgym Integration

### Ports
- **9090**: Mitmproxy (API access point for RESTgym tools)
- **12345**: JaCoCo TCP server (code coverage collection)
- **9080**: Internal Spring Boot port (not exposed externally)

### Instrumentation
- **HTTP Proxy**: Mitmproxy intercepts all requests
- **Code Coverage**: JaCoCo agent instruments Java bytecode
- **Interaction Storage**: SQLite database in `/results/$API/$TOOL/$RUN/`

### Collected Metrics
1. **HTTP Interactions** (`interactions.db`):
   - Request/response pairs
   - Status codes and headers
   - Response times
   - Error traces

2. **Code Coverage** (`jacoco-*.exec`):
   - Line coverage
   - Branch coverage
   - Method coverage
   - Dumps every 60 seconds

## Environment Variables

### Required Dependencies
```bash
KAFKA_HOST=kafka              # Kafka broker hostname
KAFKA_PORT=9092               # Kafka broker port
SCHEMA_REGISTRY_HOST=schema-registry   # Schema Registry hostname
SCHEMA_REGISTRY_PORT=8081              # Schema Registry port
```

### RESTgym Variables
```bash
API=spring-kafka-producer     # API identifier
TOOL=<fuzzing-tool>           # e.g., restler, evomaster, etc.
RUN=<run-id>                  # Unique run identifier
```

### Optional
```bash
EUREKA_HOST=eureka            # Service discovery (optional)
ZIPKIN_HOST=zipkin            # Distributed tracing (optional)
```

## Usage

### 1. Build Docker Image
```bash
cd f:\Desktop\Tesi-RESTAPI\RESTgym\apis\spring-kafka-producer
docker build -t spring-kafka-producer:latest .
```

**Build time**: ~8-10 minutes (downloads dependencies, compiles source)

### 2. Run with Dependencies

**Prerequisites**: Kafka and Schema Registry must be running.

Example with docker-compose:
```yaml
version: '3.8'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    depends_on: [zookeeper]
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092

  schema-registry:
    image: confluentinc/cp-schema-registry:7.5.0
    depends_on: [kafka]
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: kafka:9092

  producer-api:
    image: spring-kafka-producer:latest
    depends_on: [kafka, schema-registry]
    ports:
      - "9090:9090"   # Mitmproxy (API access)
      - "12345:12345" # JaCoCo TCP
    environment:
      API: spring-kafka-producer
      TOOL: manual-test
      RUN: "001"
      KAFKA_HOST: kafka
      KAFKA_PORT: 9092
      SCHEMA_REGISTRY_HOST: schema-registry
      SCHEMA_REGISTRY_PORT: 8081
    volumes:
      - ./results:/results
```

### 3. Test API
```bash
# Via mitmproxy (port 9090)
curl -X POST http://localhost:9090/api/news \
  -H "Content-Type: application/json" \
  -d '{"title": "Breaking News", "text": "Important update about technology."}'

# Health check
curl http://localhost:9090/actuator/health

# Metrics
curl http://localhost:9090/actuator/metrics
```

### 4. Collect Results
```bash
# View interactions
sqlite3 results/spring-kafka-producer/manual-test/001/interactions.db \
  "SELECT method, path, status_code, duration_ms FROM interactions ORDER BY timestamp DESC LIMIT 10;"

# Generate coverage report (after stopping container)
docker cp <container-id>:/results/spring-kafka-producer/manual-test/001 ./results/
java -jar infrastructure/jacoco/org.jacoco.cli-0.8.7.jar report \
  results/spring-kafka-producer/manual-test/001/jacoco-*.exec \
  --classfiles <path-to-classes> \
  --html results/coverage-report/
```

## RESTgym Configuration

**File**: `restgym-api-config.yml`
```yaml
enabled: true
```

**Dictionary**: `dictionaries/deeprest/spring-kafka-producer.json`
- 50 news titles
- 50 news text samples
- Actuator metric names
- Actuator endpoint paths

Total fuzzing values: **200+**

## Troubleshooting

### API doesn't start
**Symptom**: Container exits immediately
**Cause**: Kafka or Schema Registry not reachable
**Solution**: 
```bash
# Check Kafka connectivity
docker exec <container> nc -zv kafka 9092

# Check Schema Registry
docker exec <container> curl -f http://schema-registry:8081/subjects
```

### No coverage data
**Symptom**: Empty `jacoco-*.exec` files
**Cause**: JaCoCo agent not attached or no code executed
**Solution**: 
- Verify JaCoCo agent in startup logs
- Send requests to trigger code execution
- Check port 12345 is accessible

### Mitmproxy errors
**Symptom**: `502 Bad Gateway` from mitmproxy
**Cause**: Application not ready on port 9080
**Solution**: Wait 30-60 seconds for Spring Boot startup

## Files Structure

```
spring-kafka-producer/
├── Dockerfile                          # Multi-stage build with Java 21
├── restgym-api-config.yml             # RESTgym integration flag
├── specifications/
│   └── spring-kafka-producer-openapi.json  # OpenAPI 3.1.0 spec
├── classes/
│   └── README.md                       # Notes about JAR packaging
├── dictionaries/
│   └── deeprest/
│       └── spring-kafka-producer.json  # Fuzzing dictionary (200+ values)
├── database/
│   └── README.md                       # N/A (uses Kafka topics)
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
- Apache Kafka broker
- Confluent Schema Registry
- Zookeeper (for Kafka)

**Optional**:
- Eureka Server (service discovery)
- Zipkin (distributed tracing)
- categorizer-service (consumes news events)
- collector-service (saves to Elasticsearch)

## License

Same as original project: [Apache License 2.0](https://github.com/ivangfr/spring-cloud-stream-kafka-elasticsearch/blob/master/LICENSE)

## References

- Original project: https://github.com/ivangfr/spring-cloud-stream-kafka-elasticsearch
- Spring Cloud Stream: https://spring.io/projects/spring-cloud-stream
- RESTgym framework: [RESTgym documentation]

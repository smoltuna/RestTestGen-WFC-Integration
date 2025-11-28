# Kafka REST Proxy - RESTgym Integration

## Overview

**API**: Confluent Kafka REST Proxy v7.5.0  
**Purpose**: RESTful interface to Apache Kafka cluster  
**OpenAPI Spec**: `specifications/kafka-rest-openapi.yaml`  
**Port**: 8082 (proxied via mitmproxy on 9090)

Kafka REST Proxy provides a RESTful interface to a Kafka cluster, enabling HTTP-based operations for producing/consuming messages, topic management, consumer groups, and cluster administration.

## Architecture

### Multi-Service Stack

Unlike standalone APIs, Kafka REST Proxy requires a full Kafka ecosystem:

```
┌─────────────────────────────────────────────────────┐
│                   Docker Compose                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────────┐      ┌──────────────┐            │
│  │  Zookeeper  │◄─────┤ Kafka Broker │            │
│  │  port 2181  │      │  port 9092   │            │
│  └─────────────┘      └──────┬───────┘            │
│                              │                     │
│                   ┌──────────▼─────────┐           │
│                   │  Schema Registry   │           │
│                   │     port 8081      │           │
│                   └──────────┬─────────┘           │
│                              │                     │
│                   ┌──────────▼─────────┐           │
│                   │ Kafka REST Proxy   │           │
│                   │     port 8082      │           │
│                   └──────────┬─────────┘           │
│                              │                     │
│  ┌───────────────────────────▼─────────────────┐   │
│  │         Mitmproxy (RESTgym)                 │   │
│  │  port 9090 → reverse proxy to 8082         │   │
│  │  stores interactions.db                    │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
         ▲
         │  HTTP Requests
         │  (REST testing tools)
```

### RESTgym Deviation

**Standard RESTgym Pattern**: Single Dockerfile with embedded API  
**Kafka REST Proxy Pattern**: Docker Compose with 5 services

**Reason**: Kafka REST Proxy cannot function in isolation. It requires:
1. **Zookeeper** - Cluster coordination
2. **Kafka Broker** - Message storage
3. **Schema Registry** - Schema management
4. **Kafka REST Proxy** - REST API server
5. **Mitmproxy** - RESTgym HTTP interception

The `Dockerfile` in this directory is a **placeholder** for template compliance. Actual deployment uses `docker-compose-restgym.yml`.

## Directory Structure

```
kafka-rest/
├── Dockerfile                          # Placeholder (see docker-compose instead)
├── docker-compose-restgym.yml          # Complete stack orchestration
├── restgym-api-config.yml              # RESTgym configuration
├── README.md                           # This file
│
├── specifications/
│   └── kafka-rest-openapi.yaml         # OpenAPI 3.0 spec (4679 lines)
│
├── classes/
│   └── README.md                       # N/A - pre-built binary
│
├── dictionaries/
│   └── deeprest/
│       └── kafka-rest.json             # 200+ domain values
│
├── database/
│   └── README.md                       # N/A - uses Kafka for storage
│
└── infrastructure/
    ├── jacoco/
    │   ├── org.jacoco.agent-0.8.7-runtime.jar
    │   ├── org.jacoco.cli-0.8.7.jar
    │   └── collect-coverage-interval.sh   # Placeholder (N/A)
    │
    └── mitmproxy/
        └── store-interactions.py          # HTTP interaction recorder
```

## Setup Instructions

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 1.29+
- 4GB RAM minimum (Kafka cluster resource requirements)
- Ports available: 2181, 8081, 8082, 9090, 9092

### Quick Start

```bash
# Navigate to API directory
cd f:\Desktop\Tesi-RESTAPI\RESTgym\apis\kafka-rest

# Start complete Kafka stack with RESTgym instrumentation
docker-compose -f docker-compose-restgym.yml up -d

# Wait for cluster initialization (60-90 seconds)
# Check logs:
docker-compose -f docker-compose-restgym.yml logs -f

# Verify all services running
docker-compose -f docker-compose-restgym.yml ps

# Expected output:
#   kafka-rest-zookeeper       Up      2181/tcp
#   kafka-rest-kafka           Up      9092/tcp, 9101/tcp
#   kafka-rest-schema-registry Up      8081/tcp
#   kafka-rest-proxy           Up      8082/tcp
#   kafka-rest-mitmproxy       Up      9090/tcp
```

### Environment Variables

Set before running docker-compose:

```bash
# RESTgym tracking
export API=kafka-rest         # Default: kafka-rest
export TOOL=manual            # Testing tool identifier
export RUN=test-1             # Test run identifier

# Results stored at: results/kafka-rest/{TOOL}/{RUN}/interactions.db
```

Windows PowerShell:
```powershell
$env:API="kafka-rest"
$env:TOOL="manual"
$env:RUN="test-1"
docker-compose -f docker-compose-restgym.yml up -d
```

### Shutdown

```bash
# Stop all services
docker-compose -f docker-compose-restgym.yml down

# Stop and remove volumes (clears all Kafka data)
docker-compose -f docker-compose-restgym.yml down -v
```

## Testing Guide

### Access Points

| Service | Direct Port | Proxied Port | Purpose |
|---------|-------------|--------------|---------|
| Zookeeper | 2181 | - | Cluster coordination |
| Kafka Broker | 9092 | - | Message storage |
| Schema Registry | 8081 | - | Schema management |
| Kafka REST Proxy | 8082 | - | Direct API access |
| **Mitmproxy** | - | **9090** | **RESTgym instrumented access** |

**For RESTgym testing, always use port 9090 (mitmproxy).**

### Sample API Operations

#### 1. List Clusters

```bash
curl http://localhost:9090/v3/clusters
```

**Expected Response:**
```json
{
  "kind": "KafkaClusterList",
  "metadata": {
    "self": "http://localhost:9090/v3/clusters"
  },
  "data": [
    {
      "kind": "KafkaCluster",
      "metadata": {...},
      "cluster_id": "...",
      "controller": {...},
      "acls": {...},
      "brokers": {...},
      "broker_configs": {...},
      "consumer_groups": {...},
      "topics": {...},
      "partition_reassignments": {...}
    }
  ]
}
```

#### 2. Get Cluster Details

```bash
# Extract cluster_id from previous response
CLUSTER_ID="your-cluster-id"

curl http://localhost:9090/v3/clusters/$CLUSTER_ID
```

#### 3. Create Topic

```bash
curl -X POST http://localhost:9090/v3/clusters/$CLUSTER_ID/topics \
  -H "Content-Type: application/json" \
  -d '{
    "topic_name": "test-topic",
    "partitions_count": 3,
    "replication_factor": 1,
    "configs": [
      {
        "name": "compression.type",
        "value": "gzip"
      }
    ]
  }'
```

#### 4. List Topics

```bash
curl http://localhost:9090/v3/clusters/$CLUSTER_ID/topics
```

#### 5. Produce Records

```bash
curl -X POST http://localhost:9090/v3/clusters/$CLUSTER_ID/topics/test-topic/records \
  -H "Content-Type: application/json" \
  -d '{
    "key": {
      "type": "JSON",
      "data": {"id": 123}
    },
    "value": {
      "type": "JSON",
      "data": {"message": "Hello Kafka", "timestamp": 1234567890}
    }
  }'
```

#### 6. Create Consumer Group

```bash
curl -X POST http://localhost:9090/v3/clusters/$CLUSTER_ID/consumer-groups \
  -H "Content-Type: application/json" \
  -d '{
    "group_id": "test-group"
  }'
```

#### 7. List Consumer Groups

```bash
curl http://localhost:9090/v3/clusters/$CLUSTER_ID/consumer-groups
```

#### 8. List Brokers

```bash
curl http://localhost:9090/v3/clusters/$CLUSTER_ID/brokers
```

#### 9. Get Broker Config

```bash
curl http://localhost:9090/v3/clusters/$CLUSTER_ID/brokers/1/configs
```

#### 10. Create ACL

```bash
curl -X POST http://localhost:9090/v3/clusters/$CLUSTER_ID/acls \
  -H "Content-Type: application/json" \
  -d '{
    "resource_type": "TOPIC",
    "resource_name": "test-topic",
    "pattern_type": "LITERAL",
    "principal": "User:alice",
    "host": "*",
    "operation": "READ",
    "permission": "ALLOW"
  }'
```

### Complete API Coverage

**v3 API Endpoints** (from OpenAPI spec):

**Cluster Operations:**
- GET /v3/clusters
- GET /v3/clusters/{cluster_id}

**Topic Operations:**
- GET /v3/clusters/{cluster_id}/topics
- POST /v3/clusters/{cluster_id}/topics
- GET /v3/clusters/{cluster_id}/topics/{topic_name}
- DELETE /v3/clusters/{cluster_id}/topics/{topic_name}
- GET /v3/clusters/{cluster_id}/topics/{topic_name}/partitions
- GET /v3/clusters/{cluster_id}/topics/{topic_name}/partitions/{partition_id}
- GET /v3/clusters/{cluster_id}/topics/{topic_name}/configs
- POST /v3/clusters/{cluster_id}/topics/{topic_name}/records

**Consumer Group Operations:**
- GET /v3/clusters/{cluster_id}/consumer-groups
- GET /v3/clusters/{cluster_id}/consumer-groups/{consumer_group_id}
- GET /v3/clusters/{cluster_id}/consumer-groups/{consumer_group_id}/consumers
- GET /v3/clusters/{cluster_id}/consumer-groups/{consumer_group_id}/lag-summary

**Broker Operations:**
- GET /v3/clusters/{cluster_id}/brokers
- GET /v3/clusters/{cluster_id}/brokers/{broker_id}
- GET /v3/clusters/{cluster_id}/brokers/{broker_id}/configs
- GET /v3/clusters/{cluster_id}/brokers/{broker_id}/partition-replicas

**ACL Operations:**
- GET /v3/clusters/{cluster_id}/acls
- POST /v3/clusters/{cluster_id}/acls:batch
- DELETE /v3/clusters/{cluster_id}/acls

**Partition Operations:**
- GET /v3/clusters/{cluster_id}/topics/{topic_name}/partitions/{partition_id}/replicas
- POST /v3/clusters/{cluster_id}/topics/-/partitions/-/reassignment

See `specifications/kafka-rest-openapi.yaml` for complete details.

## RESTgym Integration

### HTTP Interaction Capture

All HTTP requests/responses through port 9090 are captured by mitmproxy and stored in SQLite database.

**Database Location:**
```
results/kafka-rest/{TOOL}/{RUN}/interactions.db
```

**Schema:**
```sql
CREATE TABLE http_flows (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME,
    request_method TEXT,
    request_path TEXT,
    request_headers TEXT,
    request_body TEXT,
    response_status_code INTEGER,
    response_headers TEXT,
    response_body TEXT,
    duration_ms REAL
);
```

**Query Captured Data:**
```bash
# Access container
docker exec -it kafka-rest-mitmproxy bash

# Query database
sqlite3 /results/kafka-rest/manual/test-1/interactions.db

# Count total requests
SELECT COUNT(*) FROM http_flows;

# List all endpoints hit
SELECT DISTINCT request_method, request_path FROM http_flows;

# Status code distribution
SELECT response_status_code, COUNT(*) 
FROM http_flows 
GROUP BY response_status_code;

# Average response time
SELECT AVG(duration_ms) FROM http_flows;

# Slowest requests
SELECT request_method, request_path, duration_ms 
FROM http_flows 
ORDER BY duration_ms DESC 
LIMIT 10;
```

### Code Coverage

**Status**: ❌ Not Available

Kafka REST Proxy is distributed as **pre-built binary** by Confluent Platform.

- No source code compilation
- Cannot instrument with JaCoCo agent
- `classes/` directory is N/A
- `infrastructure/jacoco/collect-coverage-interval.sh` is placeholder

**Alternative Metrics**:
- HTTP endpoint coverage (from interactions.db)
- Status code distribution
- Response time analysis
- Request parameter variety

### Dictionary Values

`dictionaries/deeprest/kafka-rest.json` contains **200+ domain-specific values**:

**Categories:**
- `cluster_id`: 10 cluster identifiers
- `topic_name`: 40 topic names (events, logs, orders, etc.)
- `broker_id`: 14 broker IDs
- `partition_id`: 17 partition numbers
- `consumer_group_id`: 20 consumer group names
- `consumer_id`: 15 consumer identifiers
- `config_name`: 28 Kafka configuration keys
- `acl_principal`: 17 ACL principals (users, groups)
- `acl_host`: 12 host patterns
- `acl_operation`: 11 ACL operations (READ, WRITE, CREATE, etc.)
- `acl_permission_type`: 2 (ALLOW, DENY)
- `acl_resource_type`: 5 resource types
- `acl_pattern_type`: 4 pattern types
- `record_key`: 14 message keys
- `record_value`: 18 JSON payloads
- `offset`: 9 offset positions
- `timestamp`: 7 timestamp values
- `replication_factor`: 3 replication factors
- `num_partitions`: 7 partition counts
- `compression_type`: 5 compression algorithms
- `cleanup_policy`: 3 cleanup policies

**Usage**: DeepREST and other testing tools use these values for intelligent input generation.

## Results Directory

After testing with `TOOL=manual` and `RUN=test-1`:

```
results/
└── kafka-rest/
    └── manual/
        └── test-1/
            └── interactions.db    # SQLite database with HTTP flows
```

**Mount Volume** (recommended):
```bash
docker-compose -f docker-compose-restgym.yml down
# Add to docker-compose-restgym.yml under mitmproxy service:
volumes:
  - ./results:/results
  - ./infrastructure:/infrastructure

# Or mount from host:
mkdir -p f:/Desktop/Tesi-RESTAPI/RESTgym/results
# Update volumes path in compose file
```

## Troubleshooting

### Services Not Starting

**Symptom**: Containers exit immediately

**Solution**:
```bash
# Check logs for each service
docker-compose -f docker-compose-restgym.yml logs zookeeper
docker-compose -f docker-compose-restgym.yml logs kafka
docker-compose -f docker-compose-restgym.yml logs schema-registry
docker-compose -f docker-compose-restgym.yml logs rest-proxy
docker-compose -f docker-compose-restgym.yml logs mitmproxy
```

Common issues:
- Insufficient memory (need 4GB+)
- Ports already in use (check with `netstat -an | findstr "2181 8081 8082 9090 9092"`)
- Docker network conflicts

### Kafka Broker Not Ready

**Symptom**: REST Proxy returns 503 Service Unavailable

**Solution**: Kafka cluster takes 60-90 seconds to initialize

```bash
# Wait for Kafka to be ready
docker exec kafka-rest-kafka kafka-broker-api-versions --bootstrap-server localhost:9092

# Check Zookeeper connection
docker exec kafka-rest-zookeeper zkServer.sh status
```

### Mitmproxy Not Capturing Requests

**Symptom**: `interactions.db` file is empty

**Solution**:
```bash
# Check mitmproxy logs
docker logs kafka-rest-mitmproxy

# Verify reverse proxy configuration
docker exec kafka-rest-mitmproxy ps aux | grep mitmdump

# Ensure requests go through port 9090, not 8082
curl http://localhost:9090/v3/clusters  # ✅ Captured
curl http://localhost:8082/v3/clusters  # ❌ Not captured
```

### Schema Registry Connection Failure

**Symptom**: Error creating topics with schemas

**Solution**:
```bash
# Verify Schema Registry is running
curl http://localhost:8081/subjects

# Check REST Proxy configuration
docker exec kafka-rest-proxy env | grep SCHEMA_REGISTRY
# Should show: KAFKA_REST_SCHEMA_REGISTRY_URL=http://schema-registry:8081
```

### Permission Denied on Results Directory

**Symptom**: Mitmproxy cannot write to `/results`

**Solution**:
```bash
# On host, create results directory with correct permissions
mkdir -p results/kafka-rest
chmod -R 777 results/

# Or run mitmproxy container with user ID
# Edit docker-compose-restgym.yml:
mitmproxy:
  user: "${UID}:${GID}"  # Add this line
```

## Performance Notes

### Resource Requirements

- **Minimum**: 4GB RAM, 2 CPU cores
- **Recommended**: 8GB RAM, 4 CPU cores
- **Disk**: 2GB for container images + data volume

### Startup Time

- **Zookeeper**: ~10 seconds
- **Kafka Broker**: ~30 seconds (waits for Zookeeper)
- **Schema Registry**: ~15 seconds (waits for Kafka)
- **REST Proxy**: ~10 seconds (waits for Schema Registry)
- **Total**: ~60-90 seconds for full stack

Use `docker-compose logs -f` to monitor progress.

### Request Latency

Typical response times through mitmproxy:

| Operation | Latency |
|-----------|---------|
| List Clusters | 50-100ms |
| Get Cluster | 30-70ms |
| List Topics | 80-150ms |
| Create Topic | 200-400ms |
| Produce Record | 100-300ms |
| List Consumer Groups | 100-200ms |

Add ~5-10ms overhead for mitmproxy reverse proxy.

## Comparison with RESTgym Template

| Aspect | Standard RESTgym | Kafka REST Proxy |
|--------|------------------|------------------|
| **Containerization** | Single Dockerfile | Docker Compose (5 services) |
| **Dockerfile** | Functional | Placeholder |
| **API Startup** | Direct in container | Via Confluent Platform |
| **Code Coverage** | JaCoCo instrumentation | ❌ Not available (pre-built) |
| **HTTP Capture** | ✅ Mitmproxy | ✅ Mitmproxy |
| **Database** | SQL schema | ❌ N/A (uses Kafka) |
| **Classes** | Extracted .class files | ❌ N/A (pre-built binary) |
| **Dictionary** | ✅ Domain values | ✅ Domain values (200+) |
| **Results** | ✅ interactions.db | ✅ interactions.db |

**Deviation Reason**: Multi-service dependency requirement (Zookeeper + Kafka + Schema Registry).

## References

- **Confluent Kafka REST Proxy Docs**: https://docs.confluent.io/platform/current/kafka-rest/index.html
- **OpenAPI Spec**: `specifications/kafka-rest-openapi.yaml`
- **Docker Images**: https://hub.docker.com/r/confluentinc/
- **RESTgym Framework**: f:\Desktop\Tesi-RESTAPI\RESTgym\
- **Mitmproxy Docs**: https://docs.mitmproxy.org/

## License

Follows Confluent Platform licensing and RESTgym project terms.

---

**Last Updated**: 2025-01-25  
**API Version**: Kafka REST Proxy v7.5.0 (Confluent Platform)  
**RESTgym Template Version**: 2024

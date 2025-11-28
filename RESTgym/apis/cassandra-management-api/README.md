# Cassandra Management API

## Overview

The Management API for Apache Cassandra™ is a sidecar service layer that provides RESTful operational actions for managing Cassandra nodes.

## API Information

- **Name**: Cassandra Management API  
- **Version**: 0.1 (based on Cassandra 4.0.18)
- **Language**: Java 11
- **Framework**: RESTEasy (JAX-RS), Netty
- **Build Tool**: Maven
- **Port**: 8080 (Management API), 9042 (Cassandra CQL), 9090 (mitmproxy), 12345 (JaCoCo)
- **Database**: Manages external Apache Cassandra database

## Features

- **Lifecycle Management**: Start/stop Cassandra nodes
- **Configuration Management**: Modify Cassandra YAML and JVM options  
- **Health Checks**: Kubernetes-style liveness and readiness probes
- **Node Operations**: All nodetool commands exposed as REST endpoints
- **Keyspace Operations**: Create, alter, list keyspaces
- **Table Operations**: Compact, flush, scrub, upgrade SSTables
- **Repair Operations**: Trigger and monitor repair jobs
- **Snapshot Management**: Take, list, and delete snapshots
- **Authentication**: Create and manage Cassandra roles

## Architecture

The Management API is designed to run as a sidecar alongside Apache Cassandra. It communicates with Cassandra via CQL through a local Unix socket for security.

```
┌─────────────────────┐      ┌──────────────────────────┐
│  Management API     │◄────►│  Apache Cassandra        │
│  (Port 8080)        │ CQL  │  (Port 9042)             │
│  RESTful Service    │      │  • System Keyspaces      │
│                     │      │  • User Keyspaces        │
│                     │      │  • Tables & Data         │
└─────────────────────┘      └──────────────────────────┘
```

**Database**: Cassandra automatically creates system keyspaces on first startup. Optional test data can be initialized using the provided `database/init-test-data.cql` script.

## RESTgym Integration

This API has been containerized following the RESTgym template:

- **Dockerfile**: Based on `k8ssandra/cass-management-api:4.0.18`
- **Infrastructure**: JaCoCo for coverage, mitmproxy for HTTP interception
- **Specifications**: OpenAPI 3.0 specification included
- **Dictionaries**: DeepREST fuzzing dictionary with Cassandra-specific values

## Building and Running

### Using RESTgym

```bash
# Build the Docker image
docker build -t cassandra-management-api:latest .

# Run with RESTgym infrastructure
docker run -d \
  -p 9090:9090 \
  -p 12345:12345 \
  -p 8080:8080 \
  -p 9042:9042 \
  -e API=cassandra-management-api \
  -e TOOL=manual \
  -e RUN=1 \
  --name cassandra-mgmt-test \
  cassandra-management-api:latest

# Wait for Cassandra to start (30-60 seconds)
sleep 60

# Test the API via mitmproxy
curl http://localhost:9090/api/v0/probes/liveness
# Expected: OK

curl http://localhost:9090/api/v0/probes/readiness  
# Expected: OK (once Cassandra is fully started)

curl http://localhost:9090/api/v0/metadata/versions/release
# Expected: 4.0.x

# Check JaCoCo is active
nc -zv localhost 12345
```

### Direct Usage (without RESTgym)

```bash
# Pull the official image
docker pull k8ssandra/cass-management-api:4.0.18

# Run with management API enabled
docker run -d \
  -e USE_MGMT_API=true \
  -p 8080:8080 \
  -p 9042:9042 \
  k8ssandra/cass-management-api:4.0.18
```

## API Endpoints

### Lifecycle
- `POST /api/v0/lifecycle/start` - Start Cassandra
- `POST /api/v0/lifecycle/stop` - Stop Cassandra  
- `GET /api/v0/lifecycle/pid` - Get Cassandra process ID
- `POST /api/v0/lifecycle/configure` - Configure Cassandra

### Probes
- `GET /api/v0/probes/liveness` - Liveness check (API running)
- `GET /api/v0/probes/readiness` - Readiness check (Cassandra ready)
- `GET /api/v0/probes/cluster?consistency=QUORUM` - Cluster consistency check

### Metadata
- `GET /api/v0/metadata/endpoints` - View of endpoint states
- `GET /api/v0/metadata/localdc` - Local datacenter name
- `GET /api/v0/metadata/versions/release` - Cassandra version
- `GET /api/v0/metadata/versions/features` - Management API feature set

### Node Operations
- `POST /api/v0/ops/node/repair` - Trigger repair
- `POST /api/v0/ops/node/drain` - Drain the node
- `POST /api/v0/ops/node/decommission` - Decommission node
- `POST /api/v0/ops/node/assassinate` - Force remove dead node
- `POST /api/v0/ops/node/move` - Move node on token ring

### Keyspace Operations
- `GET /api/v0/ops/keyspace` - List keyspaces
- `POST /api/v0/ops/keyspace/create` - Create keyspace
- `POST /api/v0/ops/keyspace/alter` - Alter keyspace replication
- `GET /api/v0/ops/keyspace/replication` - Get replication settings

### Table Operations
- `GET /api/v0/ops/tables?keyspace={ks}` - List tables in keyspace
- `POST /api/v0/ops/tables/compact` - Compact tables
- `POST /api/v0/ops/tables/flush` - Flush memtables to disk
- `POST /api/v0/ops/tables/scrub` - Scrub (rebuild) SSTables
- `POST /api/v0/ops/tables/sstables/upgrade` - Upgrade SSTable format

### Snapshot Operations
- `GET /api/v0/ops/node/snapshots` - List snapshots
- `POST /api/v0/ops/node/snapshots` - Take snapshot
- `DELETE /api/v0/ops/node/snapshots` - Clear snapshots

## Testing with RESTgym

Once the container is running, you can test with various tools:

### Basic Health Checks
```bash
curl http://localhost:9090/api/v0/probes/liveness
curl http://localhost:9090/api/v0/probes/readiness
```

### Metadata Queries
```bash
curl http://localhost:9090/api/v0/metadata/versions/release
curl http://localhost:9090/api/v0/metadata/localdc
curl http://localhost:9090/api/v0/metadata/endpoints
```

### Keyspace Operations
```bash
# List keyspaces
curl http://localhost:9090/api/v0/ops/keyspace

# Create a keyspace
curl -X POST http://localhost:9090/api/v0/ops/keyspace/create \
  -H "Content-Type: application/json" \
  -d '{
    "keyspace_name": "test_ks",
    "replication_settings": [
      {"dc_name": "datacenter1", "replication_factor": 1}
    ]
  }'

# List tables
curl "http://localhost:9090/api/v0/ops/tables?keyspace=test_ks"
```

### Initialize Test Data (Optional)
```bash
# Option 1: Use cqlsh inside the container
docker exec -it cassandra-mgmt-test cqlsh -f /database/init-test-data.cql

# Option 2: Copy the CQL file and execute it
docker cp database/init-test-data.cql cassandra-mgmt-test:/tmp/
docker exec -it cassandra-mgmt-test cqlsh -f /tmp/init-test-data.cql

# Option 3: Use interactive cqlsh
docker exec -it cassandra-mgmt-test cqlsh
# Then run: SOURCE '/tmp/init-test-data.cql';

# Verify keyspaces created
curl http://localhost:9090/api/v0/ops/keyspace
# Expected: ["system", "system_auth", "system_distributed", "system_schema", "system_traces", "system_views", "test_keyspace", "prod_keyspace"]
```

### View Coverage Data
```bash
# JaCoCo coverage is collected in background
# Check results directory after testing
docker exec cassandra-mgmt-test ls -la /results/cassandra-management-api/manual/1/

# View mitmproxy interactions database
docker exec cassandra-mgmt-test sqlite3 /results/cassandra-management-api/manual/1/interactions.db "SELECT COUNT(*) FROM interactions;"
```

## References

- **GitHub Repository**: https://github.com/k8ssandra/management-api-for-apache-cassandra
- **Docker Hub**: https://hub.docker.com/r/k8ssandra/cass-management-api
- **OpenAPI Specification**: See `specifications/cassandra-management-api-openapi.json`
- **Apache Cassandra**: https://cassandra.apache.org/

## Notes

- The Management API requires Cassandra to be running to provide meaningful responses
- Some endpoints are async and return job IDs for long-running operations
- The API uses CQL internally for all Cassandra interactions (no JMX)
- Default credentials: cassandra/cassandra (for Cassandra authentication)
- Cassandra startup takes 30-60 seconds in the container

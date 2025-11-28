# Database Directory

**Status**: Apache Cassandra Database (auto-initialized)

This directory contains information about the Apache Cassandra database that is bundled with the Management API container.

## Data Storage Architecture

The Management API runs as a **sidecar** alongside Apache Cassandra. When the container starts, Cassandra is launched and automatically initializes its system keyspaces.

### Apache Cassandra Database

- **Type**: Apache Cassandra NoSQL Database (wide-column store)
- **Version**: 4.0.18 (bundled in the Docker image)
- **Query Language**: CQL (Cassandra Query Language), NOT SQL
- **Connection**: Local Unix socket (secure, no network exposure required)
- **Default Ports**:
  - Cassandra CQL: 9042
  - Management API: 8080 (configurable via `MGMT_API_LISTEN_TCP_PORT`)

### Automatic Database Initialization

When Cassandra starts for the first time in the container, it **automatically creates system keyspaces**:

- `system` - Core system information
- `system_schema` - Schema definitions for keyspaces, tables, types, functions
- `system_auth` - Authentication and authorization (users, roles, permissions)
- `system_distributed` - Distributed system metadata
- `system_traces` - Query tracing data for performance analysis
- `system_views` - Materialized views metadata
- And other system keyspaces...

**No manual schema.sql file is needed** - Cassandra handles this automatically on first startup (takes 30-60 seconds).
  
### Operations Provided

The API provides RESTful endpoints for:
- **Lifecycle Management**: Start/stop Cassandra nodes
- **Configuration Management**: Modify Cassandra configuration
- **Health Checks**: Liveness and readiness probes
- **Node Operations**: All nodetool commands exposed as REST endpoints
- **Keyspace Operations**: Create, alter, list keyspaces
- **Table Operations**: Compact, flush, scrub tables
- **Repair Operations**: Trigger and monitor repair operations
- **Snapshot Management**: Take and manage snapshots

### Cassandra Requirement

This API requires an Apache Cassandra instance (version 4.0+) to be running. The API acts as a sidecar service providing management operations.

**For testing**:
```bash
# Option 1: Use the official Docker image (includes both Cassandra + Management API)
docker pull k8ssandra/cass-management-api:4.0.18

# Option 2: Run Cassandra separately and connect Management API
docker run -d --name cassandra cassandra:4.0
docker run --link cassandra -e USE_MGMT_API=true -p 8080:8080 k8ssandra/cass-management-api:4.0.18
```

### Optional: Test Data Initialization

For RESTgym testing, you may want to create test keyspaces and tables. This can be done via the Management API after Cassandra is fully started:

```bash
# Wait for Cassandra to be ready (30-60 seconds after container start)
curl http://localhost:8080/api/v0/probes/readiness

# Create a test keyspace
curl -X POST http://localhost:8080/api/v0/ops/keyspace/create \
  -H "Content-Type: application/json" \
  -d '{
    "keyspace_name": "test_ks",
    "replication_settings": [
      {"dc_name": "datacenter1", "replication_factor": 1}
    ]
  }'

# You can also use cqlsh directly in the container:
docker exec -it <container-name> cqlsh

# Then run CQL commands:
CREATE KEYSPACE IF NOT EXISTS test_ks 
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE test_ks.users (
  user_id uuid PRIMARY KEY,
  username text,
  email text,
  created_at timestamp
);
```

### No Schema Files Required

Unlike SQL databases, Cassandra does not use schema.sql files. All operations are performed via:
1. **CQL** (Cassandra Query Language) - similar to SQL but for NoSQL
2. **Management API REST endpoints** - for operational tasks
3. **cqlsh** - interactive CQL shell bundled with Cassandra

### Reference

- Management API Documentation: https://github.com/k8ssandra/management-api-for-apache-cassandra
- OpenAPI Specification: See `specifications/cassandra-management-api-openapi.json`
- Cassandra Documentation: https://cassandra.apache.org/doc/latest/

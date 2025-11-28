# Database Directory

**Status**: N/A

Kafka REST Proxy uses **Kafka broker** for data storage (topics, partitions, records), not a traditional SQL database.

**No database initialization scripts are required.**

Data is created dynamically through REST API operations:
- POST /v3/clusters/{cluster_id}/topics (create topic)
- POST /v3/clusters/{cluster_id}/topics/{topic_name}/records (produce record)
- Consumer groups and offsets managed by Kafka internally

See OpenAPI spec for data model details.

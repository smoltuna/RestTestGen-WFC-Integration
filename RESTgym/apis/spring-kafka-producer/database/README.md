# Database Directory

**Status**: N/A

This API does not use a SQL database. It produces messages to Kafka topics.

**Data Storage**:
- **Kafka Topic**: `producer.news`
- **Schema Registry**: Stores Avro schemas for NewsEvent
- **No SQL database required**

News data is created via REST API and immediately published to Kafka:
```bash
POST /api/news
{
  "title": "Breaking News",
  "text": "This is the news content"
}
```

The event is then consumed by `categorizer-service` downstream.

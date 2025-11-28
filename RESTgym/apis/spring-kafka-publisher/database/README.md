# Database Directory

**Status**: Uses Elasticsearch

This API reads news data from **Elasticsearch** (not SQL database).

**Data Storage**:
- **Elasticsearch Index**: `news`
- **Data Source**: Populated by `collector-service` via Kafka
- **No SQL database required**

News data schema in Elasticsearch:
```json
{
  "id": "uuid",
  "title": "string",
  "text": "string",
  "category": "string",
  "datetime": "date"
}
```

API endpoints:
- `GET /api/news` - List all news (paginated)
- `GET /api/news/{id}` - Get news by ID
- `PUT /api/news/search` - Search news by text

The data is queried directly from Elasticsearch, no SQL migrations needed.

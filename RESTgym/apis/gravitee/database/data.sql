-- Gravitee.io APIM MongoDB Sample Data
-- This file documents sample data structure for MongoDB collections

-- MongoDB uses JSON documents, not SQL INSERT statements
-- Sample data will be initialized by Gravitee on first startup with default admin user

-- Default admin credentials:
-- Username: admin
-- Password: admin

-- Default organization: DEFAULT
-- Default environment: DEFAULT

-- Sample API structure (JSON document in 'apis' collection):
-- {
--   "_id": "api-sample-123",
--   "name": "Sample API",
--   "version": "1.0.0",
--   "description": "Sample API for testing",
--   "visibility": "PUBLIC",
--   "state": "STARTED",
--   "definition_version": "V4",
--   "proxy": {
--     "virtual_hosts": [{
--       "path": "/sample"
--     }],
--     "endpoints": [{
--       "name": "default",
--       "target": "https://api.gravitee.io/echo"
--     }]
--   },
--   "created_at": ISODate("2024-01-01T00:00:00Z"),
--   "updated_at": ISODate("2024-01-01T00:00:00Z"),
--   "environment_id": "DEFAULT"
-- }

-- Sample plan structure (JSON document in 'plans' collection):
-- {
--   "_id": "plan-sample-123",
--   "name": "Free Plan",
--   "description": "Free access plan",
--   "api": "api-sample-123",
--   "security": "API_KEY",
--   "status": "PUBLISHED",
--   "validation": "AUTO",
--   "characteristics": [],
--   "flows": [],
--   "created_at": ISODate("2024-01-01T00:00:00Z"),
--   "updated_at": ISODate("2024-01-01T00:00:00Z")
-- }

-- Sample subscription structure (JSON document in 'subscriptions' collection):
-- {
--   "_id": "subscription-sample-123",
--   "plan": "plan-sample-123",
--   "application": "app-sample-123",
--   "api": "api-sample-123",
--   "status": "ACCEPTED",
--   "processed_at": ISODate("2024-01-01T00:00:00Z"),
--   "created_at": ISODate("2024-01-01T00:00:00Z"),
--   "updated_at": ISODate("2024-01-01T00:00:00Z"),
--   "starting_at": ISODate("2024-01-01T00:00:00Z")
-- }

-- Gravitee will automatically create default admin user on first startup
-- No manual data insertion needed

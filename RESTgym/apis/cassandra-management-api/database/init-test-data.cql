-- Test Data Initialization for Cassandra Management API
-- This file can be used to create test keyspaces and tables for RESTgym testing
-- 
-- Execute this file using cqlsh:
--   docker exec -it <container-name> cqlsh -f /path/to/init-test-data.cql
-- Or via Management API REST endpoints

-- Create test keyspace with simple replication
CREATE KEYSPACE IF NOT EXISTS test_keyspace
WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

-- Create test keyspace for production-like scenarios
CREATE KEYSPACE IF NOT EXISTS prod_keyspace
WITH replication = {
  'class': 'NetworkTopologyStrategy',
  'datacenter1': 3
};

-- Switch to test keyspace
USE test_keyspace;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  user_id uuid PRIMARY KEY,
  username text,
  email text,
  created_at timestamp,
  last_login timestamp
);

-- Create events table (time-series data)
CREATE TABLE IF NOT EXISTS events (
  event_id timeuuid,
  event_type text,
  user_id uuid,
  event_data text,
  created_at timestamp,
  PRIMARY KEY (event_type, event_id)
) WITH CLUSTERING ORDER BY (event_id DESC);

-- Create sessions table
CREATE TABLE IF NOT EXISTS sessions (
  session_id uuid PRIMARY KEY,
  user_id uuid,
  ip_address text,
  user_agent text,
  created_at timestamp,
  expires_at timestamp
);

-- Create logs table (time-series)
CREATE TABLE IF NOT EXISTS logs (
  log_id timeuuid,
  level text,
  message text,
  source text,
  created_at timestamp,
  PRIMARY KEY ((level), created_at, log_id)
) WITH CLUSTERING ORDER BY (created_at DESC, log_id DESC);

-- Create metrics table
CREATE TABLE IF NOT EXISTS metrics (
  metric_name text,
  metric_timestamp timestamp,
  metric_value double,
  tags map<text, text>,
  PRIMARY KEY (metric_name, metric_timestamp)
) WITH CLUSTERING ORDER BY (metric_timestamp DESC);

-- Insert sample users
INSERT INTO users (user_id, username, email, created_at, last_login)
VALUES (uuid(), 'admin', 'admin@example.com', toTimestamp(now()), toTimestamp(now()));

INSERT INTO users (user_id, username, email, created_at, last_login)
VALUES (uuid(), 'developer', 'dev@example.com', toTimestamp(now()), toTimestamp(now()));

INSERT INTO users (user_id, username, email, created_at, last_login)
VALUES (uuid(), 'testuser', 'test@example.com', toTimestamp(now()), toTimestamp(now()));

-- Insert sample events
INSERT INTO events (event_id, event_type, user_id, event_data, created_at)
VALUES (now(), 'login', uuid(), '{"ip": "127.0.0.1", "success": true}', toTimestamp(now()));

INSERT INTO events (event_id, event_type, user_id, event_data, created_at)
VALUES (now(), 'logout', uuid(), '{"duration": 3600}', toTimestamp(now()));

INSERT INTO events (event_id, event_type, user_id, event_data, created_at)
VALUES (now(), 'api_call', uuid(), '{"endpoint": "/api/v0/metadata/versions"}', toTimestamp(now()));

-- Insert sample logs
INSERT INTO logs (log_id, level, message, source, created_at)
VALUES (now(), 'INFO', 'Cassandra started successfully', 'cassandra', toTimestamp(now()));

INSERT INTO logs (log_id, level, message, source, created_at)
VALUES (now(), 'INFO', 'Management API listening on port 8080', 'mgmt-api', toTimestamp(now()));

INSERT INTO logs (log_id, level, message, source, created_at)
VALUES (now(), 'DEBUG', 'Connection established from 127.0.0.1', 'cassandra', toTimestamp(now()));

-- Insert sample metrics
INSERT INTO metrics (metric_name, metric_timestamp, metric_value, tags)
VALUES ('cpu_usage', toTimestamp(now()), 45.5, {'host': 'cassandra-1', 'dc': 'datacenter1'});

INSERT INTO metrics (metric_name, metric_timestamp, metric_value, tags)
VALUES ('memory_usage', toTimestamp(now()), 2048.0, {'host': 'cassandra-1', 'dc': 'datacenter1'});

INSERT INTO metrics (metric_name, metric_timestamp, metric_value, tags)
VALUES ('disk_usage', toTimestamp(now()), 50.2, {'host': 'cassandra-1', 'dc': 'datacenter1'});

-- Verify data
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM events;
SELECT COUNT(*) FROM logs;
SELECT COUNT(*) FROM metrics;

-- Show keyspaces
DESC KEYSPACES;

-- Show tables in test_keyspace
DESC TABLES;

-- Flowable Sample Data for RESTgym Testing
-- Minimal test data for basic API testing

-- Note: Flowable automatically generates IDs and deploys processes
-- This file provides minimal test users and groups for identity links

-- Sample users (would typically be in IDM tables, but shown here for reference)
-- In a real deployment, users would be managed through Flowable IDM

-- Sample groups (would typically be in IDM tables)
-- In a real deployment, groups would be managed through Flowable IDM

-- The main sample data will be created through:
-- 1. Deploying BPMN process definitions via REST API
-- 2. Starting process instances via REST API
-- 3. Creating tasks via process execution

-- For basic testing, Flowable will auto-create necessary data
-- No explicit INSERT statements needed as Flowable manages runtime data

-- Example process variables that might be used:
-- Variable: approved = true/false
-- Variable: amount = 1000.00
-- Variable: requestor = 'john.doe'
-- Variable: approver = 'jane.smith'
-- Variable: status = 'pending'/'approved'/'rejected'

-- This minimal approach allows Flowable to manage data lifecycle
-- while still providing a valid SQL file for RESTgym structure

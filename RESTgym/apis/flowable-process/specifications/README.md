# Flowable Process API - OpenAPI Specification

This directory contains the OpenAPI specification for the Flowable BPMN Process Engine REST API.

## Files

- `flowable-process-openapi.yaml` - Complete OpenAPI 3.0 specification for Flowable REST API

## API Documentation

The Flowable REST API provides comprehensive access to the BPMN process engine:

### Main Resource Categories

1. **Repository** - Process definitions, deployments, models
   - `/repository/deployments`
   - `/repository/process-definitions`
   - `/repository/models`

2. **Runtime** - Process instances, executions, tasks, variables
   - `/runtime/process-instances`
   - `/runtime/executions`
   - `/runtime/tasks`
   - `/runtime/activity-instances`
   - `/runtime/event-subscriptions`

3. **History** - Historical process data, audit logs
   - `/history/historic-process-instances`
   - `/history/historic-activity-instances`
   - `/history/historic-task-instances`
   - `/history/historic-variable-instances`
   - `/history/historic-detail`

4. **Management** - Engine information, jobs, database tables
   - `/management/engine`
   - `/management/jobs`
   - `/management/tables`
   - `/management/properties`

5. **Identity** - Users and groups (basic)
   - `/identity/users`
   - `/identity/groups`

6. **Query** - Advanced querying capabilities
   - `/query/process-instances`
   - `/query/tasks`
   - `/query/executions`
   - `/query/historic-process-instances`

7. **Forms** - Form data retrieval
   - `/form/form-data`

## Base URL

When running in RESTgym container:
- Internal: `http://localhost:8080/flowable-rest/service`
- External (via mitmproxy): `http://localhost:9090/flowable-rest/service`

## Authentication

All endpoints require Basic Authentication:
- Username: `admin`
- Password: `test`

## OpenAPI Format

- **Version**: OpenAPI 3.0.1
- **Format**: YAML
- **Original**: Converted from Swagger 2.0
- **Source**: Flowable Engine v7.x official documentation

## Usage in RESTgym

The OpenAPI specification is used by RESTgym tools for:
- **RESTler**: Automated REST API fuzzing
- **EvoMaster**: Search-based API testing
- **Schemathesis**: Property-based testing
- **Manual Testing**: Understanding available endpoints

## Example Endpoints

### Get Engine Info
```
GET /management/engine
```

### List Process Definitions
```
GET /repository/process-definitions
```

### Start Process Instance
```
POST /runtime/process-instances
Content-Type: application/json
{
  "processDefinitionKey": "myProcess",
  "variables": [
    {
      "name": "var1",
      "value": "value1"
    }
  ]
}
```

### Query Tasks
```
GET /runtime/tasks?assignee=kermit&candidateGroup=management
```

## Notes

- The specification covers the complete Flowable BPMN REST API
- Some endpoints require specific process definitions to be deployed
- Response schemas may vary based on process definition structure
- For complete documentation, see [Flowable Docs](https://www.flowable.com/open-source/docs)

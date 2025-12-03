# Flowable Process API - Database Schema

This directory contains SQL scripts for initializing the Flowable BPMN database.

## Files

- `schema.sql` - Complete Flowable BPMN Engine schema (422 lines)
- `data.sql` - Minimal initial data (comments only)

## Database Configuration

### Default Setup (H2 In-Memory)
```properties
spring.datasource.url=jdbc:h2:mem:flowable;DB_CLOSE_DELAY=-1
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
```

### Auto-Create Schema
Flowable automatically creates the schema when `flowable.database-schema-update=true` is set in `application.properties`. The `schema.sql` file serves as:
1. Documentation of the complete database structure
2. Reference for understanding Flowable tables
3. Optional manual schema creation for other databases

## Schema Structure

### General Tables (ACT_GE_*)
Common engine data shared across modules:
- `ACT_GE_PROPERTY` - Engine version and properties
- `ACT_GE_BYTEARRAY` - Binary data storage (BPMN XML, variables)

### Repository Tables (ACT_RE_*)
Process definitions and deployments:
- `ACT_RE_DEPLOYMENT` - Process deployments (timestamp, name, tenant)
- `ACT_RE_PROCDEF` - Process definitions (key, version, XML resource)
- `ACT_RE_MODEL` - Process models (design-time)

### Runtime Tables (ACT_RU_*)
Active process execution state:
- `ACT_RU_EXECUTION` - Process/sub-process executions
- `ACT_RU_TASK` - User tasks (assignee, priority, due date)
- `ACT_RU_VARIABLE` - Process/task variables (all types)
- `ACT_RU_IDENTITYLINK` - User/group task assignments
- `ACT_RU_JOB` - Asynchronous jobs and timers
- `ACT_RU_EVENT_SUBSCR` - Message/signal event subscriptions
- `ACT_RU_SUSPENDED_JOB` - Suspended jobs
- `ACT_RU_DEADLETTER_JOB` - Failed jobs (max retries)
- `ACT_RU_TIMER_JOB` - Timer-based jobs

### History Tables (ACT_HI_*)
Historical audit data (completed processes):
- `ACT_HI_PROCINST` - Historic process instances
- `ACT_HI_ACTINST` - Historic activity instances
- `ACT_HI_TASKINST` - Historic task instances
- `ACT_HI_VARINST` - Historic variable instances
- `ACT_HI_DETAIL` - Historic variable updates
- `ACT_HI_COMMENT` - Historic comments
- `ACT_HI_ATTACHMENT` - Historic attachments
- `ACT_HI_IDENTITYLINK` - Historic identity links

## Key Relationships

```
ACT_RE_DEPLOYMENT (1)
    ↓
ACT_RE_PROCDEF (N) - Process definitions per deployment
    ↓
ACT_RU_EXECUTION (N) - Running instances
    ↓ ↓ ↓
    ├─ ACT_RU_TASK (N) - User tasks
    ├─ ACT_RU_VARIABLE (N) - Variables
    └─ ACT_RU_JOB (N) - Async jobs
```

## Indexes

The schema includes 11 performance indexes:
- `ACT_IDX_EXEC_BUSKEY` - Business key lookup
- `ACT_IDX_TASK_CREATE` - Task creation time sorting
- `ACT_IDX_IDENT_LNK_USER` - User task queries
- `ACT_IDX_IDENT_LNK_GROUP` - Group task queries
- `ACT_IDX_VARIABLE_TASK_ID` - Task variable access
- `ACT_IDX_PROCDEF_INFO_JSON` - Process definition info
- `ACT_IDX_PROCDEF_INFO_PROC` - Process definition mapping
- `ACT_IDX_JOB_EXECUTION_ID` - Job-execution association
- `ACT_IDX_EVENT_SUBSCR_CONFIG` - Event subscription config
- `ACT_IDX_HI_PRO_INST_END` - Historic instance end time
- `ACT_IDX_HI_PRO_I_BUSKEY` - Historic business key

## Data Population

### Automatic Data
Flowable automatically creates:
- Engine properties (`ACT_GE_PROPERTY`)
- Schema version tracking
- Process definitions when deployed via REST API
- Runtime data during process execution
- History records when processes complete

### Manual Data (Optional)
You can pre-deploy processes by:
1. Placing .bpmn20.xml files in `/api/processes/` (requires code modification)
2. Using REST API after startup: `POST /repository/deployments`
3. Programmatically via Flowable Java API

## Supported Databases

Flowable supports multiple databases:
- **H2** (in-memory) - Current configuration
- **PostgreSQL** - Recommended for production
- **MySQL/MariaDB** - Alternative production option
- **Oracle** - Enterprise option
- **Microsoft SQL Server** - Enterprise option
- **DB2** - Enterprise option

### Switching to PostgreSQL
1. Update `application.properties`:
```properties
spring.datasource.url=jdbc:postgresql://postgres:5432/flowable
spring.datasource.driver-class-name=org.postgresql.Driver
spring.datasource.username=flowable
spring.datasource.password=flowable
```
2. Add PostgreSQL dependency to Flowable WAR or use external database

## Schema Version

Current schema: **7.1.0.1** (Flowable Engine 7.0.1)

Version stored in `ACT_GE_PROPERTY`:
```sql
INSERT INTO ACT_GE_PROPERTY (NAME_, VALUE_, REV_) 
VALUES ('schema.version', '7.1.0.1', 1);
```

## Notes

- The schema supports multi-tenancy via `TENANT_ID_` columns
- All timestamps are `TIMESTAMP` type
- BLOB columns store binary data (BPMN XML, serialized objects)
- Foreign keys are NOT enforced (Flowable manages referential integrity)
- Auto-increment IDs use database-specific sequences

## Resources

- [Flowable Database Documentation](https://www.flowable.com/open-source/docs/bpmn/ch03-Configuration.html#database-configuration)
- [Flowable Database Schema](https://github.com/flowable/flowable-engine/tree/main/modules/flowable-engine/src/main/resources/org/flowable/db)

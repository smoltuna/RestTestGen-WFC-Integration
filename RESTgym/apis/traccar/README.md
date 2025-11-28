# Traccar GPS Tracking System - RESTgym

Complete RESTgym containerization of Traccar GPS tracking server.

## Overview

**Traccar** is an open source GPS tracking system supporting:
- **200+ GPS protocols** - Over 2000 GPS device models supported
- **Real-time tracking** - Live position updates
- **Geofencing** - Location-based alerts
- **Reports** - Route, events, summary, trips, stops
- **Driver management** - Driver assignment and monitoring
- **Notifications** - Email, SMS, push notifications
- **Multi-database support** - H2, MySQL, PostgreSQL, SQL Server

## Project Information

| Property | Value |
|----------|-------|
| **API Name** | Traccar |
| **Version** | 6.10.0 |
| **Language** | Java 17 |
| **Build Tool** | Gradle 9.1.0 |
| **Framework** | Jetty (embedded web server) |
| **Database** | H2 (embedded, auto-init) |
| **Default Port** | 8082 (original), 8080 (RESTgym internal), 9090 (mitmproxy) |
| **Base Path** | `/api` |
| **API Endpoints** | 100+ REST API endpoints |
| **License** | Apache 2.0 |

## RESTgym Structure

```
traccar/
├── Dockerfile                          # Docker image configuration
├── restgym-api-config.yml             # RESTgym configuration
├── README.md                           # This file
├── specifications/                     # OpenAPI specification
│   └── traccar-openapi.yaml           # OpenAPI 3.1 (66 KB, 100+ endpoints)
├── classes/                            # Compiled Java classes
│   └── org/traccar/                   # Package structure
├── dictionaries/                       # DeepREST fuzzing dictionaries
│   └── deeprest/
│       └── traccar.json                # Domain-specific values (500+ values)
├── database/                           # SQL initialization
│   ├── schema.sql                     # Database schema
│   └── data.sql                       # Sample test data
└── infrastructure/                     # RESTgym monitoring tools
    ├── jacoco/
    │   ├── org.jacoco.agent-0.8.7-runtime.jar
    │   ├── org.jacoco.cli-0.8.7.jar
    │   └── collect-coverage-interval.sh
    └── mitmproxy/
        └── store-interactions.py
```

## Quick Start

### Build Docker Image

```bash
cd f:\Desktop\Tesi-RESTAPI\RESTgym\apis\traccar
docker build -t traccar:restgym .
```

**Build time**: ~10-15 minutes (clones and builds Traccar from source)

### Run Container

```bash
docker run -d \
  --name traccar-restgym \
  -p 9090:9090 \
  -p 8080:8080 \
  -e API=traccar \
  -e TOOL=manual \
  -e RUN=1 \
  traccar:restgym
```

### Wait for Startup

Traccar needs ~30-45 seconds to initialize:

```bash
# Follow startup logs
docker logs traccar-restgym -f

# Wait for "Traccar server is ready" message
# OR
# Check status endpoint
curl http://localhost:9090/api/server
```

### Test API Access

```bash
# Get server info (no auth required)
curl http://localhost:9090/api/server

# Login to get session (creates session)
curl -X POST http://localhost:9090/api/session \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=admin@traccar.org&password=admin"

# Get devices (requires authentication)
curl -u admin@traccar.org:admin http://localhost:9090/api/devices

# Get positions
curl -u admin@traccar.org:admin http://localhost:9090/api/positions

# Get geofences
curl -u admin@traccar.org:admin http://localhost:9090/api/geofences
```

## API Endpoints

Traccar provides **100+ REST API endpoints** across multiple categories:

### Server & Session (5 endpoints)
- `GET /api/server` - Server information (public)
- `PUT /api/server` - Update server settings
- `GET /api/session` - Get current session
- `POST /api/session` - Login (create session)
- `DELETE /api/session` - Logout (close session)

### Devices (10+ endpoints)
- `GET /api/devices` - List devices
- `POST /api/devices` - Create device
- `PUT /api/devices/{id}` - Update device
- `DELETE /api/devices/{id}` - Delete device
- `PUT /api/devices/{id}/accumulators` - Update odometer/hours

### Groups (5 endpoints)
- `GET /api/groups` - List groups
- `POST /api/groups` - Create group
- `PUT /api/groups/{id}` - Update group
- `DELETE /api/groups/{id}` - Delete group

### Users (5 endpoints)
- `GET /api/users` - List users
- `POST /api/users` - Create user
- `PUT /api/users/{id}` - Update user
- `DELETE /api/users/{id}` - Delete user

### Positions (4 endpoints)
- `GET /api/positions` - Get positions
- `DELETE /api/positions` - Delete positions (by time range)
- `DELETE /api/positions/{id}` - Delete position by ID

### Geofences (5 endpoints)
- `GET /api/geofences` - List geofences
- `POST /api/geofences` - Create geofence
- `PUT /api/geofences/{id}` - Update geofence
- `DELETE /api/geofences/{id}` - Delete geofence

### Commands (6 endpoints)
- `GET /api/commands` - List saved commands
- `POST /api/commands` - Create command
- `PUT /api/commands/{id}` - Update command
- `DELETE /api/commands/{id}` - Delete command
- `GET /api/commands/send` - List supported commands
- `POST /api/commands/send` - Send command to device
- `GET /api/commands/types` - List command types

### Notifications (6 endpoints)
- `GET /api/notifications` - List notifications
- `POST /api/notifications` - Create notification
- `PUT /api/notifications/{id}` - Update notification
- `DELETE /api/notifications/{id}` - Delete notification
- `GET /api/notifications/types` - List notification types
- `POST /api/notifications/test` - Send test notification

### Events (2 endpoints)
- `GET /api/events/{id}` - Get event by ID

### Reports (5 endpoints)
- `GET /api/reports/route` - Route report
- `GET /api/reports/events` - Events report
- `GET /api/reports/summary` - Summary report
- `GET /api/reports/trips` - Trips report
- `GET /api/reports/stops` - Stops report

### Permissions (2 endpoints)
- `POST /api/permissions` - Link object to another object
- `DELETE /api/permissions` - Unlink objects

### Calendars (5 endpoints)
- `GET /api/calendars` - List calendars
- `POST /api/calendars` - Create calendar
- `PUT /api/calendars/{id}` - Update calendar
- `DELETE /api/calendars/{id}` - Delete calendar

### Attributes (5 endpoints)
- `GET /api/attributes/computed` - List computed attributes
- `POST /api/attributes/computed` - Create computed attribute
- `PUT /api/attributes/computed/{id}` - Update computed attribute
- `DELETE /api/attributes/computed/{id}` - Delete computed attribute

### Drivers (5 endpoints)
- `GET /api/drivers` - List drivers
- `POST /api/drivers` - Create driver
- `PUT /api/drivers/{id}` - Update driver
- `DELETE /api/drivers/{id}` - Delete driver

### Maintenance (5 endpoints)
- `GET /api/maintenance` - List maintenance schedules
- `POST /api/maintenance` - Create maintenance schedule
- `PUT /api/maintenance/{id}` - Update maintenance schedule
- `DELETE /api/maintenance/{id}` - Delete maintenance schedule

### Statistics (1 endpoint)
- `GET /api/statistics` - Get server statistics

## Testing Examples

### Create Device

```bash
curl -X POST http://localhost:9090/api/devices \
  -u admin@traccar.org:admin \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test GPS Tracker",
    "uniqueId": "test123456789",
    "groupId": 1,
    "category": "car",
    "model": "GPS103"
  }'
```

### Create Geofence

```bash
curl -X POST http://localhost:9090/api/geofences \
  -u admin@traccar.org:admin \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Geofence",
    "description": "Test area",
    "area": "CIRCLE (30.5234 -97.6789, 500)"
  }'
```

### Send Command to Device

```bash
curl -X POST http://localhost:9090/api/commands/send \
  -u admin@traccar.org:admin \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": 1,
    "type": "positionSingle"
  }'
```

### Get Route Report

```bash
curl "http://localhost:9090/api/reports/route?deviceId=1&from=2024-11-27T00:00:00Z&to=2024-11-27T23:59:59Z" \
  -u admin@traccar.org:admin
```

## RESTgym Integration

### HTTP Interception (mitmproxy)

All requests via port 9090 are captured:

```bash
# Make API request (automatically captured)
curl -u admin@traccar.org:admin http://localhost:9090/api/devices

# Check interactions database
docker exec traccar-restgym ls -lh /results/traccar/manual/1/interactions.db

# Query interactions
docker exec traccar-restgym sqlite3 /results/traccar/manual/1/interactions.db \
  "SELECT method, url, status_code FROM interactions ORDER BY id DESC LIMIT 10;"
```

### Coverage Analysis

```bash
# Count total requests
docker exec traccar-restgym sqlite3 /results/traccar/manual/1/interactions.db \
  "SELECT COUNT(*) FROM interactions;"

# Count unique endpoints
docker exec traccar-restgym sqlite3 /results/traccar/manual/1/interactions.db \
  "SELECT COUNT(DISTINCT url) FROM interactions;"

# Status code distribution
docker exec traccar-restgym sqlite3 /results/traccar/manual/1/interactions.db \
  "SELECT status_code, COUNT(*) FROM interactions GROUP BY status_code;"
```

## OpenAPI Specification

**File**: `specifications/traccar-openapi.yaml`
- **Format**: OpenAPI 3.1.0
- **Size**: 66 KB (~2470 lines)
- **Endpoints**: 100+ documented endpoints
- **Security**: BasicAuth and ApiKey

## Dictionary

**File**: `dictionaries/deeprest/traccar.json`
- **Categories**: 30+
- **Total values**: 500+

**Key categories**:
- **device_ids, user_ids, group_ids** - Entity IDs
- **device_names** - GPS tracker names
- **device_unique_ids** - IMEI numbers, serial numbers
- **device_protocols** - osmand, gps103, tk103, gl200, etc.
- **geofence_names** - Location names
- **geofence_areas** - CIRCLE and POLYGON definitions
- **command_types** - positionSingle, engineStop, alarmArm, etc.
- **notification_types** - deviceOnline, geofenceEnter, alarm, etc.
- **latitudes, longitudes** - GPS coordinates
- **event_types** - Device events and alarms

## Database

Traccar uses **H2 embedded database** with Liquibase migrations:
- **Auto-initialization**: Database schema created automatically on first startup
- **30+ tables**: Users, devices, positions, geofences, events, commands, etc.
- **Sample data**: 5 users, 10 devices, 8 positions, 5 geofences, 8 events

See `database/README.md` for details.

## Environment Variables

```bash
# RESTgym variables
-e API=traccar              # API slug
-e TOOL=manual              # Testing tool name
-e RUN=1                    # Run number

# Traccar variables (optional)
-e JAVA_OPTS="-Xms512m -Xmx512m"  # JVM memory settings
```

## Port Mapping

| Port | Service | Access |
|------|---------|--------|
| 9090 | mitmproxy | HTTP interception (primary API access) |
| 8080 | Traccar | Direct API access |
| 12345 | JaCoCo | Code coverage |

## Health Checks

```bash
# Server status (no auth)
curl http://localhost:9090/api/server

# Verify server is ready
curl http://localhost:9090/api/server | grep -q "version" && echo "✅ Ready" || echo "❌ Not ready"
```

Docker health check monitors `/api/server` every 30 seconds.

## Logs

```bash
# View startup logs
docker logs traccar-restgym

# Follow logs
docker logs traccar-restgym -f

# View saved logs
docker exec traccar-restgym cat /results/traccar/manual/1/traccar.log
```

## Cleanup

```bash
# Stop container
docker stop traccar-restgym

# Remove container
docker rm traccar-restgym

# Remove image
docker rmi traccar:restgym
```

## Default Credentials

**Email**: `admin@traccar.org`  
**Password**: `admin`

⚠️ **Change password after first login** for production use.

## Important Notes

### Authentication

Traccar uses **email-based authentication** (not username):
- Login: `POST /api/session` with `email` and `password`
- Session-based or HTTP Basic Auth
- API key authentication also supported

### Database

- **H2 embedded**: Auto-initializes on first startup
- **Data persistence**: Stored in `/api/data/database.mv.db`
- **Production**: Can use MySQL, PostgreSQL, or SQL Server

### Devices

- Devices require unique `uniqueId` (typically IMEI)
- 200+ protocols supported
- Devices send position data via TCP/UDP protocols
- REST API used for management only

### Positions

- Positions stored automatically when devices report
- REST API can query historical positions
- WebSocket available for real-time updates

### Geofences

- Supports CIRCLE and POLYGON geometries
- WKT (Well-Known Text) format
- Can be assigned to devices or groups

## Production Considerations

For production deployment:

1. **External Database**:
   ```xml
   <entry key='database.driver'>org.postgresql.Driver</entry>
   <entry key='database.url'>jdbc:postgresql://postgres:5432/traccar</entry>
   <entry key='database.user'>traccar</entry>
   <entry key='database.password'>password</entry>
   ```

2. **Persistent Storage**:
   ```bash
   docker run -v traccar-data:/api/data ...
   ```

3. **SSL/TLS**: Use reverse proxy (nginx, Traefik)

4. **GPS Port Mapping**: Map ports for device protocols (e.g., 5001-5200)

## References

- **Official Website**: https://www.traccar.org/
- **Documentation**: https://www.traccar.org/documentation/
- **API Docs**: https://www.traccar.org/api-reference/
- **Source Code**: https://github.com/traccar/traccar
- **Demo Servers**: https://www.traccar.org/demo-server/

---

**Status**: Complete RESTgym containerization with comprehensive documentation

**Traccar Version**: 6.10.0  
**OpenAPI Endpoints**: 100+  
**Dictionary Values**: 500+  
**Database Tables**: 30+

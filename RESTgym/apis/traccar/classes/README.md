# Traccar Compiled Classes

## Overview

This directory contains the compiled Java bytecode (.class files) extracted from the Traccar tracker-server.jar. These classes are used by **JaCoCo** for code coverage analysis during RESTgym testing.

## Statistics

- **Total .class Files**: 1883
- **Source**: f:\Desktop\Tesi-RESTAPI\traccar\target\tracker-server.jar
- **Java Version**: Java 17 (Traccar 6.10.0)
- **Package Root**: org.traccar.*

## Package Structure

```
classes/
└── org/
    └── traccar/
        ├── api/                    # REST API endpoints (50+ classes)
        ├── model/                  # Data models (Device, Position, User, Event, etc.)
        ├── database/               # Database access layer (DAO, repositories)
        ├── handler/                # GPS data handlers and processors
        ├── protocol/               # 200+ GPS protocol implementations
        ├── config/                 # Configuration management
        ├── helper/                 # Utility classes
        ├── geocoder/               # Reverse geocoding (address lookup)
        ├── geofence/               # Geofencing logic
        ├── reports/                # Report generation
        ├── notification/           # Alert notifications (email, SMS, web, Firebase)
        ├── events/                 # Event processing
        ├── session/                # Session management
        ├── schedule/               # Scheduled tasks
        ├── web/                    # Web framework integration
        ├── storage/                # Storage abstractions
        └── Main.class              # Application entry point
```

## Key Packages

### 1. org.traccar.api (50+ classes)
REST API resource classes for all HTTP endpoints.

**Example Classes**:
- `ServerResource.class` - GET /api/server
- `SessionResource.class` - POST /api/session (login)
- `DeviceResource.class` - CRUD operations for devices
- `UserResource.class` - User management
- `PositionResource.class` - GPS position queries
- `EventResource.class` - Event queries
- `GeofenceResource.class` - Geofence management
- `CommandResource.class` - Device commands
- `ReportResource.class` - Report generation
- `NotificationResource.class` - Alert configuration

### 2. org.traccar.model (30+ classes)
Domain model classes (POJOs) representing database entities.

**Example Classes**:
- `Device.class` - GPS tracking device
- `Position.class` - GPS position data
- `User.class` - User account
- `Event.class` - Device events
- `Geofence.class` - Geographic boundary
- `Group.class` - Device group
- `Command.class` - Device command
- `Notification.class` - Alert configuration
- `Driver.class` - Driver identification
- `Maintenance.class` - Maintenance schedule
- `Calendar.class` - Working hours
- `Attribute.class` - Computed attribute

### 3. org.traccar.protocol (200+ packages)
GPS protocol implementations for 2000+ device models.

**Example Protocols**:
- `Tk103ProtocolDecoder.class` - TK103 GPS tracker
- `Gt06ProtocolDecoder.class` - GT06 GPS tracker
- `St901ProtocolDecoder.class` - ST901 GPS tracker
- `TeltonikaProtocolDecoder.class` - Teltonika devices
- `QuectelProtocolDecoder.class` - Quectel devices
- `ConcoxProtocolDecoder.class` - Concox devices
- `XexunProtocolDecoder.class` - Xexun devices
- `MeiligaoProtocolDecoder.class` - Meiligao devices
- ... (190+ more protocol packages)

Each protocol package includes:
- `*Protocol.class` - Protocol registration
- `*ProtocolDecoder.class` - Data parsing
- `*ProtocolEncoder.class` - Command encoding

### 4. org.traccar.database (20+ classes)
Database access layer using JDBC and Liquibase migrations.

**Example Classes**:
- `DataManager.class` - Database connection manager
- `DeviceManager.class` - Device CRUD operations
- `PermissionsManager.class` - Access control
- `ConnectionManager.class` - Active device connections
- `NotificationManager.class` - Notification handling
- `GeofenceManager.class` - Geofence operations
- `CommandsManager.class` - Command management
- `StatisticsManager.class` - Usage statistics

### 5. org.traccar.handler (30+ classes)
Event handlers and processing pipeline.

**Example Classes**:
- `GeolocationHandler.class` - Cell tower geolocation
- `GeocoderHandler.class` - Reverse geocoding (lat/lon → address)
- `DistanceHandler.class` - Distance calculation
- `EngineHoursHandler.class` - Engine runtime tracking
- `OverspeedEventHandler.class` - Overspeed detection
- `GeofenceEventHandler.class` - Geofence enter/exit detection
- `MotionEventHandler.class` - Movement detection
- `MaintenanceEventHandler.class` - Maintenance alerts
- `FilterHandler.class` - Position filtering (duplicate removal)
- `CopyAttributesHandler.class` - Attribute propagation

### 6. org.traccar.reports (10+ classes)
Report generation (route, events, summary, trips, stops).

**Example Classes**:
- `RouteReportProvider.class` - Route report
- `EventsReportProvider.class` - Events report
- `SummaryReportProvider.class` - Summary report
- `TripsReportProvider.class` - Trips report
- `StopsReportProvider.class` - Stops report
- `ReportUtils.class` - Report utilities

### 7. org.traccar.geofence (5+ classes)
Geofencing algorithms (circle, polygon, polyline).

**Example Classes**:
- `GeofenceCircle.class` - Circle geofence (point-in-circle)
- `GeofencePolygon.class` - Polygon geofence (point-in-polygon)
- `GeofencePolyline.class` - Polyline geofence (point-near-line)
- `GeofenceGeometry.class` - Base geofence class

### 8. org.traccar.geocoder (10+ classes)
Reverse geocoding providers (Google, Nominatim, OpenCage, etc.).

**Example Classes**:
- `GoogleGeocoder.class` - Google Maps Geocoding API
- `NominatimGeocoder.class` - OpenStreetMap Nominatim
- `OpenCageGeocoder.class` - OpenCage Data API
- `BingGeocoder.class` - Bing Maps API
- `MapQuestGeocoder.class` - MapQuest API
- `GisgraphyGeocoder.class` - Gisgraphy API

### 9. org.traccar.notification (10+ classes)
Notification channels (email, SMS, web, Firebase).

**Example Classes**:
- `MailNotificator.class` - Email notifications
- `SmsNotificator.class` - SMS notifications
- `WebNotificator.class` - Web notifications
- `FirebaseNotificator.class` - Firebase Cloud Messaging
- `NotificationFormatter.class` - Message formatting

## JaCoCo Coverage Analysis

### Purpose
These .class files enable **JaCoCo** to instrument and measure code coverage during RESTgym testing. JaCoCo analyzes which classes, methods, and lines are executed by REST API calls.

### Coverage Metrics

1. **Class Coverage**: Percentage of classes executed
2. **Method Coverage**: Percentage of methods called
3. **Line Coverage**: Percentage of code lines executed
4. **Branch Coverage**: Percentage of conditional branches taken
5. **Instruction Coverage**: Percentage of bytecode instructions executed

### Coverage Collection

JaCoCo agent is configured in the Dockerfile:
```dockerfile
CMD java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* \
    -jar /api/tracker-server.jar /database/traccar.xml
```

**JaCoCo Configuration**:
- `includes=*` - Cover all classes (org.traccar.*)
- `output=tcpserver` - TCP dump server mode
- `port=12345` - JaCoCo listens on port 12345
- `address=*` - Accept connections from any host

### Generate Coverage Report

After testing, generate HTML coverage report:

```bash
# Dump coverage data
java -jar /infrastructure/jacoco/org.jacoco.cli-0.8.7.jar dump \
    --address localhost \
    --port 12345 \
    --destfile coverage.exec

# Generate HTML report
java -jar /infrastructure/jacoco/org.jacoco.cli-0.8.7.jar report coverage.exec \
    --classfiles classes/ \
    --sourcefiles /path/to/traccar/src/main/java/ \
    --html coverage-report/ \
    --xml coverage.xml
```

### Expected Coverage

**High Coverage** (>80%):
- **org.traccar.api*** - REST API endpoints (directly tested via HTTP)
- **org.traccar.model*** - Data models (serialized in JSON responses)
- **org.traccar.database*** - Database layer (CRUD operations)

**Medium Coverage** (40-80%):
- **org.traccar.handler*** - Event handlers (triggered by specific conditions)
- **org.traccar.reports*** - Report generation (requires date ranges)
- **org.traccar.geofence*** - Geofencing logic (requires geofence enter/exit)

**Low Coverage** (<40%):
- **org.traccar.protocol*** - GPS protocol decoders (requires real GPS device data)
- **org.traccar.geocoder*** - Geocoding (requires API keys and network)
- **org.traccar.notification*** - Notifications (requires SMTP/SMS configuration)

### Coverage SQL Queries

Query JaCoCo data from SQLite database:

```sql
-- Most covered classes
SELECT class_name, 
       (covered_instructions * 100.0 / total_instructions) as coverage_percent
FROM jacoco_coverage
ORDER BY coverage_percent DESC
LIMIT 20;

-- Least covered classes
SELECT class_name, 
       (covered_instructions * 100.0 / total_instructions) as coverage_percent
FROM jacoco_coverage
WHERE total_instructions > 0
ORDER BY coverage_percent ASC
LIMIT 20;

-- Coverage by package
SELECT SUBSTRING_INDEX(class_name, '.', 3) as package_name,
       AVG(covered_instructions * 100.0 / total_instructions) as avg_coverage
FROM jacoco_coverage
GROUP BY package_name
ORDER BY avg_coverage DESC;
```

## RESTgym Integration

### Directory Requirement
This directory MUST contain **ONLY .class files** (no .properties, .xml, .sql, or other resources). This ensures JaCoCo can analyze pure bytecode without configuration file interference.

### Verification
```bash
# Count .class files
cd f:\Desktop\Tesi-RESTAPI\RESTgym\apis\traccar\classes
find . -name "*.class" | wc -l
# Expected: 1883

# Verify no non-class files
find . -type f ! -name "*.class" | wc -l
# Expected: 0
```

### Class File Size
```bash
# Total size of .class files
du -sh classes/
# Expected: ~5-10 MB (1883 files)
```

## Main Entry Point

**Application Main Class**:
```
org.traccar.Main.class
```

This class contains the `public static void main(String[] args)` method that starts the Traccar server:
- Loads configuration from XML file
- Initializes database connection
- Starts GPS protocol decoders (200+ ports)
- Starts HTTP server (Jersey REST framework)
- Starts background tasks (position processing, event handlers, cleanup)

## Bytecode Version

All .class files compiled with:
- **Java Version**: 17
- **Class File Version**: 61.0 (Java 17)
- **Source Compatibility**: Java 17
- **Target Compatibility**: Java 17

JaCoCo 0.8.7 fully supports Java 17 bytecode.

## Excluded Files

The following file types are **NOT** included in this directory:
- ❌ `.properties` - Configuration files (belong in resources/)
- ❌ `.xml` - Spring/Hibernate configs (belong in resources/)
- ❌ `.sql` - Database scripts (belong in database/)
- ❌ `.html` - Templates (belong in webapp/)
- ❌ `.js` - JavaScript (belong in webapp/)
- ❌ `.css` - Stylesheets (belong in webapp/)
- ❌ `.json` - Data files (belong in resources/)

Only **pure compiled bytecode** (.class) is present.

## Known Limitations

1. **No Source Files**: JaCoCo reports will lack source code highlighting unless source files are provided via `--sourcefiles` parameter
2. **Protocol Coverage**: 200+ GPS protocols cannot be fully tested without real GPS device data
3. **External Dependencies**: Coverage only includes Traccar classes (not third-party libraries in lib/)
4. **Native Methods**: JaCoCo cannot measure coverage of native methods
5. **Reflection**: Dynamic class loading may not be captured in coverage metrics

## Testing Strategy

### High-Priority Classes (API Layer)
Focus testing on these packages for maximum coverage:

```
org.traccar.api.ServerResource
org.traccar.api.SessionResource
org.traccar.api.DeviceResource
org.traccar.api.UserResource
org.traccar.api.PositionResource
org.traccar.api.EventResource
org.traccar.api.GeofenceResource
org.traccar.api.CommandResource
org.traccar.api.NotificationResource
org.traccar.api.GroupResource
org.traccar.api.DriverResource
org.traccar.api.MaintenanceResource
org.traccar.api.CalendarResource
org.traccar.api.AttributeResource
org.traccar.api.StatisticsResource
```

### Coverage Goals

| Package | Target Coverage | Priority |
|---------|----------------|----------|
| org.traccar.api | 90%+ | Critical |
| org.traccar.model | 80%+ | High |
| org.traccar.database | 70%+ | High |
| org.traccar.handler | 50%+ | Medium |
| org.traccar.reports | 60%+ | Medium |
| org.traccar.geofence | 50%+ | Medium |
| org.traccar.protocol | 10%+ | Low |
| org.traccar.geocoder | 10%+ | Low |
| org.traccar.notification | 20%+ | Low |

## References

- JaCoCo Documentation: https://www.jacoco.org/jacoco/trunk/doc/
- Traccar Source Code: https://github.com/traccar/traccar/tree/master/src/main/java
- Java 17 Bytecode: https://docs.oracle.com/javase/specs/jvms/se17/html/
- Class File Format: https://docs.oracle.com/javase/specs/jvms/se17/html/jvms-4.html

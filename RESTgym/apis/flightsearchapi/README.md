# FlightSearchAPI - RESTgym Containerized API

This directory contains the FlightSearchAPI configured for RESTgym REST API testing framework.

## API Information

- **Name**: FlightSearchAPI
- **Version**: 0.0.1-SNAPSHOT
- **Language**: Java 21
- **Framework**: Spring Boot 3.4.1
- **Database**: MongoDB
- **Authentication**: JWT (JSON Web Tokens)
- **Build Tool**: Maven
- **Original Repository**: https://github.com/Rapter1990/flightsearchapi

## API Description

A comprehensive REST API for flight search and booking management featuring:
- User authentication with role-based access control (ADMIN/USER)
- Airport management (CRUD operations)
- Flight management (CRUD operations)
- Flight search (one-way and round-trip)
- JWT token-based authentication
- Spring Boot Actuator for monitoring

## Directory Structure

```
flightsearchapi/
├── Dockerfile                          # RESTgym-compliant Docker configuration
├── restgym-api-config.yml             # RESTgym API configuration
├── README.md                           # This file
├── specifications/                     # OpenAPI documentation
│   ├── flightsearchapi-openapi.json   # OpenAPI 3.0.1 specification
│   └── README.md
├── classes/                            # Compiled Java bytecode (187 .class files)
│   ├── com/case/flightsearchapi/...
│   └── README.md
├── dictionaries/                       # Fuzzing dictionaries
│   ├── deeprest/
│   │   └── flightsearchapi.json       # 200+ domain-specific test values
│   └── README.md
├── database/                           # Database schema documentation
│   └── README.md                      # MongoDB collections and structure
└── infrastructure/                     # RESTgym monitoring tools
    ├── jacoco/                        # Code coverage collection
    │   ├── org.jacoco.agent-0.8.7-runtime.jar
    │   ├── org.jacoco.cli-0.8.7.jar
    │   └── collect-coverage-interval.sh
    ├── mitmproxy/                     # HTTP interaction recording
    │   └── store-interactions.py
    └── README.md
```

## Building the Docker Image

```bash
cd RESTgym/apis/flightsearchapi
docker build -t flightsearchapi:restgym .
```

**Build process:**
1. Installs Java 21, Maven, Python, mitmproxy
2. Clones and builds the FlightSearchAPI from GitHub
3. Copies infrastructure components
4. Configures RESTgym monitoring (JaCoCo + mitmproxy)

## Running the Container

### Standalone (without MongoDB)
```bash
docker run -d \
  -p 9090:9090 \
  -p 12345:12345 \
  -e API=flightsearchapi \
  -e TOOL=manual \
  -e RUN=1 \
  -v $(pwd)/results:/results \
  --name flightsearchapi-test \
  flightsearchapi:restgym
```

### With MongoDB (recommended)
```bash
# Create a Docker network
docker network create restgym-network

# Run MongoDB
docker run -d \
  --name mongodb \
  --network restgym-network \
  -e MONGO_INITDB_DATABASE=flightdatabase \
  mongo:latest

# Run FlightSearchAPI
docker run -d \
  --name flightsearchapi \
  --network restgym-network \
  -p 9090:9090 \
  -p 12345:12345 \
  -e API=flightsearchapi \
  -e TOOL=manual \
  -e RUN=1 \
  -v $(pwd)/results:/results \
  flightsearchapi:restgym
```

## Accessing the API

All requests go through mitmproxy on port 9090:

```bash
# Health check
curl http://localhost:9090/actuator/health

# Register admin user
curl -X POST http://localhost:9090/api/v1/authentication/user/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@test.com",
    "password": "Admin123!",
    "firstName": "Admin",
    "lastName": "User",
    "phoneNumber": "12345678901",
    "userType": "ADMIN"
  }'

# Login
curl -X POST http://localhost:9090/api/v1/authentication/user/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@test.com",
    "password": "Admin123!"
  }'

# Use returned token for authenticated requests
curl http://localhost:9090/api/v1/airports \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Port Configuration

| Port | Service | Access |
|------|---------|--------|
| 8080 | FlightSearchAPI | Internal only (not exposed) |
| 9090 | mitmproxy (reverse proxy) | Public - use this for all API calls |
| 12345 | JaCoCo coverage server | Internal monitoring |

## Environment Variables

- `API` - API identifier (default: flightsearchapi)
- `TOOL` - Testing tool name (default: manual)
- `RUN` - Test run number (default: 1)

Results are stored in: `/results/{API}/{TOOL}/{RUN}/`

## Results Collection

After running tests, collect results:

```bash
# Copy results from container
docker cp flightsearchapi:/results ./results

# Check interactions database
sqlite3 results/flightsearchapi/manual/1/interactions.db \
  "SELECT method, url, status_code FROM interactions;"

# Generate JaCoCo coverage report
# (requires .class files and .exec files)
```

## API Endpoints

### Authentication
- `POST /api/v1/authentication/user/register` - Register new user
- `POST /api/v1/authentication/user/login` - User login
- `POST /api/v1/authentication/user/refresh-token` - Refresh token
- `POST /api/v1/authentication/user/logout` - User logout

### Airports (ADMIN: all operations, USER: read-only)
- `POST /api/v1/airports` - Create airport
- `GET /api/v1/airports` - List airports (paginated)
- `GET /api/v1/airports/{id}` - Get airport by ID
- `PUT /api/v1/airports/{id}` - Update airport
- `DELETE /api/v1/airports/{id}` - Delete airport

### Flights (ADMIN: all operations, USER: read-only)
- `POST /api/v1/flights` - Create flight
- `GET /api/v1/flights` - List flights (paginated)
- `GET /api/v1/flights/{id}` - Get flight by ID
- `PUT /api/v1/flights/{id}` - Update flight
- `DELETE /api/v1/flights/{id}` - Delete flight

### Flight Search
- `POST /api/v1/flights/search` - Search flights (one-way/round-trip)

### Monitoring
- `GET /actuator/health` - Health check
- `GET /actuator/prometheus` - Prometheus metrics
- Other Actuator endpoints (see OpenAPI spec)

## User Roles

- **ADMIN**: Full CRUD access to airports and flights
- **USER**: Read-only access to airports and flights, can search

## Authentication Flow

1. Register: `POST /api/v1/authentication/user/register`
2. Login: `POST /api/v1/authentication/user/login` → Receive `accessToken` and `refreshToken`
3. Use token: Include `Authorization: Bearer {accessToken}` header
4. Refresh when expired: `POST /api/v1/authentication/user/refresh-token`
5. Logout: `POST /api/v1/authentication/user/logout`

## RESTgym Compliance

This containerization follows the RESTgym API template exactly:

✅ Ubuntu 22.04 base image  
✅ `ENV API=flightsearchapi`  
✅ Standard directory structure (`/api`, `/infrastructure`, `/results`)  
✅ JaCoCo agent on port 12345  
✅ mitmproxy reverse proxy on port 9090  
✅ API runs on internal port 8080  
✅ Periodic coverage collection script  
✅ SQLite interaction storage  
✅ Complete OpenAPI 3.0 specification  
✅ DeepREST fuzzing dictionary  
✅ Extracted .class files (no config files)  
✅ Database documentation  
✅ `restgym-api-config.yml` with `enabled: true`  

## Testing with RESTgym

To test this API with RESTgym tools:

1. **Place in RESTgym structure**:
   ```bash
   cp -r flightsearchapi /path/to/RESTgym/apis/
   ```

2. **Update RESTgym configuration**:
   Add `flightsearchapi` to the list of enabled APIs

3. **Run RESTgym tests**:
   ```bash
   cd /path/to/RESTgym
   python run.py --api flightsearchapi --tool deeprest
   ```

## Known Issues & Notes

1. **MongoDB dependency**: API requires MongoDB to function
2. **Startup time**: ~20-30 seconds for full initialization
3. **Authentication required**: Most endpoints need JWT token
4. **Java 21**: Requires JDK 21+ (container has it pre-installed)
5. **Preview features**: Original pom.xml had `--enable-preview` flag (removed for compatibility)

## Troubleshooting

### API not responding
```bash
# Check if API started successfully
docker logs flightsearchapi | grep "Started FlightSearchApiApplication"

# Check if MongoDB is accessible
docker logs flightsearchapi | grep -i mongodb
```

### Authentication issues
```bash
# Verify you registered a user
# Check token expiration (access token: 30 min, refresh: 24h)
# Ensure Authorization header format: "Bearer {token}"
```

### Coverage not collecting
```bash
# Verify JaCoCo port is accessible
docker exec flightsearchapi nc -zv localhost 12345

# Check coverage script is running
docker exec flightsearchapi ps aux | grep jacoco
```

### Interactions not recorded
```bash
# Verify mitmproxy is running
docker exec flightsearchapi ps aux | grep mitmproxy

# Check interactions database
docker exec flightsearchapi ls -lh /results/flightsearchapi/manual/1/
```

## References

- **Original Repository**: https://github.com/Rapter1990/flightsearchapi
- **RESTgym Framework**: https://github.com/SeUniVr/RESTgym
- **RESTgym Template**: https://github.com/SeUniVr/RESTgym/tree/main/apis/%23api-template
- **OpenAPI Specification**: `specifications/flightsearchapi-openapi.json`
- **API Documentation**: See `FlightSearchAPI.md` in the original repository

## License

This containerization follows the original FlightSearchAPI license.

## Maintainer

Containerized for RESTgym by GitHub Copilot AI Assistant
Original API by Sercan Noyan Germiyanoğlu (https://github.com/Rapter1990)

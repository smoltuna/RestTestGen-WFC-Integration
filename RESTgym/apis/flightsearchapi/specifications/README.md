# Specifications Directory

This directory contains the OpenAPI specification for the FlightSearchAPI.

## Files

- `flightsearchapi-openapi.json` - OpenAPI 3.0.1 specification in JSON format

## API Information

- **Version**: 1.0.0
- **Base URL**: http://localhost:1133 (original), http://localhost:8080 (Docker internal), http://localhost:9090 (via mitmproxy)
- **Context Path**: /api/v1

## Endpoints

The API provides the following endpoint groups:

1. **Authentication** (`/api/v1/authentication/user/`)
   - Register, login, refresh token, logout

2. **Airport Management** (`/api/v1/airports/`)
   - CRUD operations for airports

3. **Flight Management** (`/api/v1/flights/`)
   - CRUD operations for flights

4. **Flight Search** (`/api/v1/flights/search`)
   - Search flights with one-way or round-trip options

5. **Actuator** (`/actuator/`)
   - Spring Boot Actuator endpoints for monitoring

## Authentication

The API uses JWT (JSON Web Token) authentication with two user roles:
- **ADMIN**: Full access to all operations
- **USER**: Read-only access to airports and flights

Bearer token must be included in the Authorization header for protected endpoints.

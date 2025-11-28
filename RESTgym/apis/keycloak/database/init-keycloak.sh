#!/bin/bash

# Keycloak Database Initialization Script
# This script creates test realms, users, clients, and roles for RESTgym testing

set -e

echo "=== Keycloak Test Data Initialization ==="
echo "Waiting for Keycloak to be fully ready..."

# Wait for Keycloak to be ready
until curl -sf http://localhost:8080/health/ready > /dev/null 2>&1; do
    echo "Waiting for Keycloak..."
    sleep 5
done

echo "Keycloak is ready. Starting test data initialization..."

# Get admin access token
echo "Getting admin access token..."
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${KEYCLOAK_ADMIN}" \
    -d "password=${KEYCLOAK_ADMIN_PASSWORD}" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r '.access_token')

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" == "null" ]; then
    echo "ERROR: Failed to get admin token"
    exit 1
fi

echo "Admin token obtained successfully"

# Create test realm
echo "Creating test realm..."
curl -s -X POST http://localhost:8080/admin/realms \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "realm": "test-realm",
        "enabled": true,
        "displayName": "Test Realm for RESTgym",
        "displayNameHtml": "<b>RESTgym Test Realm</b>",
        "registrationAllowed": true,
        "loginWithEmailAllowed": true,
        "duplicateEmailsAllowed": false,
        "resetPasswordAllowed": true,
        "editUsernameAllowed": false,
        "bruteForceProtected": false
    }'

echo "Test realm created"

# Create test client
echo "Creating test client..."
curl -s -X POST http://localhost:8080/admin/realms/test-realm/clients \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "clientId": "restgym-client",
        "name": "RESTgym Test Client",
        "description": "OAuth2 client for RESTgym testing",
        "enabled": true,
        "publicClient": false,
        "serviceAccountsEnabled": true,
        "directAccessGrantsEnabled": true,
        "standardFlowEnabled": true,
        "implicitFlowEnabled": false,
        "clientAuthenticatorType": "client-secret",
        "secret": "restgym-secret",
        "redirectUris": ["http://localhost:*", "https://localhost:*"],
        "webOrigins": ["*"],
        "protocol": "openid-connect"
    }'

echo "Test client created"

# Create test roles
echo "Creating test roles..."
for role in "admin" "user" "manager" "developer" "viewer"; do
    curl -s -X POST http://localhost:8080/admin/realms/test-realm/roles \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$role\",
            \"description\": \"Test $role role for RESTgym\"
        }"
    echo "Role '$role' created"
done

# Create test users
echo "Creating test users..."

# User 1: admin
curl -s -X POST http://localhost:8080/admin/realms/test-realm/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "admin",
        "email": "admin@restgym.test",
        "firstName": "Admin",
        "lastName": "User",
        "enabled": true,
        "emailVerified": true,
        "credentials": [{
            "type": "password",
            "value": "admin123",
            "temporary": false
        }]
    }'

# User 2: testuser
curl -s -X POST http://localhost:8080/admin/realms/test-realm/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "testuser",
        "email": "test@restgym.test",
        "firstName": "Test",
        "lastName": "User",
        "enabled": true,
        "emailVerified": true,
        "credentials": [{
            "type": "password",
            "value": "test123",
            "temporary": false
        }]
    }'

# User 3: john.doe
curl -s -X POST http://localhost:8080/admin/realms/test-realm/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "john.doe",
        "email": "john.doe@restgym.test",
        "firstName": "John",
        "lastName": "Doe",
        "enabled": true,
        "emailVerified": true,
        "credentials": [{
            "type": "password",
            "value": "john123",
            "temporary": false
        }]
    }'

# User 4: jane.smith
curl -s -X POST http://localhost:8080/admin/realms/test-realm/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "jane.smith",
        "email": "jane.smith@restgym.test",
        "firstName": "Jane",
        "lastName": "Smith",
        "enabled": true,
        "emailVerified": true,
        "credentials": [{
            "type": "password",
            "value": "jane123",
            "temporary": false
        }]
    }'

# User 5: disabled user
curl -s -X POST http://localhost:8080/admin/realms/test-realm/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "disableduser",
        "email": "disabled@restgym.test",
        "firstName": "Disabled",
        "lastName": "User",
        "enabled": false,
        "emailVerified": false
    }'

echo "Test users created"

# Create test groups
echo "Creating test groups..."
for group in "admins" "users" "developers" "managers"; do
    curl -s -X POST http://localhost:8080/admin/realms/test-realm/groups \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$group\",
            \"attributes\": {
                \"description\": [\"Test $group group for RESTgym\"]
            }
        }"
    echo "Group '$group' created"
done

# Assign roles to admin user
echo "Assigning roles to users..."
ADMIN_USER_ID=$(curl -s http://localhost:8080/admin/realms/test-realm/users?username=admin \
    -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

if [ ! -z "$ADMIN_USER_ID" ] && [ "$ADMIN_USER_ID" != "null" ]; then
    ADMIN_ROLE_ID=$(curl -s http://localhost:8080/admin/realms/test-realm/roles/admin \
        -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.id')
    
    curl -s -X POST http://localhost:8080/admin/realms/test-realm/users/$ADMIN_USER_ID/role-mappings/realm \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "[{
            \"id\": \"$ADMIN_ROLE_ID\",
            \"name\": \"admin\"
        }]"
    
    echo "Admin role assigned to admin user"
fi

# Create sample identity provider
echo "Creating test identity provider..."
curl -s -X POST http://localhost:8080/admin/realms/test-realm/identity-provider/instances \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "alias": "test-oidc",
        "providerId": "oidc",
        "enabled": true,
        "displayName": "Test OIDC Provider",
        "config": {
            "authorizationUrl": "https://test.example.com/auth",
            "tokenUrl": "https://test.example.com/token",
            "clientId": "test-client",
            "clientSecret": "test-secret",
            "defaultScope": "openid profile email"
        }
    }'

echo "Test identity provider created"

# Create sample authentication flow
echo "Creating test authentication flow..."
curl -s -X POST http://localhost:8080/admin/realms/test-realm/authentication/flows \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "alias": "restgym-flow",
        "description": "RESTgym test authentication flow",
        "providerId": "basic-flow",
        "topLevel": true,
        "builtIn": false
    }'

echo "Test authentication flow created"

echo ""
echo "=== Initialization Complete ==="
echo ""
echo "Test realm: test-realm"
echo "Test client: restgym-client (secret: restgym-secret)"
echo ""
echo "Test users created:"
echo "  - admin / admin123 (with admin role)"
echo "  - testuser / test123"
echo "  - john.doe / john123"
echo "  - jane.smith / jane123"
echo "  - disableduser (disabled)"
echo ""
echo "Test roles: admin, user, manager, developer, viewer"
echo "Test groups: admins, users, developers, managers"
echo ""
echo "Get token example:"
echo "curl -X POST http://localhost:9090/realms/test-realm/protocol/openid-connect/token \\"
echo "  -d 'client_id=restgym-client' \\"
echo "  -d 'client_secret=restgym-secret' \\"
echo "  -d 'username=admin' \\"
echo "  -d 'password=admin123' \\"
echo "  -d 'grant_type=password'"
echo ""
echo "Database initialized successfully!"

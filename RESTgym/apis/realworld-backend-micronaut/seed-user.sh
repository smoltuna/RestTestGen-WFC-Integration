#!/bin/bash
# Wait for application to start
sleep 10

# Try to register the test user via API
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "username": "restapitestteam",
      "email": "restapitestteam@gmail.com",
      "password": "universe"
    }
  }' 2>&1 | head -20

echo "User seeding attempted"

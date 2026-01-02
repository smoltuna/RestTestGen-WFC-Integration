#!/bin/sh
# Generates rtg-config.yml and api-config.yml from $API and $PORT env vars

mkdir -p /app/apis/experiment-api/specifications/
cp -R /specifications/* /app/apis/experiment-api/specifications/

# Generate rtg-config.yml (tells RestTestGen which API to test)
cat > /app/rtg-config.yml << EOF
apiUnderTest: experiment-api
strategyClassName: NominalAndErrorStrategy
EOF

# Generate api-config.yml (tells RestTestGen how to connect to the API)
cat > /app/apis/experiment-api/api-config.yml << EOF
specificationFileName: ${API}-openapi.json
host: http://localhost:${PORT}
EOF

# Add authentication file if auth config exists
# Uses native Java WFC auth handler with authFileName
if [ -f "/auth/${API}-auth.yaml" ]; then
    echo "authFileName: /auth/${API}-auth.yaml" >> /app/apis/experiment-api/api-config.yml
fi

echo "Configuration generated for API: ${API} on port ${PORT}"
echo "--- rtg-config.yml ---"
cat /app/rtg-config.yml
echo "--- api-config.yml ---"
cat /app/apis/experiment-api/api-config.yml

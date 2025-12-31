#!/bin/sh
# Generates api-config.yml from $API and $PORT env vars

mkdir -p /app/apis/experiment-api/specifications/
cp -R /specifications/* /app/apis/experiment-api/specifications/

# Generate api-config.yml
cat > /app/apis/experiment-api/api-config.yml << EOF
specificationFileName: ${API}-openapi.json
host: http://localhost:${PORT}
EOF

# Add authentication command if auth config exists
if [ -f "/auth/${API}-auth.yaml" ]; then
    echo "authenticationCommands:" >> /app/apis/experiment-api/api-config.yml
    echo "  default: \"python3 /scripts/wfc-auth.py /auth/${API}-auth.yaml http://localhost:${PORT}\"" >> /app/apis/experiment-api/api-config.yml
fi

echo "Configuration generated for API: ${API} on port ${PORT}"
cat /app/apis/experiment-api/api-config.yml

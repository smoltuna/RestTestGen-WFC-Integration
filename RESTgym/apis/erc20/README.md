# ERC20 REST API - RESTgym Container

This directory contains the RESTgym-compliant containerization of the ERC20 REST API service.

## Overview

**API**: ERC20 Token Standard RESTful Service  
**Language**: Java 8  
**Framework**: Spring Boot 2.1.7  
**Build Tool**: Gradle 5.1.1  
**Blockchain**: Ganache (Ethereum test network)  

## API Description

The ERC20 REST API provides a RESTful interface for creating and managing ERC-20 tokens on an Ethereum blockchain. It supports:

- **Token Deployment**: Create new ERC-20 tokens with custom parameters
- **Token Queries**: Get token name, symbol, decimals, total supply
- **Balance Management**: Check token balances for addresses
- **Token Transfers**: Transfer tokens between addresses
- **Approval System**: Approve token spending by third parties
- **Allowance Queries**: Check approved spending limits

## Directory Structure

```
erc20/
├── Dockerfile                          # RESTgym-compliant Docker image
├── restgym-api-config.yml             # RESTgym configuration (enabled: true)
├── erc20-rest-service-0.1.0.jar       # Compiled application JAR
├── specifications/                     # OpenAPI specifications
│   └── erc20-openapi.json             # OpenAPI 3.0 specification
├── classes/                            # Compiled Java classes (31 files)
│   └── io/blk/erc20/                  # Package structure
│       ├── Application.class
│       ├── Controller.class
│       ├── ContractService.class
│       └── generated/                 # Web3j generated contracts
├── dictionaries/                       # Fuzzing dictionaries
│   └── deeprest/
│       └── erc20.json                 # Domain values (addresses, tokens, amounts)
└── infrastructure/                     # RESTgym metric tools
    ├── jacoco/
    │   ├── org.jacoco.agent-0.8.7-runtime.jar
    │   ├── org.jacoco.cli-0.8.7.jar
    │   └── collect-coverage-interval.sh
    └── mitmproxy/
        └── store-interactions.py      # HTTP interaction recorder
```

## Build Information

### Source
- Repository: https://github.com/web3labs/erc20-rest-service
- Modified `build.gradle` to use compatible web3j versions:
  - `org.web3j:quorum:4.8.4`
  - `org.web3j:core:4.8.7`

### Build Process
1. Built using Docker multi-stage build with `gradle:5.1.1-jdk8`
2. Command: `gradle build -x test --no-daemon`
3. Extracted JAR: `build/libs/erc20-rest-service-0.1.0.jar`
4. Extracted classes: Only `.class` files (no config files)
5. Total class files: 31

### Class Extraction
```bash
# Classes extracted from BOOT-INF/classes/
# Package: io.blk.erc20
# Only .class files included (verified: 0 non-class files)
```

## Docker Image

### Base Image
`ubuntu:22.04`

### Installed Components
- **OpenJDK 17**: Java runtime
- **Node.js & npm**: For Ganache
- **Ganache 7.9.1**: Ethereum test blockchain
- **Python 3 & pip**: For mitmproxy
- **mitmproxy**: HTTP proxy for interaction recording
- **JaCoCo 0.8.7**: Code coverage monitoring

### Exposed Ports
- **9090**: Mitmproxy (API access point)
- **12345**: JaCoCo TCP server
- **8080**: API internal port
- **8545**: Ganache blockchain

### Environment Variables
- `API=erc20`: RESTgym API identifier
- `TOOL`: Testing tool name (set by RESTgym)
- `RUN`: Test run identifier (set by RESTgym)

### Runtime Configuration
- **Ganache Settings**:
  - Deterministic wallet
  - 10 accounts with 100 ETH each
  - Network ID: 1337
  - Default address: `0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1`

- **API Settings**:
  - Node endpoint: `http://localhost:8545` (Ganache)
  - From address: `0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1`
  - Server port: 8080

## RESTgym Integration

### Startup Sequence
1. **Create results directory**: `/results/$API/$TOOL/$RUN`
2. **Start Ganache**: Ethereum test blockchain on port 8545
3. **Start JaCoCo collector**: Coverage dump script (5s interval)
4. **Start mitmproxy**: HTTP proxy on port 9090
5. **Start API**: Spring Boot application with JaCoCo agent

### Metrics Collection
- **Code Coverage**: JaCoCo dumps to `/results/$API/$TOOL/$RUN/*.exec`
- **HTTP Interactions**: SQLite database at `/results/$API/$TOOL/$RUN/interactions.db`
- **Ganache Logs**: `/results/$API/$TOOL/$RUN/ganache.log`

### Interaction Database Schema
```sql
CREATE TABLE http_flows (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME,
    request_method TEXT,
    request_path TEXT,
    request_body TEXT,
    response_status_code INTEGER,
    response_body TEXT,
    duration_ms REAL,
    -- ... additional fields
);
```

## Testing

### Build Image
```bash
cd /path/to/RESTgym/apis/erc20
docker build -t restgym-erc20:latest .
```

### Run Container
```bash
docker run -d \
  -p 9090:9090 \
  -p 12345:12345 \
  -p 8545:8545 \
  -e API=erc20 \
  -e TOOL=manual \
  -e RUN=test-1 \
  --name erc20-test \
  restgym-erc20:latest
```

### Wait for Startup
```bash
# Wait ~30 seconds for all services to start
sleep 30

# Check logs
docker logs erc20-test
```

### Test API
```bash
# Get API configuration
curl http://localhost:9090/config

# Example output:
# {
#   "nodeEndpoint": "http://localhost:8545",
#   "fromAddress": "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1"
# }

# Deploy a token
curl -X POST http://localhost:9090/deploy \
  -H "Content-Type: application/json" \
  -d '{
    "tokenName": "TestToken",
    "tokenSymbol": "TST",
    "initialAmount": 1000000,
    "decimalUnits": 18
  }'

# Example output: "0x1234...abcd" (contract address)

# Query token (replace with actual contract address)
curl http://localhost:9090/0x1234...abcd/name
curl http://localhost:9090/0x1234...abcd/symbol
curl http://localhost:9090/0x1234...abcd/totalSupply
```

### Verify JaCoCo
```bash
# Check JaCoCo is listening
nc -zv localhost 12345
# Output: Connection to localhost 12345 port [tcp/*] succeeded!
```

### Check Interactions
```bash
# Copy database from container
docker cp erc20-test:/results/erc20/manual/test-1/interactions.db .

# Query interactions
sqlite3 interactions.db "SELECT request_method, request_path, response_status_code FROM http_flows LIMIT 10;"
```

### View Coverage
```bash
# Copy coverage files
docker cp erc20-test:/results/erc20/manual/test-1/ ./test-results/

# Generate HTML report
cd test-results
java -jar ../infrastructure/jacoco/org.jacoco.cli-0.8.7.jar report \
  *.exec \
  --classfiles ../classes \
  --html coverage-report

# Open coverage-report/index.html in browser
```

### Cleanup
```bash
docker stop erc20-test
docker rm erc20-test
```

## API Endpoints

### Configuration
- `GET /config` - Get node endpoint and from address

### Token Deployment
- `POST /deploy` - Deploy new ERC-20 token

### Token Information
- `GET /{contractAddress}/name` - Get token name
- `GET /{contractAddress}/symbol` - Get token symbol
- `GET /{contractAddress}/decimals` - Get decimal precision
- `GET /{contractAddress}/totalSupply` - Get total token supply
- `GET /{contractAddress}/version` - Get contract version

### Balance & Transfers
- `GET /{contractAddress}/balanceOf/{ownerAddress}` - Get token balance
- `POST /{contractAddress}/transfer` - Transfer tokens
- `POST /{contractAddress}/transferFrom` - Transfer from approved address

### Approval System
- `POST /{contractAddress}/approve` - Approve spending
- `POST /{contractAddress}/approveAndCall` - Approve and notify contract
- `GET /{contractAddress}/allowance` - Get approved allowance

### Swagger UI
- `http://localhost:9090/swagger-ui.html` - Interactive API documentation
- `http://localhost:9090/v2/api-docs` - Swagger 2.0 spec (converted to OpenAPI 3.0)

## Dictionary Values

The `dictionaries/deeprest/erc20.json` file contains domain-specific values for fuzzing:

### Ethereum Addresses (20 values)
- Ganache default accounts (10 addresses)
- Test addresses (0x0000..., 0x1111..., etc.)
- Real Ethereum addresses for edge cases

### Token Parameters
- **Token Names**: TestToken, MyToken, ERC20Token, etc. (20 values)
- **Token Symbols**: TST, MTK, ERC, etc. (20 values)
- **Amounts**: 0, 1, 10, 100, 1000, ..., 100000000 (20 values)
- **Decimals**: 0, 2, 6, 8, 9, 12, 15, 18, etc. (20 values)

### Coverage
- All API endpoints covered
- Parameter variations for testing
- Edge cases (zero amounts, max values)

## Notes

### No Database
This API does not use a persistent database. All data is stored on the Ganache blockchain, which is ephemeral (resets on container restart).

### Blockchain Dependency
The API requires Ganache to be running. The Dockerfile ensures Ganache starts before the API.

### Quorum Support
The API supports Quorum (private Ethereum) via the `privateFor` header for private transactions. This feature is available but not tested in the standard RESTgym setup.

### Transaction Timing
Blockchain operations can be slow. Some endpoints (especially deploy, transfer, approve) may take 1-5 seconds to respond.

## Troubleshooting

### API not responding
- Check Ganache is running: `docker logs erc20-test | grep Ganache`
- Wait longer for startup (30-60 seconds)
- Check API logs: `docker logs erc20-test | grep "Started Application"`

### JaCoCo not connecting
- Verify agent is loaded: `docker exec erc20-test ps aux | grep jacoco`
- Check port 12345: `nc -zv localhost 12345`

### No interactions recorded
- Ensure requests go through port 9090 (not direct to 8080)
- Check mitmproxy logs: `docker logs erc20-test | grep mitmproxy`

### Ganache errors
- Check blockchain logs: `docker exec erc20-test cat /results/erc20/manual/test-1/ganache.log`
- Verify accounts: `curl http://localhost:9090/config`

## References

- **Original Repository**: https://github.com/web3labs/erc20-rest-service
- **ERC-20 Standard**: https://github.com/ethereum/EIPs/issues/20
- **Web3j Documentation**: https://docs.web3j.io/
- **Ganache Documentation**: https://github.com/trufflesuite/ganache
- **RESTgym Template**: https://github.com/SeUniVr/RESTgym/tree/main/apis/%23api-template

## Version History

- **v1.0** (2024-11-25): Initial RESTgym containerization
  - Fixed web3j version compatibility (4.8.4/4.8.7)
  - Added Ganache blockchain integration
  - Integrated JaCoCo and mitmproxy
  - Created comprehensive dictionary (200+ values)
  - Extracted 31 class files for coverage analysis

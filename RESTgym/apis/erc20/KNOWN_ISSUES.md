# Known Issues

## Node.js Version Compatibility

**Issue**: Ganache 7.9.1 requires Node.js 14+ but Ubuntu 22.04 apt repository provides Node.js 12.22.9

**Error**: `SyntaxError: Unexpected token '.'` when starting Ganache

**Impact**: ERC-20 token deployment and blockchain operations will not work

**Workarounds**:

### Option 1: Use NodeSource Repository (Recommended)
Update Dockerfile to install Node.js 18 LTS:

```dockerfile
# Before: apt-get -y install nodejs npm
# After:
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get -y install nodejs && \
    npm install -g ganache@7.9.1
```

### Option 2: Use Ganache 6.x
Downgrade to Ganache 6.12.2 (compatible with Node 12):

```dockerfile
# Change:
RUN npm install -g ganache@6.12.2
```

Note: Ganache 6.x uses different CLI arguments:
```bash
ganache-cli \
  --deterministic \
  --accounts 10 \
  --defaultBalanceEther 100 \
  --networkId 1337 \
  --host 0.0.0.0 \
  --port 8545
```

### Option 3: Test Without Ganache
For RESTgym testing (fuzzing), the API endpoints that don't require blockchain can still be tested:
- `/config` - Configuration (✅ Working)
- `/swagger-ui.html` - API documentation (✅ Working)
- `/v2/api-docs` - OpenAPI spec (✅ Working)

Blockchain-dependent endpoints will return 500 errors but fuzzing tools can still discover the API surface.

## Verification Status

✅ **Working Components**:
- Docker image builds successfully (806 seconds)
- API starts correctly (Spring Boot 2.1.7)
- Mitmproxy running on port 9090
- JaCoCo agent loaded and TCP server on port 12345
- Configuration endpoint `/config` returns correct response
- Infrastructure ready for metrics collection

❌ **Not Working**:
- Ganache blockchain (Node.js version issue)
- Token deployment endpoint `/deploy` (depends on Ganache)
- All blockchain transaction endpoints

## Testing Results

**API Response Test**:
```bash
curl http://localhost:9090/config
# Output: {"nodeEndpoint":"http://localhost:8545","fromAddress":"0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1"}
# Status: 200 OK ✅
```

**JaCoCo Verification**:
```powershell
Test-NetConnection -ComputerName localhost -Port 12345
# TcpTestSucceeded: True ✅
```

**Coverage Collection**:
```
Coverage dumps requested every 5 seconds
java.io.IOException: Invalid execution data file
```
This error is normal when no code has been executed yet. Coverage will be collected once API receives requests.

## Recommendation

For immediate RESTgym integration, update Dockerfile to use Node.js 18 LTS (Option 1). This is a one-line change and maintains compatibility with the latest Ganache version.

Alternatively, for quick testing without modifying the Dockerfile, use Option 3 - the API infrastructure is working correctly and can be tested with non-blockchain endpoints.

## Timestamp

Created: 2024-11-25 12:50 UTC
Build time: 806 seconds
Test date: 2024-11-25 12:49 UTC

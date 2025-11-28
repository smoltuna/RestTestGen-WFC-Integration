# Database Directory

**Status**: Uses Ganache (Ethereum Blockchain)

This API does not use a traditional SQL database. It interacts with an Ethereum blockchain for data storage.

**Data Storage**:
- **Blockchain**: Ganache (Ethereum test network)
- **Smart Contracts**: ERC-20 token contracts deployed on Ganache
- **Network ID**: 1337
- **RPC Endpoint**: http://localhost:8545
- **No SQL database required**

**Default Accounts**:
Ganache creates 10 deterministic accounts with 100 ETH each:
- Account 0: `0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1` (default sender)
- Account 1-9: Additional test accounts

**Token Data**:
All ERC-20 token data (balances, allowances, supply) is stored on-chain:
- Token name, symbol, decimals
- Total supply
- Address balances
- Approval allowances

The blockchain state persists only during container runtime. Each restart creates a fresh Ganache instance.

"""
ERC20 API - Path rewriting script
Replaces invalid contract addresses with the deployed test contract
"""
import re
from mitmproxy import ctx

class ERC20PathRewriter:
    def __init__(self):
        self.contract_address = None
        self.loaded_address = False
    
    def load_contract_address(self):
        """Load the deployed contract address from file"""
        if self.loaded_address:
            return
        
        try:
            with open("/tmp/erc20_contract_address.txt", "r") as f:
                self.contract_address = f.read().strip()
                ctx.log.info(f"[ERC20] Loaded contract address: {self.contract_address}")
                self.loaded_address = True
        except Exception as e:
            ctx.log.warn(f"[ERC20] Could not load contract address: {e}")
            self.loaded_address = True  # Don't try again
    
    def request(self, flow):
        """Rewrite paths with random contract addresses to use deployed contract"""
        self.load_contract_address()
        
        if not self.contract_address:
            return
        
        # Pattern to match /{contractAddress}/... endpoints
        # Skip /config and /deploy which don't need contract addresses
        if flow.request.path.startswith("/config") or flow.request.path.startswith("/deploy"):
            return
        
        # Match paths like /ANYTHING/decimals, /ANYTHING/name, etc.
        # where ANYTHING is not the valid contract address
        pattern = r'^/([^/]+)/(decimals|name|symbol|totalSupply|balanceOf|allowance|approve|transfer|transferFrom|approveAndCall|version)(/.*)?$'
        match = re.match(pattern, flow.request.path)
        
        if match:
            current_address = match.group(1)
            endpoint = match.group(2)
            rest = match.group(3) or ""
            
            # Only replace if it's not already the correct address
            if current_address.lower() != self.contract_address.lower():
                new_path = f"/{self.contract_address}/{endpoint}{rest}"
                ctx.log.info(f"[ERC20] Rewriting path: {flow.request.path} -> {new_path}")
                flow.request.path = new_path

addons = [ERC20PathRewriter()]

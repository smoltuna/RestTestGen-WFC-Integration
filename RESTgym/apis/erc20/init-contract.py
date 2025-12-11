#!/usr/bin/env python3
"""
Initialize ERC20 test environment by deploying a test contract
"""
import requests
import json
import time
import sys

def deploy_contract(base_url="http://localhost:8080"):
    """Deploy a test ERC20 contract and return its address"""
    
    # Contract specification for deployment
    contract_spec = {
        "initialAmount": 1000000,
        "tokenName": "TestToken",
        "decimalUnits": 18,
        "tokenSymbol": "TST"
    }
    
    print(f"Deploying test contract to {base_url}...")
    
    try:
        response = requests.post(
            f"{base_url}/deploy",
            json=contract_spec,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        if response.status_code in [200, 201]:
            contract_address = response.text.strip().strip('"')
            print(f"Contract deployed successfully: {contract_address}")
            
            # Save contract address to file for tests to use
            with open("/tmp/erc20_contract_address.txt", "w") as f:
                f.write(contract_address)
            
            return contract_address
        else:
            print(f"Failed to deploy contract: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print(f"Error deploying contract: {e}")
        return None

def verify_contract(base_url, contract_address):
    """Verify the deployed contract is working"""
    try:
        # Test the name endpoint
        response = requests.get(f"{base_url}/{contract_address}/name", timeout=10)
        if response.status_code == 200:
            print(f"Contract verification successful - Name: {response.text}")
            return True
        else:
            print(f"Contract verification failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"Error verifying contract: {e}")
        return False

if __name__ == "__main__":
    base_url = "http://localhost:8080"
    
    # Wait for service to be ready
    print("Waiting for ERC20 service to be ready...")
    for i in range(30):
        try:
            response = requests.get(f"{base_url}/config", timeout=2)
            if response.status_code == 200:
                print("ERC20 service is ready!")
                break
        except:
            pass
        time.sleep(2)
    else:
        print("ERC20 service did not become ready in time")
        sys.exit(1)
    
    # Deploy contract
    contract_address = deploy_contract(base_url)
    if contract_address:
        time.sleep(5)  # Wait for contract to be mined
        if verify_contract(base_url, contract_address):
            print("Setup complete!")
            sys.exit(0)
    
    print("Setup failed!")
    sys.exit(1)

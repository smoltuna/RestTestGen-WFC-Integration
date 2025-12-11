#!/usr/bin/env python3
"""
Initialize Gravitee by creating a test user account
"""
import requests
import json
import time
import sys
import base64

def wait_for_gravitee():
    """Wait for Gravitee to be ready"""
    print("Waiting for Gravitee to be ready...")
    for i in range(60):
        try:
            response = requests.get("http://localhost:8083/management/organizations", timeout=2)
            if response.status_code in [200, 401]:  # 401 means it's running but needs auth
                print("Gravitee is ready!")
                return True
        except:
            pass
        time.sleep(1)
    print("Gravitee did not become ready in time")
    return False

def create_user():
    """Create test user using admin credentials"""
    admin_username = "admin"
    admin_password = "admin"
    test_email = "restapitestteam@gmail.com"
    
    # Create admin auth header
    admin_creds = f"{admin_username}:{admin_password}"
    admin_encoded = base64.b64encode(admin_creds.encode()).decode()
    admin_auth = f"Basic {admin_encoded}"
    
    headers = {
        "Authorization": admin_auth,
        "Content-Type": "application/json"
    }
    
    # Try to register the user
    user_data = {
        "email": test_email,
        "firstname": "REST",
        "lastname": "TestTeam",
        "source": "gravitee",
        "newsletter": False
    }
    
    print(f"Creating user {test_email}...")
    
    try:
        # Try user registration endpoint (doesn't require admin)
        response = requests.post(
            "http://localhost:8083/management/organizations/DEFAULT/users/registration",
            json=user_data,
            timeout=10
        )
        
        if response.status_code in [200, 201]:
            print(f"User registration initiated: {response.status_code}")
            print("Note: User may need email confirmation to set password")
            return True
        elif response.status_code == 400:
            print(f"Registration may be disabled or user exists: {response.text}")
            # Try creating as admin instead
            return create_user_as_admin(headers, test_email)
        else:
            print(f"Registration failed: {response.status_code} - {response.text}")
            # Try creating as admin
            return create_user_as_admin(headers, test_email)
            
    except Exception as e:
        print(f"Error during registration: {e}")
        return create_user_as_admin(headers, test_email)

def create_user_as_admin(headers, test_email):
    """Create user using admin API"""
    user_data = {
        "email": test_email,
        "firstname": "REST",
        "lastname": "TestTeam",
        "source": "gravitee",
        "newsletter": False
    }
    
    print(f"Attempting to create user as admin...")
    
    try:
        response = requests.post(
            "http://localhost:8083/management/organizations/DEFAULT/users",
            json=user_data,
            headers=headers,
            timeout=10
        )
        
        if response.status_code in [200, 201]:
            print(f"User created successfully: {response.status_code}")
            user_info = response.json()
            print(f"User ID: {user_info.get('id', 'N/A')}")
            return True
        elif response.status_code == 409:
            print("User already exists")
            return True
        else:
            print(f"Failed to create user: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"Error creating user as admin: {e}")
        return False

def test_authentication():
    """Test if we can authenticate with admin (since we can't set password for new user)"""
    admin_creds = "admin:admin"
    admin_encoded = base64.b64encode(admin_creds.encode()).decode()
    admin_auth = f"Basic {admin_encoded}"
    
    headers = {"Authorization": admin_auth}
    
    print("Testing authentication with admin credentials...")
    
    try:
        response = requests.get(
            "http://localhost:8083/management/organizations/DEFAULT/environments",
            headers=headers,
            timeout=5
        )
        
        if response.status_code == 200:
            print(f"✓ Authentication successful! Status: {response.status_code}")
            return True
        else:
            print(f"✗ Authentication failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"Error testing authentication: {e}")
        return False

if __name__ == "__main__":
    if not wait_for_gravitee():
        print("Setup failed: Gravitee not ready")
        sys.exit(1)
    
    # Try to create user (though we'll use admin creds for auth)
    create_user()
    
    # Test authentication
    if test_authentication():
        print("\n✓ Setup complete! API is ready for testing.")
        print("Note: Using admin credentials since Gravitee requires email confirmation for password setup")
        sys.exit(0)
    else:
        print("\n✗ Setup incomplete: Authentication test failed")
        sys.exit(1)

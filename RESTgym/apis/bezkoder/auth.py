"""
BezKoder Swagger Example - Authentication Script
JWT Bearer Token with signup and login
"""
import requests
import json

class BezKoderAuth:
    def __init__(self):
        self.token = None
        self.base_url = "http://localhost:8080"
    
    def get_token(self):
        if self.token is None:
            try:
                # Signup
                signup_url = f"{self.base_url}/api/auth/signup"
                signup_payload = {
                    "username": "restgym_test",
                    "email": "restgym.test@gmail.com",
                    "password": "RESTgym2024!",
                    "role": ["user"]
                }
                headers = {
                    "Content-Type": "application/json",
                    "Accept": "application/json"
                }
                
                # Try signup (might fail if user exists)
                signup_response = requests.post(signup_url, json=signup_payload, headers=headers, timeout=5)
                
                # Login
                login_url = f"{self.base_url}/api/auth/signin"
                login_payload = {
                    "username": "restgym_test",
                    "password": "RESTgym2024!"
                }
                login_response = requests.post(login_url, json=login_payload, headers=headers, timeout=5)
                
                if login_response.status_code == 200:
                    self.token = login_response.json()["accessToken"]
                    print(f"[BezKoder Auth] Token obtained")
                else:
                    print(f"[BezKoder Auth] Login failed: {login_response.status_code}")
            except Exception as e:
                print(f"[BezKoder Auth] Error: {e}")
        
        return self.token
    
    def request(self, flow):
        # Skip auth endpoints
        if "/api/auth/" in flow.request.pretty_url:
            return
        
        token = self.get_token()
        if token:
            flow.request.headers["Authorization"] = f"Bearer {token}"

addons = [BezKoderAuth()]

import requests
from mitmproxy import http

class QuartzAuthJWT:
    def __init__(self):
        self.username = "restapitestteam@gmail.com"
        self.password = "universe"
        self.jwt_token = None
        self.login_url = "http://localhost:8080/quartz-manager/auth/login"
        self.context_path = "/quartz-manager"
        
    def get_jwt_token(self):
        if self.jwt_token:
            return self.jwt_token
        
        try:
            response = requests.post(
                self.login_url,
                data={"username": self.username, "password": self.password},
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                timeout=5
            )
            
            if response.status_code == 200:
                token_data = response.json()
                self.jwt_token = token_data.get('accessToken')
                if self.jwt_token:
                    print(f"[QuartzAuth] Successfully obtained JWT token")
                return self.jwt_token
            else:
                print(f"[QuartzAuth] Login failed: {response.status_code}")
        except Exception as e:
            print(f"[QuartzAuth] Error: {e}")
        
        return None
    
    def request(self, flow: http.HTTPFlow):
        if "/auth/login" not in flow.request.path and self.context_path in flow.request.path:
            token = self.get_jwt_token()
            if token:
                flow.request.headers["Authorization"] = f"Bearer {token}"

addons = [QuartzAuthJWT()]

"""
WFC auth handler for mitmproxy.
"""
import os
import sys
import json
import requests
import yaml
from mitmproxy import http, ctx
from urllib.parse import urljoin


class WFCAuth:
    """Reads auth.yaml and applies auth headers to intercepted requests."""
    
    def __init__(self):
        self.api_name = os.environ.get('API', 'unknown')
        self.auth_config = None
        self.auth_users = []
        self.current_user_index = 0
        self.tokens = {}  # Cache tokens per user
        self.base_url = "http://localhost:8080"
        self.initialized = False
        self.signup_done = {}  # Track signup per user
        
        print(f"[WFC-AUTH] Initializing for API: {self.api_name}", file=sys.stderr)
        self._load_auth_config()
    
    def _load_auth_config(self):
        """Load auth.yaml configuration file"""
        auth_path = f"/api/auth.yaml"
        
        if not os.path.exists(auth_path):
            print(f"[WFC-AUTH] No auth.yaml found at {auth_path}, authentication disabled", file=sys.stderr)
            return
        
        try:
            with open(auth_path, 'r') as f:
                self.auth_config = yaml.safe_load(f)
            
            if not self.auth_config or 'auth' not in self.auth_config:
                print(f"[WFC-AUTH] Invalid auth.yaml - missing 'auth' array", file=sys.stderr)
                return
            
            # Apply authTemplate to all auth entries
            template = self.auth_config.get('authTemplate', {})
            
            # Get baseUrl from authTemplate or use default
            self.base_url = template.get('baseUrl', 'http://localhost:8080')
            print(f"[WFC-AUTH] Using base URL: {self.base_url}", file=sys.stderr)
            
            self.auth_users = []
            
            for user in self.auth_config['auth']:
                merged_user = self._merge_with_template(user, template)
                self.auth_users.append(merged_user)
                print(f"[WFC-AUTH] Loaded user: {merged_user.get('name', 'unnamed')}", file=sys.stderr)
            
            self.initialized = True
            print(f"[WFC-AUTH] Loaded {len(self.auth_users)} user(s) from auth.yaml", file=sys.stderr)
            
        except Exception as e:
            print(f"[WFC-AUTH] Error loading auth.yaml: {e}", file=sys.stderr)
    
    def _merge_with_template(self, user, template):
        """Merge user config with template (user values take precedence)"""
        merged = dict(template)
        
        for key, value in user.items():
            if key == 'loginEndpointAuth' and 'loginEndpointAuth' in merged:
                # Deep merge loginEndpointAuth
                merged_login = dict(merged.get('loginEndpointAuth', {}))
                if isinstance(value, dict):
                    for login_key, login_value in value.items():
                        if login_key == 'token' and 'token' in merged_login:
                            # Deep merge token config
                            merged_token = dict(merged_login.get('token', {}))
                            if isinstance(login_value, dict):
                                merged_token.update(login_value)
                            merged_login['token'] = merged_token
                        elif login_value is not None:
                            merged_login[login_key] = login_value
                merged['loginEndpointAuth'] = merged_login
            elif value is not None:
                merged[key] = value
        
        return merged
    
    def _get_current_user(self):
        """Get the current user configuration (uses first user by default)"""
        if not self.auth_users:
            return None
        return self.auth_users[0]  # Use first user for simplicity
    
    def _extract_token_from_json(self, json_data, json_pointer):
        """Extract value from JSON using JSON Pointer"""
        if not json_pointer:
            return None
        
        # Remove leading slash and split
        parts = json_pointer.lstrip('/').split('/')
        
        try:
            result = json_data
            for part in parts:
                if isinstance(result, dict):
                    result = result.get(part)
                elif isinstance(result, list):
                    result = result[int(part)]
                else:
                    return None
            return result
        except (KeyError, IndexError, ValueError, TypeError):
            return None
    
    def _perform_signup(self, user):
        """Perform user signup/registration (extension to WFC schema)"""
        user_name = user.get('name', 'unnamed')
        
        # Check if already signed up
        if user_name in self.signup_done:
            return True
        
        signup_config = user.get('signupEndpoint')
        if not signup_config:
            # No signup required
            self.signup_done[user_name] = True
            return True
        
        endpoint = signup_config.get('endpoint', '')
        verb = signup_config.get('verb', 'POST').upper()
        content_type = signup_config.get('contentType', 'application/json')
        payload_raw = signup_config.get('payloadRaw', '')
        
        signup_url = urljoin(self.base_url, endpoint)
        headers = {'Content-Type': content_type, 'Accept': 'application/json'}
        
        print(f"[WFC-AUTH] Performing signup for {user_name} at {signup_url}", file=sys.stderr)
        
        try:
            if verb == 'POST':
                response = requests.post(signup_url, data=payload_raw, headers=headers, timeout=10)
            else:
                response = requests.request(verb, signup_url, data=payload_raw, headers=headers, timeout=10)
            
            print(f"[WFC-AUTH] Signup response: {response.status_code}", file=sys.stderr)
            
            # Signup can fail if user already exists (409, 422, 400) - that's OK
            if response.status_code in [200, 201, 409, 422, 400]:
                self.signup_done[user_name] = True
                return True
            else:
                print(f"[WFC-AUTH] Signup failed: {response.text[:200]}", file=sys.stderr)
                return False
                
        except Exception as e:
            print(f"[WFC-AUTH] Signup error: {e}", file=sys.stderr)
            # Mark as done anyway to avoid retry loop
            self.signup_done[user_name] = True
            return False
    
    def _perform_login(self, user):
        """Perform login and extract token/cookies based on WFC config"""
        user_name = user.get('name', 'unnamed')
        login_config = user.get('loginEndpointAuth')
        
        if not login_config:
            print(f"[WFC-AUTH] No loginEndpointAuth for user {user_name}", file=sys.stderr)
            return None
        
        # Determine login URL
        endpoint = login_config.get('endpoint', '')
        external_url = login_config.get('externalEndpointURL')
        
        if external_url:
            login_url = external_url
        else:
            login_url = urljoin(self.base_url, endpoint)
        
        # Prepare request
        verb = login_config.get('verb', 'POST').upper()
        content_type = login_config.get('contentType', 'application/json')
        
        headers = {'Content-Type': content_type}
        
        # Add any additional headers from config
        for header in login_config.get('headers', []):
            headers[header['name']] = header['value']
        
        # Prepare payload
        payload = None
        payload_raw = login_config.get('payloadRaw')
        payload_user_pwd = login_config.get('payloadUserPwd')
        
        if payload_raw:
            payload = payload_raw
        elif payload_user_pwd:
            username = payload_user_pwd.get('username')
            password = payload_user_pwd.get('password')
            username_field = payload_user_pwd.get('usernameField', 'username')
            password_field = payload_user_pwd.get('passwordField', 'password')
            
            if 'json' in content_type.lower():
                payload = json.dumps({username_field: username, password_field: password})
            else:
                payload = f"{username_field}={username}&{password_field}={password}"
        
        print(f"[WFC-AUTH] Performing login for {user_name} at {login_url}", file=sys.stderr)
        
        try:
            if verb == 'POST':
                response = requests.post(login_url, data=payload, headers=headers, timeout=10)
            elif verb == 'GET':
                response = requests.get(login_url, headers=headers, timeout=10)
            else:
                print(f"[WFC-AUTH] Unsupported verb: {verb}", file=sys.stderr)
                return None
            
            print(f"[WFC-AUTH] Login response: {response.status_code}", file=sys.stderr)
            
            if response.status_code not in [200, 201]:
                print(f"[WFC-AUTH] Login failed: {response.text[:200]}", file=sys.stderr)
                return None
            
            # Handle token extraction ()
            token_config = login_config.get('token')
            if token_config:
                # uses extractFromField (JSON pointer)
                extract_from_field = token_config.get('extractFromField')
                
                if extract_from_field:
                    try:
                        json_response = response.json()
                        token = self._extract_token_from_json(json_response, extract_from_field)
                        if token:
                            # Extract duration: expires_in (seconds), expiresIn (seconds), or exp (unix timestamp)
                            duration = None
                            for field in ['expires_in', 'expiresIn']:
                                if field in json_response and isinstance(json_response[field], (int, float)):
                                    duration = int(json_response[field])
                                    break
                            if duration is None and 'exp' in json_response:
                                import time
                                exp_value = json_response.get('exp')
                                if isinstance(exp_value, (int, float)):
                                    duration = max(0, int(exp_value) - int(time.time()))
                            
                            self.tokens[user_name] = {
                                'token': token,
                                'config': token_config,
                                'duration': duration
                            }
                            print(f"[WFC-AUTH] Extracted token for {user_name}", file=sys.stderr)
                            return token
                        else:
                            print(f"[WFC-AUTH] Failed to extract token using {extract_from_field}", file=sys.stderr)
                    except json.JSONDecodeError:
                        print(f"[WFC-AUTH] Failed to parse JSON response", file=sys.stderr)
            
            return None
            
        except Exception as e:
            print(f"[WFC-AUTH] Login error: {e}", file=sys.stderr)
            return None
    
    def _get_auth_headers(self, user):
        """Get authentication headers for a user"""
        user_name = user.get('name', 'unnamed')
        headers = {}
        
        # Check for fixed headers first
        fixed_headers = user.get('fixedHeaders', [])
        if fixed_headers:
            for header in fixed_headers:
                headers[header['name']] = header['value']
            return headers
        
        # Check for cached token
        if user_name in self.tokens:
            token_data = self.tokens[user_name]
            token = token_data['token']
            token_config = token_data['config']
            
            # : httpHeaderName and headerPrefix
            header_name = token_config.get('httpHeaderName', 'Authorization')
            header_prefix = token_config.get('headerPrefix', '')
            
            headers[header_name] = f"{header_prefix}{token}"
            return headers
        
        # Need to perform login (with signup first if configured)
        login_config = user.get('loginEndpointAuth')
        if login_config:
            # Perform signup first if needed
            self._perform_signup(user)
            
            self._perform_login(user)
            
            # Try again after login
            if user_name in self.tokens:
                token_data = self.tokens[user_name]
                token = token_data['token']
                token_config = token_data['config']
                
                # : httpHeaderName and headerPrefix
                header_name = token_config.get('httpHeaderName', 'Authorization')
                header_prefix = token_config.get('headerPrefix', '')
                
                headers[header_name] = f"{header_prefix}{token}"
        
        return headers
    
    def _should_skip_auth(self, path):
        """Check if path should skip authentication (login endpoints, etc.)"""
        user = self._get_current_user()
        if not user:
            return True
        
        login_config = user.get('loginEndpointAuth', {})
        login_endpoint = login_config.get('endpoint', '')
        
        # Skip auth for login endpoint itself
        if login_endpoint and login_endpoint in path:
            return True
        
        # Common patterns to skip
        skip_patterns = [
            '/login', '/signin', '/signup', '/register', 
            '/auth/', '/token', '/oauth', '/openid-connect'
        ]
        
        for pattern in skip_patterns:
            if pattern in path.lower():
                return True
        
        return False
    
    def request(self, flow: http.HTTPFlow):
        """Intercept requests and add authentication"""
        if not self.initialized or not self.auth_users:
            return
        
        path = flow.request.path
        
        # Skip authentication for login endpoints
        if self._should_skip_auth(path):
            print(f"[WFC-AUTH] Skipping auth for: {path}", file=sys.stderr)
            return
        
        user = self._get_current_user()
        if not user:
            return
        
        # Get authentication headers
        auth_headers = self._get_auth_headers(user)
        
        # Apply headers to request
        for name, value in auth_headers.items():
            flow.request.headers[name] = value
            print(f"[WFC-AUTH] Added header {name} to {path}", file=sys.stderr)
        
        # Apply cookies if available
        user_name = user.get('name', 'unnamed')
        if user_name in self.cookies:
            cookie_str = '; '.join([f"{k}={v}" for k, v in self.cookies[user_name].items()])
            if cookie_str:
                existing_cookies = flow.request.headers.get('Cookie', '')
                if existing_cookies:
                    flow.request.headers['Cookie'] = f"{existing_cookies}; {cookie_str}"
                else:
                    flow.request.headers['Cookie'] = cookie_str
                print(f"[WFC-AUTH] Added cookies to {path}", file=sys.stderr)


# Create addon instance
addons = [WFCAuth()]

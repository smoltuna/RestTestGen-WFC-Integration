"""
RESTgym mitmproxy addon - Store HTTP interactions in SQLite database
Captures HTTP request/response data for REST API testing analysis
"""
import os
import sqlite3
import json
from datetime import datetime
from mitmproxy import http

class InteractionRecorder:
    def __init__(self):
        # Get environment variables for results path
        api = os.environ.get('API', 'unknown')
        tool = os.environ.get('TOOL', 'manual')
        run = os.environ.get('RUN', '1')
        
        # Create database path
        db_path = f"/results/{api}/{tool}/{run}/interactions.db"
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        
        # Initialize SQLite database
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
        self.conn.execute('''
            CREATE TABLE IF NOT EXISTS http_flows (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                request_method TEXT NOT NULL,
                request_scheme TEXT,
                request_host TEXT,
                request_port INTEGER,
                request_path TEXT NOT NULL,
                request_query TEXT,
                request_headers TEXT,
                request_body TEXT,
                response_status_code INTEGER,
                response_reason TEXT,
                response_headers TEXT,
                response_body TEXT,
                duration_ms REAL,
                error TEXT
            )
        ''')
        self.conn.commit()
        print(f"✅ Interactions database initialized: {db_path}")
    
    def request(self, flow: http.HTTPFlow):
        """Called when request is received"""
        flow.metadata['start_time'] = datetime.now()
    
    def response(self, flow: http.HTTPFlow):
        """Called when response is received - store interaction"""
        try:
            # Calculate duration
            start_time = flow.metadata.get('start_time')
            duration_ms = None
            if start_time:
                duration_ms = (datetime.now() - start_time).total_seconds() * 1000
            
            # Extract request data
            req = flow.request
            request_headers = json.dumps(dict(req.headers))
            request_body = None
            if req.content:
                try:
                    request_body = req.content.decode('utf-8', errors='ignore')[:10000]  # Limit size
                except:
                    request_body = f"<binary data: {len(req.content)} bytes>"
            
            # Extract response data
            resp = flow.response
            response_headers = json.dumps(dict(resp.headers))
            response_body = None
            if resp.content:
                try:
                    response_body = resp.content.decode('utf-8', errors='ignore')[:10000]  # Limit size
                except:
                    response_body = f"<binary data: {len(resp.content)} bytes>"
            
            # Insert into database
            self.conn.execute('''
                INSERT INTO http_flows (
                    request_method, request_scheme, request_host, request_port,
                    request_path, request_query, request_headers, request_body,
                    response_status_code, response_reason, response_headers, response_body,
                    duration_ms
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                req.method,
                req.scheme,
                req.host,
                req.port,
                req.path,
                req.query_string.decode('utf-8', errors='ignore') if req.query_string else None,
                request_headers,
                request_body,
                resp.status_code,
                resp.reason,
                response_headers,
                response_body,
                duration_ms
            ))
            self.conn.commit()
            
        except Exception as e:
            error_msg = f"Error recording interaction: {e}"
            print(f"❌ {error_msg}")
            try:
                self.conn.execute(
                    'INSERT INTO http_flows (request_method, request_path, error) VALUES (?, ?, ?)',
                    (flow.request.method, flow.request.path, error_msg)
                )
                self.conn.commit()
            except:
                pass
    
    def error(self, flow: http.HTTPFlow):
        """Called when error occurs"""
        try:
            error_msg = str(flow.error) if flow.error else "Unknown error"
            self.conn.execute(
                'INSERT INTO http_flows (request_method, request_path, error) VALUES (?, ?, ?)',
                (flow.request.method, flow.request.path, error_msg)
            )
            self.conn.commit()
        except Exception as e:
            print(f"❌ Error recording error: {e}")

# Register addon
addons = [InteractionRecorder()]

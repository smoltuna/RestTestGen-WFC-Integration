"""
Mitmproxy addon to store HTTP interactions in SQLite database
Records all HTTP requests/responses for RESTgym testing (Spring Kafka Producer API)
"""
import os
import sqlite3
import json
from datetime import datetime
from mitmproxy import http

class InteractionRecorder:
    def __init__(self):
        # Get RESTgym environment variables
        api = os.environ.get('API', 'unknown')
        tool = os.environ.get('TOOL', 'manual')
        run = os.environ.get('RUN', 'run-1')
        
        # Create database in results directory
        db_path = f"/results/{api}/{tool}/{run}/interactions.db"
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
        self._create_tables()
        print(f"✅ Interactions database initialized: {db_path}")
    
    def _create_tables(self):
        """Create database tables for storing HTTP interactions"""
        self.conn.execute('''
            CREATE TABLE IF NOT EXISTS http_flows (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                request_method TEXT,
                request_scheme TEXT,
                request_host TEXT,
                request_port INTEGER,
                request_path TEXT,
                request_http_version TEXT,
                request_headers TEXT,
                request_content_length INTEGER,
                request_body TEXT,
                response_status_code INTEGER,
                response_reason TEXT,
                response_http_version TEXT,
                response_headers TEXT,
                response_content_length INTEGER,
                response_body TEXT,
                duration_ms REAL
            )
        ''')
        
        self.conn.execute('''
            CREATE INDEX IF NOT EXISTS idx_method_path 
            ON http_flows(request_method, request_path)
        ''')
        
        self.conn.execute('''
            CREATE INDEX IF NOT EXISTS idx_status 
            ON http_flows(response_status_code)
        ''')
        
        self.conn.execute('''
            CREATE INDEX IF NOT EXISTS idx_timestamp 
            ON http_flows(timestamp)
        ''')
        
        self.conn.commit()
    
    def response(self, flow: http.HTTPFlow):
        """Called when a response is received"""
        try:
            # Extract request data
            req_headers = dict(flow.request.headers)
            req_body = ""
            if flow.request.content:
                try:
                    req_body = flow.request.content.decode('utf-8', errors='ignore')[:10000]
                except:
                    req_body = str(flow.request.content[:10000])
            
            # Extract response data
            resp_headers = dict(flow.response.headers)
            resp_body = ""
            if flow.response.content:
                try:
                    resp_body = flow.response.content.decode('utf-8', errors='ignore')[:10000]
                except:
                    resp_body = str(flow.response.content[:10000])
            
            # Calculate duration
            duration = None
            if hasattr(flow, 'response') and flow.response:
                if hasattr(flow.response, 'timestamp_end') and hasattr(flow.request, 'timestamp_start'):
                    duration = (flow.response.timestamp_end - flow.request.timestamp_start) * 1000
            
            # Insert into database
            self.conn.execute('''
                INSERT INTO http_flows (
                    request_method, request_scheme, request_host, request_port,
                    request_path, request_http_version, request_headers,
                    request_content_length, request_body,
                    response_status_code, response_reason, response_http_version,
                    response_headers, response_content_length, response_body,
                    duration_ms
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                flow.request.method,
                flow.request.scheme,
                flow.request.host,
                flow.request.port,
                flow.request.path,
                flow.request.http_version,
                json.dumps(req_headers),
                len(flow.request.content) if flow.request.content else 0,
                req_body,
                flow.response.status_code,
                flow.response.reason,
                flow.response.http_version,
                json.dumps(resp_headers),
                len(flow.response.content) if flow.response.content else 0,
                resp_body,
                duration
            ))
            
            self.conn.commit()
            
            # Log interaction
            print(f"[{datetime.now().strftime('%H:%M:%S')}] "
                  f"{flow.request.method} {flow.request.path} -> "
                  f"{flow.response.status_code} ({duration:.1f}ms)" if duration else "")
            
        except Exception as e:
            print(f"❌ Error recording interaction: {e}")
    
    def done(self):
        """Called when mitmproxy shuts down"""
        if self.conn:
            # Get statistics
            cursor = self.conn.execute('SELECT COUNT(*) FROM http_flows')
            count = cursor.fetchone()[0]
            print(f"\n📊 Recorded {count} HTTP interactions")
            
            cursor = self.conn.execute('''
                SELECT response_status_code, COUNT(*) 
                FROM http_flows 
                GROUP BY response_status_code 
                ORDER BY response_status_code
            ''')
            print("\n📈 Status code distribution:")
            for status, count in cursor.fetchall():
                print(f"  {status}: {count}")
            
            self.conn.close()

# Register addon
addons = [InteractionRecorder()]

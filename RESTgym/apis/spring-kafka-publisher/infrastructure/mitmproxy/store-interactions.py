"""
Mitmproxy addon for RESTgym: Records HTTP interactions to SQLite database
Stores requests/responses with timing and metadata for fuzzing analysis
"""
import sqlite3
import json
import os
from datetime import datetime
from mitmproxy import http, ctx


class InteractionRecorder:
    def __init__(self):
        self.api = os.getenv("API", "unknown")
        self.tool = os.getenv("TOOL", "unknown")
        self.run = os.getenv("RUN", "unknown")
        
        # Create results directory
        self.results_dir = f"/results/{self.api}/{self.tool}/{self.run}"
        os.makedirs(self.results_dir, exist_ok=True)
        
        # Initialize database
        self.db_path = f"{self.results_dir}/interactions.db"
        self.conn = sqlite3.connect(self.db_path)
        self.create_tables()
        self.request_count = 0
        
    def create_tables(self):
        """Create SQLite tables for storing HTTP interactions"""
        cursor = self.conn.cursor()
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS interactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                method TEXT NOT NULL,
                path TEXT NOT NULL,
                status_code INTEGER,
                request_headers TEXT,
                request_body TEXT,
                response_headers TEXT,
                response_body TEXT,
                duration_ms REAL,
                error TEXT
            )
        """)
        
        # Indexes for common queries
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_method_path ON interactions(method, path)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_status ON interactions(status_code)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_timestamp ON interactions(timestamp)")
        
        self.conn.commit()
        
    def request(self, flow: http.HTTPFlow):
        """Called when request is received"""
        flow.metadata["start_time"] = datetime.now()
        
    def response(self, flow: http.HTTPFlow):
        """Called when response is complete - record to database"""
        try:
            # Calculate duration
            start_time = flow.metadata.get("start_time")
            duration_ms = None
            if start_time:
                duration_ms = (datetime.now() - start_time).total_seconds() * 1000
            
            # Extract request data
            method = flow.request.method
            path = flow.request.path
            request_headers = dict(flow.request.headers)
            request_body = flow.request.content.decode("utf-8", errors="replace") if flow.request.content else None
            
            # Extract response data
            status_code = flow.response.status_code
            response_headers = dict(flow.response.headers)
            response_body = flow.response.content.decode("utf-8", errors="replace") if flow.response.content else None
            
            # Insert into database
            cursor = self.conn.cursor()
            cursor.execute("""
                INSERT INTO interactions 
                (timestamp, method, path, status_code, request_headers, request_body,
                 response_headers, response_body, duration_ms, error)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                datetime.now().isoformat(),
                method,
                path,
                status_code,
                json.dumps(request_headers),
                request_body,
                json.dumps(response_headers),
                response_body,
                duration_ms,
                None
            ))
            self.conn.commit()
            self.request_count += 1
            
            ctx.log.info(f"Recorded: {method} {path} -> {status_code} ({duration_ms:.2f}ms)")
            
        except Exception as e:
            ctx.log.error(f"Error recording interaction: {e}")
            
    def error(self, flow: http.HTTPFlow):
        """Called when an error occurs"""
        try:
            cursor = self.conn.cursor()
            cursor.execute("""
                INSERT INTO interactions 
                (timestamp, method, path, status_code, request_headers, request_body, error)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                datetime.now().isoformat(),
                flow.request.method,
                flow.request.path,
                None,
                json.dumps(dict(flow.request.headers)),
                flow.request.content.decode("utf-8", errors="replace") if flow.request.content else None,
                str(flow.error)
            ))
            self.conn.commit()
            ctx.log.warn(f"Recorded error: {flow.request.method} {flow.request.path}")
        except Exception as e:
            ctx.log.error(f"Error recording error: {e}")
            
    def done(self):
        """Called when mitmproxy shuts down"""
        ctx.log.info(f"Shutting down - Recorded {self.request_count} interactions to {self.db_path}")
        self.conn.close()


# Mitmproxy addon entry point
addons = [InteractionRecorder()]

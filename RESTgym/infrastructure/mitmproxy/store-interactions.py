import sqlite3
import os
import sys

class StoreInteractions:

    conn = None
    cursor = None
    count = 0

    def __init__(self):
        print(f"[STORE-INTERACTIONS] Initializing... API={os.environ.get('API')}, TOOL={os.environ.get('TOOL')}, RUN={os.environ.get('RUN')}", file=sys.stderr)
        try:
            self.conn = self.open_sqlite()
            self.cursor = self.conn.cursor()
            self.init_sqlite()
            print(f"[STORE-INTERACTIONS] Database initialized successfully", file=sys.stderr)
        except Exception as e:
            print(f"[STORE-INTERACTIONS] ERROR in __init__: {e}", file=sys.stderr)
            raise

    def open_sqlite(self):
        db_path = f"/results/{os.environ['API']}/{os.environ['TOOL']}/{os.environ['RUN']}/results.db"
        print(f"[STORE-INTERACTIONS] Opening database at: {db_path}", file=sys.stderr)
        return sqlite3.connect(db_path)
    
    def init_sqlite(self):
        self.cursor.execute('CREATE TABLE interactions (id integer PRIMARY KEY, request_method text, request_path text, request_headers text, request_content text, request_timestamp real, response_status_code integer, response_headers text, response_content text, response_timestamp real)')
        self.conn.commit()
    
    def response(self, flow):
        try:
            print(f"[STORE-INTERACTIONS] Recording interaction {self.count + 1}: {flow.request.method} {flow.request.path} -> {flow.response.status_code}", file=sys.stderr)
            self.cursor.execute('INSERT INTO interactions (request_method, request_path, request_headers, request_content, request_timestamp, response_status_code, response_headers, response_content, response_timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', (flow.request.method, flow.request.path, bytes(flow.request.headers).decode('utf-8'), flow.request.content.decode('utf-8'), flow.request.timestamp_start, flow.response.status_code, bytes(flow.response.headers).decode('utf-8'), flow.response.content.decode('utf-8'), flow.response.timestamp_start))
            self.count += 1
            if self.count % 10 == 0:
                self.conn.commit()
                print(f"[STORE-INTERACTIONS] Committed {self.count} interactions", file=sys.stderr)
        except Exception as e:
            print(f"[STORE-INTERACTIONS] ERROR in response: {e}", file=sys.stderr)

addons = [StoreInteractions()]






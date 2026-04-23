#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
from datetime import datetime, timezone
import json
import os

LOG_DIR = '/opt/management/shared/artifacts'
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, 'webhook-receiver.log')

class Handler(BaseHTTPRequestHandler):
    def _write_log(self, body):
        ts = datetime.now(timezone.utc).isoformat()
        entry = {
            'time': ts,
            'path': self.path,
            'method': self.command,
            'headers': dict(self.headers),
            'body': body.decode('utf-8', errors='replace')
        }
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(json.dumps(entry, ensure_ascii=True) + '\n')

    def do_POST(self):
        length = int(self.headers.get('Content-Length', '0'))
        body = self.rfile.read(length) if length > 0 else b''
        self._write_log(body)
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"ok":true}')

    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'webhook receiver online')

    def do_HEAD(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 9080), Handler)
    print('webhook receiver listening on 0.0.0.0:9080')
    server.serve_forever()

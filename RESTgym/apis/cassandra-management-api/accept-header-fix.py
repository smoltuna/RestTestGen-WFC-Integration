#!/usr/bin/env python3
"""Fixes Accept header for Cassandra (only returns text/plain)"""
from mitmproxy import http

class CassandraAuthMiddleware:
    def request(self, flow: http.HTTPFlow) -> None:
        if "Accept" in flow.request.headers:
            if "application/json" in flow.request.headers["Accept"]:
                flow.request.headers["Accept"] = "text/plain, */*"


addons = [CassandraAuthMiddleware()]

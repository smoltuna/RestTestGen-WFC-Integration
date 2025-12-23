#!/usr/bin/env python3
"""
Mitmproxy addon for Cassandra Management API.
Fixes content negotiation by converting Accept headers to text/plain.
"""

from mitmproxy import http


class CassandraAuthMiddleware:
    def request(self, flow: http.HTTPFlow) -> None:
        """Modify Accept header to prevent 406 errors."""
        # Cassandra Management API only returns text/plain
        # Change Accept header from application/json to text/plain or */*
        if "Accept" in flow.request.headers:
            # If requesting JSON, change to accept text/plain
            if "application/json" in flow.request.headers["Accept"]:
                flow.request.headers["Accept"] = "text/plain, */*"


addons = [CassandraAuthMiddleware()]

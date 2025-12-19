from mitmproxy import ctx

class CassandraAuth:
    def request(self, flow):
        # Cassandra Management API returns text/plain for many endpoints
        # Modify Accept header to include text/plain and */*
        original_accept = flow.request.headers.get("Accept", "")
        
        # If Accept is only application/json, broaden it to accept text/plain too
        if "application/json" in original_accept and "text/plain" not in original_accept:
            flow.request.headers["Accept"] = "text/plain, application/json, */*"
            ctx.log.info(f"[CASSANDRA-AUTH] Modified Accept header for {flow.request.pretty_url}")
        elif not original_accept or original_accept == "application/json":
            flow.request.headers["Accept"] = "*/*"
            ctx.log.info(f"[CASSANDRA-AUTH] Set Accept to */* for {flow.request.pretty_url}")

addons = [CassandraAuth()]

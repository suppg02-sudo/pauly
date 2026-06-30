#!/bin/bash
# Directus Server — Quick health check (reads ports from .env)
source /opt/pauly/.env 2>/dev/null || { echo "ERROR: /opt/pauly/.env not found"; exit 1; }

echo "=== Directus Health ==="
curl -s "http://localhost:${PORT_DIRECTUS:-8056}/server/health" && echo "" || echo "UNREACHABLE"
echo ""
echo "=== Containers ==="
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | grep -E 'directus|postgres|redis'
echo ""
echo "=== Page Count ==="
curl -s "http://localhost:${PORT_DIRECTUS:-8056}/items/pages?limit=0&meta=*" \
  -H "Authorization: Bearer ${DIRECTUS_TOKEN:-docs-api-token-change-me}" | jq -r '.meta.total_count // 0'

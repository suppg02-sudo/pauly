#!/bin/bash
# Astro Starlight — Quick health check (reads ports from .env)
source /opt/pauly/.env 2>/dev/null || { echo "ERROR: /opt/pauly/.env not found"; exit 1; }

echo "=== Astro Status ==="
ASTRO_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT_ASTRO:-3003}/ 2>/dev/null || echo "000")
echo "Astro (port ${PORT_ASTRO:-3003}): HTTP $ASTRO_CODE"
echo ""
echo "=== Directus Status ==="
DIRECTUS_HEALTH=$(curl -s "http://localhost:${PORT_DIRECTUS:-8056}/server/health" 2>/dev/null || echo "UNREACHABLE")
echo "Directus (port ${PORT_DIRECTUS:-8056}): $DIRECTUS_HEALTH"
echo ""
echo "=== Containers ==="
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | grep -E 'astro-docs|directus|postgres|redis'
echo ""
echo "=== Directus Pages ==="
curl -s "http://localhost:${PORT_DIRECTUS:-8056}/items/pages?limit=0&meta=*" \
  -H "Authorization: Bearer ${DIRECTUS_TOKEN:-docs-api-token-change-me}" | jq -r '.meta.total_count // "ERROR"'

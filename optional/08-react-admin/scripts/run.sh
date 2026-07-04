#!/bin/bash
# React-Admin — quick start script
set -euo pipefail

source /opt/pauly/.env 2>/dev/null || true

echo "=== React-Admin ==="
echo "Building and starting react-admin demo..."

cd "$(dirname "$0")/.."
docker compose build --no-cache
docker compose up -d

echo "Waiting for startup..."
for i in $(seq 1 30); do
  CODE=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${PORT_REACT_ADMIN:-5200}/" 2>/dev/null || echo "000")
  if [ "$CODE" = "200" ]; then
    echo "React-Admin running on port ${PORT_REACT_ADMIN:-5200}"
    echo "URL: http://${SERVER_IP:-localhost}:${PORT_REACT_ADMIN:-5200}/"
    exit 0
  fi
  sleep 2
done
echo "WARNING: React-Admin not responding yet (may still be building)"

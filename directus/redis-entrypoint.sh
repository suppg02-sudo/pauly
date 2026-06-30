#!/bin/sh
set -e

AOFDIR="/data/appendonlydir"

# Auto-repair corrupt AOF files before Redis starts
if [ -d "$AOFDIR" ]; then
  for aof in "$AOFDIR"/*.aof; do
    [ -f "$aof" ] || continue
    if ! redis-check-aof --truncate-to-timestamp "$aof" >/dev/null 2>&1; then
      echo "[entrypoint] AOF file $(basename "$aof") appears corrupt, attempting repair..."
      echo "y" | redis-check-aof --fix "$aof" >/dev/null 2>&1 || {
        echo "[entrypoint] Could not repair $(basename "$aof"), removing it"
        rm -f "$aof"
        # Clean up manifest references to removed file
        MANIFEST="$AOFDIR/appendonly.aof.manifest"
        if [ -f "$MANIFEST" ]; then
          tmp=$(mktemp)
          grep -v "$(basename "$aof")" "$MANIFEST" > "$tmp" || true
          mv "$tmp" "$MANIFEST"
        fi
      }
      echo "[entrypoint] AOF repair complete"
    fi
  done
fi

echo "[entrypoint] AOF files verified, starting Redis..."
exec redis-server --appendonly yes --appendfsync everysec --aof-load-truncated yes

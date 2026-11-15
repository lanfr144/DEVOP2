#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 01 - Run the three P01 queries (queries.js) in the container
# ==============================================================================
# Output goes to the terminal; redirect it to keep a trace for the deliverable:
#   ./run_queries.sh | tee queries_output.txt
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"

# This script drives Docker itself (compose, exec, inspect): run it on the
# machine (WSL / Git Bash), not inside a container.
if ! command -v docker >/dev/null 2>&1; then
  echo "Run this script on the machine, not inside a container: type 'exit' first." >&2
  exit 1
fi

CONTAINER="${MONGO_CONTAINER_NAME:-mongodb_service}"

# Copy the script into the container, then run it with the container's own
# credentials (no password on the host command line).
docker cp queries.js "$CONTAINER":/tmp/queries.js >/dev/null
docker exec "$CONTAINER" sh -c \
  'mongosh --quiet -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
     --authenticationDatabase admin --file /tmp/queries.js'

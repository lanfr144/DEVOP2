#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 01 - (Re)load logs.ndjson into unit01.logs
# ==============================================================================
# Use it when the mongo_data volume already existed before the seed script was
# added (the image only runs /docker-entrypoint-initdb.d on an EMPTY volume).
# Safe to run several times: the seed script upserts, it never duplicates.
#
# No password is typed here: mongosh runs INSIDE the container and reads the
# credentials from the container environment (MONGO_INITDB_ROOT_*), which
# docker compose filled from .env.
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

docker exec "$CONTAINER" sh -c \
  'mongosh --quiet -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
     --authenticationDatabase admin --file /docker-entrypoint-initdb.d/01-seed-logs.js'

#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 01 - working notes: the compose version of the lab
# ==============================================================================
# No password in this file: MongoDB credentials come from .env
# (PASSWORD_MONGO_ROOT), which docker compose passes to the container.
# mongosh runs INSIDE the container and reads them from its environment, so the
# password never appears on a command line, in the history or in "ps".
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] || { echo "Missing .env: copy .env.example to .env and set the passwords." >&2; exit 1; }

docker compose up -d --wait
docker compose ps
docker compose logs --tail 10

# Open a mongosh shell on the unit01 database
docker compose exec mongo sh -c \
  'mongosh -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin unit01'

# Follow the logs (Ctrl+C to stop):
#   docker compose logs -f mongo
#   docker compose logs -f mongo-express

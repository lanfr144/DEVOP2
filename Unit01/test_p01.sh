#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 01 - Automated test of the P01 deliverable
# ==============================================================================
# What it tests (each step prints PASS or FAIL):
#   1. docker-compose.yml is valid and has no obsolete `version:`
#   2. no secret from .env is written in a versioned file; .env is git-ignored
#   3. an ISOLATED stack starts from an EMPTY volume and both containers become
#      "healthy" (healthchecks of mongo AND mongo-express)
#   4. the seed script ran automatically (10 documents with Date timestamps)
#   5. the seed is idempotent (running load_logs.sh again keeps 10 documents)
#   6. the 3 queries return the expected results (3 / 5 / 3 services)
#   7. mongo-express answers: /status = 200 and / without login = 401
#   8. log_to_mongo.py writes logs directly into MongoDB (skip: SKIP_LOGGER_TEST=1)
#
# The test stack uses its own project name, container names, ports and volume,
# so the real stack (mongodb_service / mongo_express_ui) is NOT touched.
# Everything is removed at the end (docker compose down -v).
#
# Usage:  ./test_p01.sh 2>&1 | tee test_p01_output.txt
# ==============================================================================
set -uo pipefail
cd "$(dirname "$0")"

# This script drives Docker itself (compose, exec, inspect): run it on the
# machine (WSL / Git Bash), not inside a container.
if ! command -v docker >/dev/null 2>&1; then
  echo "Run this script on the machine, not inside a container: type 'exit' first." >&2
  exit 1
fi

# --- isolated test stack (environment variables override .env values) --------
export COMPOSE_PROJECT_NAME=unit01test
export MONGO_CONTAINER_NAME=unit01test_mongo
export EXPRESS_CONTAINER_NAME=unit01test_express
export MONGO_HOST_PORT=27029
export EXPRESS_HOST_PORT=8093

FAILS=0
pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; FAILS=$((FAILS + 1)); }

cleanup() {
  echo "--- cleanup: removing the test stack and its volume"
  docker compose down -v --remove-orphans >/dev/null 2>&1
}
trap cleanup EXIT

mongo_eval() {   # run a JS expression in the test container, print the result
  docker exec "$MONGO_CONTAINER_NAME" sh -c \
    'mongosh --quiet -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin unit01 --eval "$0"' "$1"
}

echo "=== P01 test - $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1. compose file -----------------------------------------------------------
if docker compose config -q 2>/tmp/p01_cfg.err && ! grep -q '^version:' docker-compose.yml; then
  pass "1 docker-compose.yml valid (no obsolete version attribute)"
else
  fail "1 docker-compose.yml invalid: $(cat /tmp/p01_cfg.err)"
fi

# 2. secrets ----------------------------------------------------------------
leak=0
while IFS='=' read -r key value; do
  case "$key" in PASSWORD_*) ;; *) continue ;; esac
  [ -z "$value" ] && continue
  # Files that may be shared/committed (everything except .env and backups)
  if grep -rlF --exclude=.env --exclude='*.wbk' --exclude-dir='mongosh-*' -- "$value" . >/dev/null 2>&1; then
    echo "      secret of $key found in: $(grep -rlF --exclude=.env --exclude='*.wbk' --exclude-dir='mongosh-*' -- "$value" . | tr '\n' ' ')"
    leak=1
  fi
done < .env
if [ $leak -eq 0 ] && grep -qx '.env' ../.gitignore && [ -f .env.example ]; then
  pass "2 no secret outside .env; .env git-ignored; .env.example present"
else
  fail "2 secret handling"
fi

# 3. start from an empty volume and wait for both healthchecks --------------
docker compose down -v >/dev/null 2>&1
if docker compose up -d --wait --wait-timeout 180 >/dev/null 2>&1; then
  pass "3 test stack started, mongo + mongo-express healthy"
else
  fail "3 stack not healthy"; docker compose ps; exit 1
fi
docker compose ps --format '      {{.Name}}: {{.Status}}'

# 4. automatic seed ---------------------------------------------------------
n=$(mongo_eval 'db.logs.countDocuments()')
dates=$(mongo_eval 'db.logs.countDocuments({timestamp: {$type: "date"}})')
if [ "$n" = "10" ] && [ "$dates" = "10" ]; then
  pass "4 seed ran on first start: $n documents, $dates with a Date timestamp"
else
  fail "4 seed: count=$n dates=$dates (expected 10/10)"
fi

# 5. idempotent reload ------------------------------------------------------
./load_logs.sh | sed 's/^/      /'
n=$(mongo_eval 'db.logs.countDocuments()')
[ "$n" = "10" ] && pass "5 load_logs.sh idempotent (still $n documents)" \
                || fail "5 load_logs.sh created duplicates (count=$n)"

# 6. the three queries ------------------------------------------------------
out=$(./run_queries.sh)
echo "$out" | sed 's/^/      /'
expected='RESULT q1=3 q2=5 q3=auth-api,orders-api,payment-api'
if echo "$out" | grep -qx "$expected"; then
  pass "6 queries: ERROR/24h=3, U12345=5 actions, WARN services=3"
else
  fail "6 queries: expected '$expected'"
fi

# 7. mongo-express HTTP -----------------------------------------------------
# curl runs in the tools container (no curl needed on the host) and reaches
# mongo-express by service name on the Docker network.
EXPRESS_IN=$(grep '^EXPRESS_CONTAINER_PORT=' .env | cut -d= -f2-)
s=$(docker compose exec -T tools curl -s -o /dev/null -w '%{http_code}' "http://mongo-express:${EXPRESS_IN}/status")
r=$(docker compose exec -T tools curl -s -o /dev/null -w '%{http_code}' "http://mongo-express:${EXPRESS_IN}/")
if [ "$s" = "200" ] && [ "$r" = "401" ]; then
  pass "7 mongo-express: /status=$s, / without login=$r (Basic Auth active)"
else
  fail "7 mongo-express: /status=$s, /=$r (expected 200/401)"
fi

# 8. Python logger writing directly into MongoDB ----------------------------
if [ "${SKIP_LOGGER_TEST:-0}" = "1" ]; then
  echo "SKIP  8 log_to_mongo.py (SKIP_LOGGER_TEST=1)"
else
  # Runs in a throw-away python container on the test network; credentials
  # are passed as environment variables read from .env (never printed).
  set -a; . ./.env; set +a
  if docker run --rm --network "${COMPOSE_PROJECT_NAME}_mongo_net" \
       -e MONGO_HOST=mongo -e MONGO_HOST_PORT=27017 \
       -e MONGO_ROOT_USER -e PASSWORD_MONGO_ROOT \
       -v "$PWD/log_to_mongo.py:/app/log_to_mongo.py:ro" python:3.12-slim \
       sh -c 'pip install -q --root-user-action=ignore pymongo >/dev/null 2>&1 && python /app/log_to_mongo.py' \
       | sed 's/^/      /'; then
    n=$(mongo_eval 'db.logs.countDocuments({service: "demo-logger", timestamp: {$type: "date"}})')
    out=$(./run_queries.sh | grep '^RESULT')
    # Q1/Q2 are unchanged (logger docs are dated "now" and use other users),
    # but Q3 has no time window: the demo WARN makes "demo-logger" appear,
    # which proves that live logs are immediately visible to the queries.
    expected8='RESULT q1=3 q2=5 q3=auth-api,demo-logger,orders-api,payment-api'
    if [ "$n" = "3" ] && [ "$out" = "$expected8" ]; then
      pass "8 log_to_mongo.py wrote $n logs (Date timestamps); Q3 now sees demo-logger"
    else
      fail "8 logger: demo docs=$n, queries now '$out'"
    fi
  else
    fail "8 log_to_mongo.py could not run"
  fi
fi

echo "=== $([ $FAILS -eq 0 ] && echo 'ALL TESTS PASSED' || echo "$FAILS TEST(S) FAILED")"
exit $FAILS

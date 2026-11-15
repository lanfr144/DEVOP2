#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 02 - the curl commands of the course, runnable as they are
# ==============================================================================
# 1. index ONE document          (POST <index>/_doc)
# 2. index several with _bulk    (POST <index>/_bulk)
# 3. full-text search "payment"  (read only, on logs-demo)
# 4. aggregation per level       (read only, on logs-demo)
#
# The two writes go to a separate practice index (logs-curl-test), deleted at
# the end: the 15 documents of logs-demo, which the deliverable and
# test_p02.sh rely on, are never modified.
#
# Run it in the tools container:   docker compose exec tools ./use_curl.sh
# The password and the ports come from .env; nothing is written here.
# ==============================================================================
set -a
. ./.env
ES_URL="${ES_URL:-https://localhost:${ES_PORT_EXPOSE}}"
set +a
TEST_INDEX=logs-curl-test

echo "== 1. index one document into ${TEST_INDEX}"
curl -k -u elastic:"${PASSWORD_ELASTIC}" -X POST \
 "${ES_URL}/${TEST_INDEX}/_doc?refresh=true" \
 -H 'Content-Type: application/json' -d '{ "service":"web","level":"INFO", "@timestamp":"2025-09-24T20:30:00Z","message":"Server started" }'
echo

# _bulk: one action line + one document line each time, and the body MUST end
# with a newline (that is why the closing quote is alone on the last line).
echo "== 2. index three documents into ${TEST_INDEX} with _bulk"
curl -k -u elastic:"${PASSWORD_ELASTIC}" -X POST \
 "${ES_URL}/${TEST_INDEX}/_bulk?refresh=true" \
 -H 'Content-Type: application/x-ndjson' --data-binary '{"index":{}}
{"service":"payment-api","level":"ERROR","@timestamp":"2025-09-24T21:00:00Z","message":"transaction_failed"}
{"index":{}}
{"service":"auth-api","level":"WARN","@timestamp":"2025-09-24T21:05:00Z","message":"login_bruteforce_detected"}
{"index":{}}
{"service":"orders-api","level":"INFO","@timestamp":"2025-09-24T21:10:00Z","message":"order_created"}
'
echo

echo "== 3. full-text search for \"payment\" in logs-demo"
curl -k -u elastic:"${PASSWORD_ELASTIC}" \
 "${ES_URL}/logs-demo/_search?pretty" \
 -H 'Content-Type: application/json' -d '{ "query": { "match": { "message": "payment" } } }'

echo "== 4. documents per level in logs-demo"
curl -k -u elastic:"${PASSWORD_ELASTIC}" \
 "${ES_URL}/logs-demo/_search?pretty" \
 -H 'Content-Type: application/json' -d '{ "size": 0, "aggs": { "by_level": { "terms": { "field": "level.keyword" } } } }'

echo "== cleanup: delete the practice index ${TEST_INDEX}"
curl -k -u elastic:"${PASSWORD_ELASTIC}" -X DELETE "${ES_URL}/${TEST_INDEX}"
echo

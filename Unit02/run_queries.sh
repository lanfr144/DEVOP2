#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 02 - Part A: show the queries of the exercise, live
# ==============================================================================
# Read-only: it sends the four _search requests to Elasticsearch and prints a
# short version of each answer. Nothing is added to the index.
#   1. how many documents, services and levels (exercise point 1)
#   2. (a) full-text search "payment"  (b) filter level = ERROR
#      (c) aggregation per level       (exercise point 2)
#   3. own aggregation: top 3 services (exercise point 3)
# curl runs in the Unit02 tools container; the password is read from .env.
# Usage:  ./run_queries.sh            (on the machine or in unit02-tools-1)
#         ./run_queries.sh --raw      (full JSON answers, as saved in query_*.json)
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"
RAW=0; [ "${1:-}" = "--raw" ] && RAW=1

PASSWORD_ELASTIC=$(grep '^PASSWORD_ELASTIC=' .env | cut -d= -f2- | sed 's/^"//; s/"$//')
ES="https://elasticsearch:$(grep '^ES_PORT_IN=' .env | cut -d= -f2-)"

if command -v docker >/dev/null 2>&1; then
  if ! docker compose ps --status running --services 2>/dev/null | grep -qx tools; then
    echo "The Unit02 stack is not running. Start it first:  ./start.sh" >&2; exit 1
  fi
  RUN="docker compose exec -T tools"
elif getent hosts elasticsearch >/dev/null 2>&1; then
  RUN=""
else
  echo "Elasticsearch is not reachable from here: run this script on the machine, in Unit02." >&2; exit 1
fi

SHORT='
import json, sys
d = json.load(sys.stdin)
print("   total hits:", d["hits"]["total"]["value"])
for h in d["hits"]["hits"]:
    s = h["_source"]
    print("   -", s["@timestamp"], s["level"].ljust(5), s["service"].ljust(12), s["message"])
for name, agg in d.get("aggregations", {}).items():
    if "buckets" in agg:
        print("   " + name + ":", ", ".join(str(b["key"]) + "=" + str(b["doc_count"]) for b in agg["buckets"]))
    else:
        print("   " + name + ":", agg.get("value"))
'

query() {   # query "title" 'json body'
  echo
  echo "== $1"
  echo "   POST logs-demo/_search  $2"
  if [ "$RAW" = "1" ]; then
    $RUN curl -sk -u "elastic:${PASSWORD_ELASTIC}" -H 'Content-Type: application/json' -X POST "$ES/logs-demo/_search?pretty" -d "$2"
  else
    $RUN curl -sk -u "elastic:${PASSWORD_ELASTIC}" -H 'Content-Type: application/json' -X POST "$ES/logs-demo/_search" -d "$2" \
      | $RUN python3 -I -c "$SHORT"
  fi
}

query '1. Content of the index: documents, services, levels' \
  '{"size":0,"aggs":{"services":{"terms":{"field":"service.keyword"}},"levels":{"terms":{"field":"level.keyword"}}}}'
query '2a. Full-text search for "payment"' \
  '{"query":{"match":{"message":"payment"}}}'
query '2b. Filter level = ERROR' \
  '{"query":{"term":{"level.keyword":"ERROR"}}}'
query '2c. Aggregation: documents per level' \
  '{"size":0,"aggs":{"by_level":{"terms":{"field":"level.keyword"}}}}'
query '3. Own aggregation: top 3 services by log volume' \
  '{"size":0,"aggs":{"top_services":{"terms":{"field":"service.keyword","size":3}}}}'

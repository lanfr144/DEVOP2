#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 02 - (re)load the 15 demo logs into the logs-demo index
# ==============================================================================
# Use it when the index is empty: fresh clone, new machine, or after
# "docker compose down -v" (which deletes the Elasticsearch volume). An empty
# index is why the Kibana dashboard shows "No results found".
#
# Source: logs-demo-export.json (the export of Part A). Each document is sent
# back with its original _id through the _bulk API, so running the script
# twice never creates duplicates.
#
# Like create_dashboard.sh, it works on the machine (through docker compose)
# and inside the Unit02 tools container. The password is read from .env.
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"

PASSWORD_ELASTIC=$(grep '^PASSWORD_ELASTIC=' .env | cut -d= -f2- | sed 's/^"//; s/"$//')
ES_PORT_IN=$(grep '^ES_PORT_IN=' .env | cut -d= -f2-)
ES="https://elasticsearch:${ES_PORT_IN}"

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

# Build the _bulk body (action line + document line) from the export, send it,
# then print how many documents the index holds.
$RUN python3 -I - <<'PY' | $RUN curl -sk -u "elastic:${PASSWORD_ELASTIC}" -X POST "$ES/logs-demo/_bulk?refresh=true" \
      -H 'Content-Type: application/x-ndjson' --data-binary @- \
  | $RUN python3 -I -c "import json,sys; d=json.load(sys.stdin); print('bulk: errors =', d.get('errors'), '| items =', len(d.get('items', [])))"
import json
for hit in json.load(open('logs-demo-export.json'))['hits']['hits']:
    print(json.dumps({'index': {'_id': hit['_id']}}))
    print(json.dumps(hit['_source']))
PY

$RUN curl -sk -u "elastic:${PASSWORD_ELASTIC}" "$ES/logs-demo/_count" \
  | $RUN python3 -I -c "import json,sys; print('logs-demo now holds', json.load(sys.stdin)['count'], 'documents')"

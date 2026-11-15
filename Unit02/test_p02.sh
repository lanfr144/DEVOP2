#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 02 - Automated test of the P02 deliverable
# ==============================================================================
# Runs against the RUNNING stack (docker compose up -d --wait first); it does
# not restart Elasticsearch. Each step prints PASS or FAIL:
#   1. docker-compose.yml valid; every long-running service has a healthcheck
#   2. no secret from .env in any other file (also searched INSIDE .docx/.pptx);
#      .env git-ignored; .env.example present
#   3. elasticsearch and kibana containers are "healthy"
#   4. Part A data: >= 15 docs, >= 3 services, levels INFO + WARN + ERROR
#   5. Part A queries: full-text "payment", filter level=ERROR, aggregation by
#      level, custom aggregation (top 3 services) - live results = saved JSON
#   6. Part A export: logs-demo-export.json contains every document
#   7. Part B Kibana: API up, data view on @timestamp, dashboard with 2 Lens
#      panels; the ERROR count seen by Kibana's data view = Part A filter count
#
# Usage:  ./test_p02.sh 2>&1 | tee test_p02_output.txt
# ==============================================================================
set -uo pipefail
cd "$(dirname "$0")"

# This script drives Docker itself (compose, exec, inspect): run it on the
# machine (WSL / Git Bash), not inside a container.
if ! command -v docker >/dev/null 2>&1; then
  echo "Run this script on the machine, not inside a container: type 'exit' first." >&2
  exit 1
fi
if ! docker compose ps --status running --services 2>/dev/null | grep -qx tools; then
  echo "The stack of this unit is not running. Start it first:  ./start.sh" >&2
  exit 1
fi

getenv() { grep "^$1=" .env | cut -d= -f2- | sed 's/^"//; s/"$//'; }
PASSWORD_ELASTIC=$(getenv PASSWORD_ELASTIC)
# curl and python run in the "tools" container (nothing to install on the host);
# from there the stack is reached by service name and container port.
ES="https://elasticsearch:$(getenv ES_PORT_IN)"
KB="http://kibana:$(getenv KIBANA_PORT_IN)"
KB_HOST="http://localhost:$(getenv KIBANA_PORT_EXPOSE)"   # URL for your browser
TOOLS="docker compose exec -T tools"
AUTH="elastic:${PASSWORD_ELASTIC}"

FAILS=0
pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; FAILS=$((FAILS + 1)); }
# -k: the lab CA is self-signed (acceptable locally only, see Elasticsearch.docx)
es()  { $TOOLS curl -sk -u "$AUTH" -H 'Content-Type: application/json' "$@"; }
kb()  { $TOOLS curl -s  -u "$AUTH" -H 'kbn-xsrf: true' "$@"; }
jq_() { $TOOLS python3 -I -c "import json,sys; d=json.load(sys.stdin); print($1)"; }

echo "=== P02 test - $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1. compose -----------------------------------------------------------------
if docker compose config -q 2>/dev/null; then
  missing=$(docker compose config --format json | jq_ "' '.join(n for n,s in d['services'].items() if n!='setup' and 'healthcheck' not in s)")
  [ -z "$missing" ] && pass "1 compose valid; healthcheck on elasticsearch + kibana (setup = one-shot job)" \
                    || fail "1 no healthcheck on: $missing"
else
  fail "1 docker-compose.yml invalid"
fi

# 2. secrets (plain files AND inside Office zip files) ------------------------
leaks=$($TOOLS python3 -I - <<'EOF'
import os, zipfile
secrets = {}
for line in open('.env'):
    k, _, v = line.strip().partition('=')
    if k.startswith('PASSWORD_') and v.strip('"'):
        secrets[k] = v.strip('"').encode()
found = []
for dp, dn, fn in os.walk('.'):
    dn[:] = [d for d in dn if d not in ('data',)]
    for f in fn:
        if f == '.env' or f.endswith('.wbk'):
            continue
        p = os.path.join(dp, f)
        blobs = [open(p, 'rb').read()]
        if f.endswith(('.docx', '.pptx', '.xlsx')):
            z = zipfile.ZipFile(p)
            blobs = [z.read(n) for n in z.namelist()]
        for k, s in secrets.items():
            if any(s in b for b in blobs):
                found.append(f'{k} in {p}')
print('; '.join(found))
EOF
)
if [ -z "$leaks" ] && grep -qx '.env' ../.gitignore && [ -f .env.example ]; then
  pass "2 no secret outside .env (docx included); .env git-ignored; .env.example present"
else
  fail "2 secrets: ${leaks:-.gitignore/.env.example problem}"
fi

# 3. container health ---------------------------------------------------------
h_es=$(docker inspect -f '{{.State.Health.Status}}' elasticsearch 2>/dev/null)
h_kb=$(docker inspect -f '{{.State.Health.Status}}' kibana 2>/dev/null)
[ "$h_es" = healthy ] && [ "$h_kb" = healthy ] \
  && pass "3 elasticsearch=$h_es, kibana=$h_kb" \
  || fail "3 elasticsearch=$h_es, kibana=$h_kb"

# 4. Part A data ---------------------------------------------------------------
stats=$(es -X POST "$ES/logs-demo/_search" -d '{"size":0,"aggs":{"s":{"cardinality":{"field":"service.keyword"}},"l":{"terms":{"field":"level.keyword"}}}}' \
  | jq_ "d['hits']['total']['value'], d['aggregations']['s']['value'], ','.join(sorted(b['key'] for b in d['aggregations']['l']['buckets']))")
read -r total services levels <<<"$stats"
if [ "$total" -ge 15 ] && [ "$services" -ge 3 ] && [ "$levels" = "ERROR,INFO,WARN" ]; then
  pass "4 logs-demo: $total docs, $services services, levels $levels"
else
  fail "4 logs-demo: $total docs, $services services, levels $levels"
fi

# 5. Part A queries: live result must equal the saved deliverable file --------
check_query() {   # $1 label, $2 saved file, $3 request body, $4 python expression
  live=$(es -X POST "$ES/logs-demo/_search" -d "$3" | jq_ "$4")
  saved=$(jq_ "$4" < "$2")
  [ "$live" = "$saved" ] && pass "5 $1: $live (= $2)" || fail "5 $1: live=$live saved=$saved"
}
check_query 'full-text "payment"' query_a_search.json \
  '{"query":{"match":{"message":"payment"}}}' "d['hits']['total']['value']"
check_query 'filter level=ERROR' query_b_filter.json \
  '{"query":{"term":{"level.keyword":"ERROR"}}}' "d['hits']['total']['value']"
check_query 'aggregation by level' query_c_agg_level.json \
  '{"size":0,"aggs":{"by_level":{"terms":{"field":"level.keyword"}}}}' \
  "sorted((b['key'],b['doc_count']) for b in d['aggregations']['by_level']['buckets'])"
check_query 'custom agg top 3 services' query_custom_agg.json \
  '{"size":0,"aggs":{"top_services":{"terms":{"field":"service.keyword","size":3}}}}' \
  "sorted((b['key'],b['doc_count']) for b in d['aggregations']['top_services']['buckets'])"

# 6. export --------------------------------------------------------------------
exported=$(jq_ "len(d['hits']['hits'])" < logs-demo-export.json)
[ "$exported" = "$total" ] && pass "6 logs-demo-export.json holds all $exported documents" \
                           || fail "6 export holds $exported docs, index has $total"

# 7. Part B Kibana --------------------------------------------------------------
st=$(kb "$KB/api/status" | jq_ "d['status']['overall']['level']")
dv=$(kb "$KB/api/data_views" | jq_ "','.join(sorted(v['title'] for v in d['data_view']))")
tf=$(kb "$KB/api/data_views/data_view/p02-logs-demo" | jq_ "d['data_view']['timeFieldName']")
panels=$(kb "$KB/api/saved_objects/dashboard/p02-dashboard" | jq_ "len(json.loads(d['attributes']['panelsJSON']))")
lens=$(kb "$KB/api/saved_objects/_find?type=lens&search_fields=title&search=P02*" | jq_ "d['total']")
# What Discover shows for  level : "ERROR"  = an ES query through the data view
kerr=$(es -X POST "$ES/logs-demo*/_count" -d '{"query":{"match":{"level":"ERROR"}}}' | jq_ "d['count']")
ferr=$(jq_ "d['hits']['total']['value']" < query_b_filter.json)
if [ "$st" = available ] && [ "$tf" = "@timestamp" ] && [ "$panels" -ge 2 ] && [ "$lens" -ge 2 ] && [ "$kerr" = "$ferr" ]; then
  pass "7 Kibana $st; data views [$dv] on $tf; dashboard p02-dashboard: $panels panels, $lens Lens; ERROR in Kibana=$kerr = Part A=$ferr"
else
  fail "7 Kibana status=$st timefield=$tf panels=$panels lens=$lens errors kibana=$kerr partA=$ferr"
fi
if [ -s dashboard.png ]; then
  echo "      dashboard.png present (screenshot of $KB_HOST/app/dashboards#/view/p02-dashboard)"
else
  echo "      manual step left: open $KB_HOST/app/dashboards#/view/p02-dashboard and save the screenshot as dashboard.png"
fi

echo "=== $([ $FAILS -eq 0 ] && echo 'ALL TESTS PASSED' || echo "$FAILS TEST(S) FAILED")"
exit $FAILS

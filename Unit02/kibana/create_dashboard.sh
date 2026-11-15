#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 02 - P02 Part B: create the Kibana dashboard from code
# ==============================================================================
# Imports p02-dashboard.ndjson through the Kibana Saved Objects API:
#   - data view  "P02 logs-demo"           (logs-demo*, time field @timestamp)
#   - Lens       "P02 - Logs by service"   (stacked bars: service x level)
#   - Lens       "P02 - Logs by level"     (donut: second panel)
#   - Lens       "P02 - Errors by service" (bars, KQL level.keyword : "ERROR")
#   - Lens       "P02 - Logs over time"    (date histogram x level)
#   - dashboard  "P02 - Logs demo dashboard" (the 4 panels, last 1 year)
# overwrite=true -> safe to run again (same fixed IDs, no duplicates).
#
# The same objects can be built by hand in the UI (see P02_DELIVERABLE.md);
# this file makes the result reproducible and testable ("dashboard as code").
#
# The password is read from ../.env (PASSWORD_ELASTIC), never typed here.
# Then open http://localhost:5602/app/dashboards#/view/p02-dashboard and take
# the screenshot for the deliverable.
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."          # Unit02/, where docker-compose.yml lives

PASSWORD_ELASTIC=$(grep '^PASSWORD_ELASTIC=' .env | cut -d= -f2-)
KIBANA_PORT=$(grep '^KIBANA_PORT_EXPOSE=' .env | cut -d= -f2-)
KIBANA_PORT_IN=$(grep '^KIBANA_PORT_IN=' .env | cut -d= -f2-)

# curl always runs in the Unit02 "tools" container and reaches Kibana by service
# name. The script can be started from two places:
#   - on the machine (WSL / Git Bash): it calls the container with docker compose
#   - inside the Unit02 tools container: it calls curl directly
if command -v docker >/dev/null 2>&1; then
  if ! docker compose ps --status running --services 2>/dev/null | grep -qx tools; then
    echo "The Unit02 stack is not running. Start it first:  ./start.sh" >&2
    exit 1
  fi
  RUN="docker compose exec -T tools"
elif getent hosts kibana >/dev/null 2>&1; then
  RUN=""
else
  echo "Kibana is not reachable from here." >&2
  echo "You are in a container that is not on the Unit02 network (for example unit05-tools-1)." >&2
  echo "Type 'exit', then on the machine:  cd Unit02 && ./start.sh && ./kibana/create_dashboard.sh" >&2
  exit 1
fi

$RUN curl -s -u "elastic:${PASSWORD_ELASTIC}" -H 'kbn-xsrf: true' \
  -X POST "http://kibana:${KIBANA_PORT_IN}/api/saved_objects/_import?overwrite=true" \
  --form file=@kibana/p02-dashboard.ndjson
echo
echo "Dashboard: http://localhost:${KIBANA_PORT}/app/dashboards#/view/p02-dashboard"

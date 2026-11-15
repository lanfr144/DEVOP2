#!/bin/bash
# Start this unit in Docker: .env, port check, up --wait, then the next commands.
set -euo pipefail
cd "$(dirname "$0")"
export NEED_ENV=1 GIT_ENV=0
export NEXT_STEPS='# here, on the machine (not inside a container):
./run_queries.sh
./test_p01.sh
docker exec -it {tools} python log_to_mongo.py'
exec ../scripts/start_unit.sh

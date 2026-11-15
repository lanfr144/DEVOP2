#!/bin/bash
# Start this unit in Docker: .env, port check, up --wait, then the next commands.
set -euo pipefail
cd "$(dirname "$0")"
export NEED_ENV=1 GIT_ENV=1
export NEXT_STEPS='docker exec -it {tools} bash
# then, inside the container:
./TestUnit5.sh'
exec ../scripts/start_unit.sh

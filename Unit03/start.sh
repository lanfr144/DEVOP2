#!/bin/bash
# Start this unit in Docker: .env, port check, up --wait, then the next commands.
set -euo pipefail
cd "$(dirname "$0")"
export NEED_ENV=0 GIT_ENV=0
export NEXT_STEPS='docker exec -it {tools} bash
# then, inside the container:
python app.py
APP_ENV=staging python app.py
APP_ENV=prod python app.py
./test_p03.sh'
exec ../scripts/start_unit.sh

#!/bin/bash
# Start this unit in Docker: .env, port check, up --wait, then the next commands.
set -euo pipefail
cd "$(dirname "$0")"
export NEED_ENV=1 GIT_ENV=1
export NEXT_STEPS='docker exec -it {tools} bash
# then, inside the container:
git init release-strategies-lab    # then the lab, parts 1 to 4 (Unit04/VERIFICATION.md)
./record_history.sh                # at the end: writes P04_git_history.txt'
exec ../scripts/start_unit.sh

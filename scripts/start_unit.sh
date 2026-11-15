#!/bin/bash
# ==============================================================================
# DEVOP2 - start the Docker stack of one unit (called by UnitXX/start.sh)
# ==============================================================================
#   1. .env      NEED_ENV=1: must exist (created from .env.example if missing)
#                GIT_ENV=1 : GIT_USER_NAME, GIT_USER_EMAIL and GH_TOKEN are read
#                            from this machine (git config --global, gh auth token)
#   2. ports     every host port of .env must be free (skipped if already running)
#   3. start     docker compose up -d --build --wait  -> returns when every
#                healthcheck (services + toolbox image) is "healthy"
#                If the start fails: prints a diagnosis (state, healthcheck
#                results, last log lines, networks), then stops and removes
#                every container of the unit (docker compose down; volumes
#                are kept). KEEP_ON_FAILURE=1 leaves them running.
#   4. hint      prints the commands to type next (NEXT_STEPS, set by start.sh;
#                {tools} is replaced by the real name of the tools container)
# ==============================================================================
set -euo pipefail
NEED_ENV="${NEED_ENV:-1}"
GIT_ENV="${GIT_ENV:-0}"
NEXT_STEPS="${NEXT_STEPS:-}"
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- helpers -----------------------------------------------------------------
env_get() { grep -m1 "^$1=" .env 2>/dev/null | cut -d= -f2- | tr -d '\r' || true; }
env_set() {   # env_set KEY VALUE : replace (or add) KEY=VALUE in .env, value never echoed
  KEY="$1" VAL="$2" awk 'BEGIN { k = ENVIRON["KEY"]; v = ENVIRON["VAL"] }
       index($0, k "=") == 1 { print k "=" v; done = 1; next }
       { print }
       END { if (!done) print k "=" v }' .env > .env.tmp && mv .env.tmp .env
}
# First non-empty answer among the Linux and the Windows flavour of a command
# (under WSL, git/gh are often configured on the Windows side only).
local_value() {
  local out cmd
  for cmd in "$1" "$1.exe"; do
    command -v "$cmd" >/dev/null 2>&1 || continue
    out=$("$cmd" "${@:2}" 2>/dev/null | tr -d '\r' | head -1) || true
    [ -n "$out" ] && { printf '%s' "$out"; return 0; }
  done
  return 1
}

# --- 1. .env -----------------------------------------------------------------
if [ "$NEED_ENV" = "1" ] && [ ! -f .env ]; then
  cp .env.example .env
  echo "A new .env was created from .env.example."
  if [ "$GIT_ENV" != "1" ]; then
    echo "Open it, replace every PASSWORD_* value, then run ./start.sh again."
    exit 1
  fi
fi

if [ "$GIT_ENV" = "1" ]; then
  echo "--- Git identity and GitHub token (taken from this machine)"
  for key in GIT_USER_NAME GIT_USER_EMAIL GH_TOKEN; do
    cur=$(env_get "$key")
    if [ -n "$cur" ] && [ "$cur" != "$key" ] && [ "$cur" != "PASSWORD_GH_TOKEN" ]; then
      echo "KEEP  $key (already set in .env)"; continue
    fi
    case "$key" in
      GIT_USER_NAME)  val=$(local_value git config --global user.name)  || val="" ;;
      GIT_USER_EMAIL) val=$(local_value git config --global user.email) || val="" ;;
      GH_TOKEN)       val=$(local_value gh auth token)                  || val="" ;;
    esac
    if [ -n "$val" ]; then
      env_set "$key" "$val"; echo "SET   $key (written in .env, git-ignored)"
    else
      env_set "$key" ""
      case "$key" in
        GH_TOKEN) echo "MISS  GH_TOKEN: run 'gh auth login' on this machine (Unit 05 also needs: gh auth refresh -h github.com -s delete_repo), then ./start.sh again" ;;
        GIT_USER_NAME)  echo "MISS  GIT_USER_NAME: run 'git config --global user.name \"Your Name\"' on this machine, then ./start.sh again" ;;
        GIT_USER_EMAIL) echo "MISS  GIT_USER_EMAIL: run 'git config --global user.email you@example.com' on this machine, then ./start.sh again" ;;
      esac
    fi
  done
fi

if [ -f .env ] && grep -qE '^(PASSWORD_[A-Z_]*)=\1$' .env; then
  echo "Warning: .env still contains dummy passwords (value = variable name):"
  grep -E '^(PASSWORD_[A-Z_]*)=\1$' .env | cut -d= -f1 | sed 's/^/  - /'
fi

# --- 2. ports ----------------------------------------------------------------
if [ -n "$(docker compose ps -q 2>/dev/null)" ]; then
  echo "Stack already running: port check skipped."
elif [ -f .env ]; then
  echo "--- checking host ports"
  "$SCRIPTS/check_ports.sh" .env || { echo "Start cancelled: free the port or change it in .env."; exit 1; }
fi

# --- 3. start ----------------------------------------------------------------
echo "--- starting (waits for every healthcheck)"
if ! docker compose up -d --build --wait; then
  # Say WHY: state of every container, then for each one that is not healthy
  # the output of its last healthchecks and the end of its log.
  echo
  echo "=== The stack did not become healthy. Diagnosis:"
  docker compose ps -a --format 'table {{.Service}}\t{{.Name}}\t{{.Status}}' || true
  for name in $(docker compose ps -a --format '{{.Name}}'); do
    health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$name" 2>/dev/null || echo unknown)
    state=$(docker inspect -f '{{.State.Status}}' "$name" 2>/dev/null || echo unknown)
    if [ "$health" = healthy ] || { [ "$health" = none ] && [ "$state" = running -o "$state" = exited ]; }; then continue; fi
    echo
    echo "--- $name: state=$state health=$health"
    echo "    last healthcheck results:"
    docker inspect -f '{{range .State.Health.Log}}exit={{.ExitCode}} {{.Output}}{{println}}{{end}}' "$name" 2>/dev/null | tail -6 | sed 's/^/      /'
    echo "    last log lines:"
    docker logs --tail 25 "$name" 2>&1 | sed 's/^/      /'
  done
  echo
  echo "--- networks of this unit (subnet | container=address)"
  for net in $(docker network ls -q --filter "label=com.docker.compose.project=$(docker compose config --format json 2>/dev/null | sed -n 's/^ *"name": *"\([^"]*\)".*/\1/p' | head -1)" 2>/dev/null); do
    docker network inspect "$net" -f '    {{.Name}}: {{range .IPAM.Config}}{{.Subnet}}{{end}} | {{range .Containers}}{{.Name}}={{.IPv4Address}} {{end}}' 2>/dev/null || true
  done

  echo
  echo "If a log above says \"Operation timed out\" between two containers, old Docker"
  echo "firewall rules may be blocking the network:  ../scripts/fix_docker_stale_rules.sh"

  # A half-started stack is never left running: everything of this unit is
  # stopped and removed (containers and network; the data volumes are kept).
  # Set KEEP_ON_FAILURE=1 to leave it up for a manual investigation.
  echo
  if [ "${KEEP_ON_FAILURE:-0}" = "1" ]; then
    echo "KEEP_ON_FAILURE=1: the containers are left running for investigation."
    echo "Stop them with:  docker compose down"
  else
    echo "--- stopping everything of this unit (volumes are kept)"
    docker compose down --remove-orphans || true
  fi
  echo
  echo "Fix the cause shown above, then run ./start.sh again."
  exit 1
fi
docker compose ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'

# --- 4. what to type next ----------------------------------------------------
if [ -n "$NEXT_STEPS" ]; then
  tools=$(docker compose ps --format '{{.Name}}' tools 2>/dev/null | head -1)
  echo
  echo "Next commands:"
  printf '%s\n' "${NEXT_STEPS//\{tools\}/${tools:-<tools-container>}}" | sed 's/^/  /'
fi

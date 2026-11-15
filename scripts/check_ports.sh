#!/bin/bash
# ==============================================================================
# DEVOP2 - check that the host ports of a unit are free BEFORE starting it
# ==============================================================================
# Usage:  ../scripts/check_ports.sh [.env]      (run from a unit folder)
# Reads every variable named *_HOST_PORT or *_PORT_EXPOSE in the .env file.
# For each port:
#   1. quick test: does something already answer on 127.0.0.1:<port>?
#   2. real test : can Docker publish 127.0.0.1:<port>? (the exact operation
#      "docker compose up" will do; catches ports held on the Docker host)
# Exit code 0 = all free, 1 = at least one busy. To fix a busy port, change the
# variable in .env: the compose files take every host port from there.
# ==============================================================================
set -uo pipefail
ENV_FILE="${1:-.env}"
PROBE_IMAGE="${PORT_PROBE_IMAGE:-alpine:3.20}"

[ -f "$ENV_FILE" ] || { echo "check_ports: $ENV_FILE not found" >&2; exit 1; }

busy=0; count=0
while IFS='=' read -r name value; do
  port=$(printf '%s' "$value" | tr -d '"'"'"' \r')
  case "$port" in ''|*[!0-9]*) echo "SKIP  $name: '$port' is not a port number"; continue ;; esac
  count=$((count + 1))

  if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
    owner=$(docker ps --filter "publish=$port" --format '{{.Names}}' 2>/dev/null | tr '\n' ' ')
    echo "BUSY  $name=$port  (in use${owner:+ by container: $owner}) -> change $name in $ENV_FILE"
    busy=1; continue
  fi

  if err=$(docker run --rm -p "127.0.0.1:$port:$port" "$PROBE_IMAGE" true 2>&1); then
    echo "FREE  $name=$port"
  elif printf '%s' "$err" | grep -qiE 'already allocated|address already in use|bind|port'; then
    echo "BUSY  $name=$port  (Docker cannot publish it) -> change $name in $ENV_FILE"
    busy=1
  else
    echo "WARN  $name=$port  not verified with Docker: $(printf '%s' "$err" | tail -1)"
  fi
done < <(grep -E '^[A-Z0-9_]*(HOST_PORT|PORT_EXPOSE)=' "$ENV_FILE")

[ "$count" -eq 0 ] && echo "check_ports: no host port defined in $ENV_FILE"
exit $busy

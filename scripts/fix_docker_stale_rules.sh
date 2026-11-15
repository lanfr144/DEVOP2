#!/bin/bash
# ==============================================================================
# DEVOP2 - remove stale Docker firewall rules (containers cannot reach each other)
# ==============================================================================
# Symptom: a container waits forever for another one of the same network
#          ("connect: Operation timed out"), although both are running.
# Cause:   for a port published on 127.0.0.1, Docker adds a rule in the "raw"
#          table:   -d <container address> ! -i <bridge of its network> -j DROP
#          (nobody may reach that container except through its own network).
#          When such a rule is left behind after its network was removed, it
#          keeps dropping every packet sent to that address. The next network
#          that receives the same address range gets a new bridge name, so its
#          own containers are blocked by the old rule.
# Fix:     delete only the rules whose bridge no longer exists. Rules of
#          networks that are still there are kept.
# Usage:   ./scripts/fix_docker_stale_rules.sh      (asks for sudo)
#          ./scripts/fix_docker_stale_rules.sh -n   (only show, change nothing)
# ==============================================================================
set -uo pipefail
DRY=0; [ "${1:-}" = "-n" ] && DRY=1
if [ "$(id -u)" != "0" ]; then exec sudo "$0" "$@"; fi

removed=0; kept=0
while read -r rule; do
  bridge=$(printf '%s\n' "$rule" | sed -E 's/.* ! -i ([^ ]+) .*/\1/')
  spec=${rule#-A PREROUTING }
  if ip link show "$bridge" >/dev/null 2>&1; then
    echo "KEEP    $spec   (network $bridge exists)"; kept=$((kept + 1))
  elif [ "$DRY" = "1" ]; then
    echo "STALE   $spec   (network $bridge is gone; would be removed)"; removed=$((removed + 1))
  else
    # shellcheck disable=SC2086
    iptables -t raw -D PREROUTING $spec && echo "REMOVED $spec   (network $bridge is gone)"
    removed=$((removed + 1))
  fi
done < <(iptables -t raw -S PREROUTING | grep -E '^-A PREROUTING -d [0-9./]+ ! -i [^ ]+ -j DROP$')

echo "Stale rules: $removed, rules kept: $kept."

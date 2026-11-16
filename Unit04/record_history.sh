#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 04b - write the record of the lab into P04_git_history.txt
# ==============================================================================
# Read-only on the lab repository: it only runs git log / tag / branch / show /
# reflog and saves their output next to this script. Run it again whenever the
# lab changes; the file is rebuilt from scratch.
# Usage (in the tools container or on the machine, from Unit04):
#   ./record_history.sh                      # reads ./release-strategies-lab
#   ./record_history.sh path/to/other/repo
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"
REPO="${1:-release-strategies-lab}"
OUT="$PWD/P04_git_history.txt"
[ -d "$REPO/.git" ] || { echo "No Git repository in '$REPO'. Do the lab first." >&2; exit 1; }
cd "$REPO"

{
  echo "DEVOP2 - Unit 04b - Release Management Lab - record of the work"
  echo "Repository: $(git remote get-url origin 2>/dev/null || echo '(no remote yet)')"
  echo "Generated on $(date +%Y-%m-%d) with record_history.sh (read-only git commands)"
  echo; echo "== git log --oneline --graph --all --decorate"
  git log --oneline --graph --all --decorate
  echo; echo "== git tag"; git tag
  echo; echo "== git branch -a"; git branch -a
  echo; echo "== what each commit changed (oldest first)"
  git log --reverse --format='%h  %ad  %s' --date=format:'%Y-%m-%d %H:%M' --name-status | grep -v '^$'
  if git cat-file -e HEAD:server1/version.txt 2>/dev/null; then
    echo; echo "== the three servers after each commit that touched them"
    for c in $(git log --reverse --format=%h -- server1 server2 server3); do
      printf '%s  %-58s' "$c" "$(git log -1 --format=%s "$c" | cut -c1-56)"
      for s in 1 2 3; do printf 'server%s=%s  ' "$s" "$(git show "$c:server$s/version.txt" 2>/dev/null | tr -d '\r\n')"; done
      echo
    done
  fi
  echo; echo "== git reflog (every movement of HEAD)"
  git reflog --format='%h %gd %gs'
} > "$OUT"
echo "Written: $OUT ($(wc -l < "$OUT") lines)"

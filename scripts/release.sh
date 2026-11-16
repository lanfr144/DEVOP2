#!/bin/bash
# ==============================================================================
# DEVOP2 - publish a new version of the repository (MAJOR.MINOR.PATCH)
# ==============================================================================
# Usage:  ./scripts/release.sh next-unit|same-unit|fix "what changed"
#   next-unit (or major) = the work moves on to the next unit   1.4.1 -> 2.0.0
#   same-unit (or minor) = a change inside the same unit        2.0.0 -> 2.1.0
#   fix       (or patch) = a small fix                          2.1.0 -> 2.1.1
# It updates VERSION and CHANGELOG.md, commits everything, creates the
# annotated tag vX.Y.Z and pushes the branch and the tag when a remote exists.
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

level="${1:-}"; message="${2:-}"
case "$level" in
  next-unit|major) level=major ;;
  same-unit|minor) level=minor ;;
  fix|patch)       level=patch ;;
  *) echo "Usage: $0 next-unit|same-unit|fix \"what changed\"" >&2; exit 1 ;;
esac
[ -n "$message" ] || { echo "Give a short description of the change." >&2; exit 1; }

current=$(tr -d ' \r\n' < VERSION)
[[ "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "VERSION must contain three numbers (found '$current')." >&2; exit 1; }
IFS=. read -r major minor patch <<<"$current"
case "$level" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
esac
new="$major.$minor.$patch"
git rev-parse -q --verify "refs/tags/v$new" >/dev/null && { echo "Tag v$new already exists." >&2; exit 1; }

echo "$new" > VERSION
# insert the new entry above the most recent one
awk -v entry="## v$new - $(date +%Y-%m-%d)\n- $message\n" \
    '!done && /^## v[0-9]/ { printf "%s\n", entry; done = 1 } { print }' CHANGELOG.md > CHANGELOG.tmp
mv CHANGELOG.tmp CHANGELOG.md

git add -A
git commit -m "v$new - $message"
git tag -a "v$new" -m "$message"
echo "Version $current -> $new (tag v$new)"

if git remote get-url origin >/dev/null 2>&1; then
  git push origin HEAD "v$new"
else
  echo "No remote 'origin': nothing pushed."
fi

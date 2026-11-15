#!/bin/bash
# DEVOP2 toolbox entrypoint: prepares Git, then runs the container command.
# Values come from the unit's .env (GIT_USER_NAME, GIT_USER_EMAIL, GH_TOKEN);
# nothing is written in the image.
set -e

# The project is a bind mount owned by another user: tell Git it is trusted.
git config --global --add safe.directory '*'
git config --global init.defaultBranch main
[ -n "${GIT_USER_NAME:-}" ]  && git config --global user.name  "$GIT_USER_NAME"
[ -n "${GIT_USER_EMAIL:-}" ] && git config --global user.email "$GIT_USER_EMAIL"

# gh reads GH_TOKEN from the environment; this makes "git push" use it too.
if [ -n "${GH_TOKEN:-}" ]; then
  git config --global credential."https://github.com".helper '!gh auth git-credential'
fi

exec "$@"

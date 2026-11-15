# ==============================================================================
# DEVOP2 - toolbox image: every prerequisite of the exercises, installed once.
# ==============================================================================
# Nothing has to be installed on the host except Docker (and bash to run the
# *.sh helpers). Each unit starts this image as its "tools" service:
#   Unit 01  python + pymongo (log_to_mongo.py), curl
#   Unit 02  curl + python (queries, Kibana API, test_p02.sh)
#   Unit 03  python + pyyaml + python-dotenv
#   Unit 04  git + gh (release-strategies lab)
#   Unit 05  git + gh (rollback lab, TestUnit5.sh)
# mongosh is NOT installed here: it already lives in the mongo:7 container
# (docker compose exec mongo mongosh ...).
# ==============================================================================
FROM python:3.12-slim-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git gh jq less nano \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --root-user-action=ignore \
      pyyaml python-dotenv pymongo requests pytest

COPY entrypoint.sh /usr/local/bin/devop2-entrypoint
# strip CR in case the file was checked out with Windows line endings
RUN sed -i 's/\r$//' /usr/local/bin/devop2-entrypoint \
 && chmod +x /usr/local/bin/devop2-entrypoint

WORKDIR /work

# Healthy = every prerequisite answers. "docker compose up --wait" blocks until
# this passes, so an exercise never starts with a missing tool.
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD python -c "import yaml, dotenv, pymongo, requests" \
   && git --version >/dev/null && gh --version >/dev/null \
   && curl --version >/dev/null || exit 1

ENTRYPOINT ["devop2-entrypoint"]
CMD ["sleep", "infinity"]

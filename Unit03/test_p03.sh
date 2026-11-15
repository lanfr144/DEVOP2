#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 03 - Automated test of the P03 deliverable
# ==============================================================================
#   1. Ex.1 config.yaml: valid YAML, dev/staging/prod with DB_URL, API_KEY,
#      DEBUG; 2-space indentation; lowercase booleans
#   2. Ex.3 app.py in the 3 environments: right mode, secrets masked
#      -> the output is saved in terminal_output_3_envs.txt (deliverable)
#   3. Ex.2 unknown APP_ENV raises ValueError
#   4. Ex.2 APP_ENV is case-insensitive (PROD = prod)
#   5. config_bad.yaml (negative example) is rejected by the YAML parser
#   6. Ex.2 step 2: the validated loader raises KeyError on a missing key
#   7. Appendix loader_env.py: .env.dev/.staging/.prod + DEBUG=TRUE -> True
#   8. .env.* files are git-ignored, .env.example is present
#
# Usage:  ./test_p03.sh 2>&1 | tee test_p03_output.txt
# ==============================================================================
set -uo pipefail
cd "$(dirname "$0")"

# Use the project venv when it exists (pyyaml + python-dotenv installed there)
PY=python3; [ -x venv/bin/python ] && PY=venv/bin/python

FAILS=0
pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; FAILS=$((FAILS + 1)); }

echo "=== P03 test - $(date -u +%Y-%m-%dT%H:%M:%SZ) - $($PY --version)"

# 1. config.yaml ---------------------------------------------------------------
if $PY -c "
import yaml
d = yaml.safe_load(open('config.yaml'))['environments']
assert set(d) == {'dev', 'staging', 'prod'}, d.keys()
for env, c in d.items():
    assert set(c) == {'DB_URL', 'API_KEY', 'DEBUG'}, (env, c.keys())
    assert isinstance(c['DEBUG'], bool), env
" && ! grep -nE '^( {1}| {3}| {5})[^ ]' config.yaml && ! grep -qE 'DEBUG: (True|False|TRUE|FALSE)' config.yaml; then
  pass "1 config.yaml: 3 environments x (DB_URL, API_KEY, DEBUG), 2-space indent, lowercase booleans"
else
  fail "1 config.yaml"
fi

# 2. app.py in the 3 environments (deliverable output) -------------------------
OUT=terminal_output_3_envs.txt
{
  echo "# DEVOP2 Unit 03 - output of app.py in the 3 environments ($(date -u +%Y-%m-%d))"
  for env in dev staging prod; do
    echo
    echo "\$ APP_ENV=$env python app.py"
    APP_ENV=$env $PY app.py 2>&1
  done
} > "$OUT"
cat "$OUT" | sed 's/^/      /'
if grep -A1 'APP_ENV=dev '     "$OUT" | grep -q '\[DEBUG MODE\]' &&
   grep -A1 'APP_ENV=staging ' "$OUT" | grep -q '\[DEBUG MODE\]' &&
   grep -A1 'APP_ENV=prod '    "$OUT" | grep -q '\[PRODUCTION MODE\]' &&
   ! grep -qE '_pass|12345|67890|abcdef' "$OUT"; then
  pass "2 app.py: DEBUG in dev+staging, PRODUCTION in prod, password and API key masked"
else
  fail "2 app.py output (see $OUT)"
fi

# 3. invalid environment ---------------------------------------------------------
err=$(APP_ENV=qa $PY app.py 2>&1 | tail -1)
[[ "$err" == "ValueError: Invalid APP_ENV: qa."* ]] && pass "3 APP_ENV=qa -> $err" || fail "3 got: $err"

# 4. case-insensitive -------------------------------------------------------------
APP_ENV=PROD $PY app.py 2>&1 | grep -q 'PRODUCTION MODE' \
  && pass "4 APP_ENV=PROD accepted (lower-cased)" || fail "4 APP_ENV=PROD"

# 5. bad YAML ----------------------------------------------------------------------
# PyYAML ends its traceback with the position, the error class is a few lines above
err=$($PY -c "import yaml; yaml.safe_load(open('config_bad.yaml'))" 2>&1 | grep -E '^yaml\.[a-z]+\.[A-Za-z]+Error' | head -1)
[ -n "$err" ] && pass "5 config_bad.yaml rejected: $err (API_KEY= instead of API_KEY:)" || fail "5 config_bad.yaml accepted"

# 6. validated loader, missing key -------------------------------------------------
tmp=$(mktemp --suffix=.yaml)
printf 'environments:\n  dev:\n    DB_URL: "x"\n    DEBUG: true\n' > "$tmp"
err=$($PY -c "import config_loader_validated as c; c.load_config('$tmp')" 2>&1 | tail -1)
rm -f "$tmp"
[[ "$err" == *"KeyError"*"API_KEY"* ]] && pass "6 validated loader: $err" || fail "6 got: $err"

# 7. .env variant ---------------------------------------------------------------------
ok=1
for env in dev staging prod bad; do
  expected=True; [ $env = prod ] && expected=False
  got=$(APP_ENV=$env $PY loader_env.py 2>&1 | grep -o 'DEBUG.*' )
  [[ "$got" == *"$expected" ]] || { ok=0; echo "      .env.$env -> $got (expected $expected)"; }
done
[ $ok = 1 ] && pass "7 loader_env.py: dev/staging True, prod False, bad (DEBUG=TRUE) True" || fail "7 loader_env.py"

# 8. secrets ------------------------------------------------------------------------
if grep -qx '.env.\*' ../.gitignore && grep -qx '!.env.example' ../.gitignore && [ -f .env.example ]; then
  pass "8 .env.* git-ignored, .env.example versioned"
else
  fail "8 .gitignore / .env.example"
fi

echo "=== $([ $FAILS -eq 0 ] && echo 'ALL TESTS PASSED' || echo "$FAILS TEST(S) FAILED")"
exit $FAILS

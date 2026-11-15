# DEVOP2 – Unit 03 – P03 deliverable: application configuration

Author: François Lange · Date: 2026-10-26

## Exercise 1 – `config.yaml`

Three environments under `environments:` (`dev`, `staging`, `prod`), each with `DB_URL`, `API_KEY` and `DEBUG`. 2-space indentation, lowercase booleans (`true` / `false`). The values are fake (demo).

## Exercise 2 – `config_loader.py`

`load_config()` reads `APP_ENV` (default `dev`, case-insensitive), raises `ValueError` when the environment doesn't exist, and converts `DEBUG` to a boolean.
`config_loader_validated.py` (step 2) also raises `KeyError` when a required key is missing.

### Bug fixed (2026-10-26)

`config.yaml` puts the environments under a top-level key `environments:`, but the loader looked for `dev` at the top level. Every environment failed:

```
ValueError: Invalid APP_ENV: dev. Choose from ['environments']
```

Fix: `configs = data.get("environments", data)`. The loader reads the `environments` section, and still accepts a file where `dev/staging/prod` are at the top level. The path to `config.yaml` is now resolved next to the script, so the app works from any directory.

## Exercise 3 – `app.py`: output in the 3 environments

(Also saved in `terminal_output_3_envs.txt`.)

```
$ APP_ENV=dev python app.py
[DEBUG MODE] Verbose logs enabled
Connecting to DB: postgresql://dev_user:****@localhost:5432/dev_db
Using API key: dev-... (masked)

$ APP_ENV=staging python app.py
[DEBUG MODE] Verbose logs enabled
Connecting to DB: postgresql://staging_user:****@staging-db:5432/staging_db
Using API key: stag... (masked)

$ APP_ENV=prod python app.py
[PRODUCTION MODE] Logging minimal
Connecting to DB: postgresql://prod_user:****@prod-db:5432/prod_db
Using API key: prod... (masked)
```

* The database password is replaced with `****`, and only the first 4 characters of the API key are shown.
* PowerShell: `$env:APP_ENV="prod"; python app.py`.

## Appendix – `.env` variant (`loader_env.py`)

* `.env.dev`, `.env.staging`, `.env.prod`: one file per environment, loaded with `python-dotenv`.
* `.env.bad` shows that `DEBUG=TRUE` (uppercase) is still read as `True`.
* Fixed 2026-10-26: in the 4 `.env.*` files, every `:` in the URLs had become `=` (`postgresql=//dev_user=dev_pass@localhost=5432/…`, probably a global search-and-replace). The URLs are valid again.
* `.env.example` is the versioned template. The `.env.*` files are git-ignored.

## Negative example – `config_bad.yaml`

`API_KEY= "staging-67890"` (`=` instead of `:`) → `yaml.scanner.ScannerError`.
`DEBUG: FALSE` is accepted by PyYAML (YAML 1.1) but breaks the lowercase convention.
Quick check: `python -c "import yaml; yaml.safe_load(open('config_bad.yaml'))"`.

## Installation and test

```bash
python -m venv venv && source venv/bin/activate
pip install pyyaml python-dotenv
./test_p03.sh 2>&1 | tee test_p03_output.txt
```

Result on 2026-10-26: **ALL TESTS PASSED** (8 checks).

1. structure of `config.yaml`
2. output for the 3 environments with secrets masked
3. `ValueError` on an unknown environment
4. `PROD` = `prod`
5. `config_bad.yaml` rejected
6. `KeyError` on a missing key
7. `.env` variant
8. `.gitignore`

## Note on `.gitignore`

The repository has a single `.gitignore`, at its root (`../.gitignore`). It ignores `.env` and `.env.*` and keeps `.env.example`. `config.yaml` is committed: it is a deliverable of Exercise 1 and only holds fake values. A `config.yaml` with real secrets would have to be ignored and replaced by a `config.yaml.example`.

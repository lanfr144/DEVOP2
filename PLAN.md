# DEVOP2 – Exercises: action plan

Updated: 2026-10-26 · Reference: `todo.docx`

## 1. Status

| Unit | Before | Now | Remaining (for you) |
|---|---|---|---|
| P01 MongoDB | ~80 %: wrong 24 h query, no paragraph, empty DB, mongo-express *unhealthy*, password in `todo.sh` | ✅ done & tested (8/8) | Change the Mongo password (it was published in clear text) |
| P02 ELK | ~65 %: no comparison, no Lens/dashboard, passwords in the docx | ✅ done & tested (10/10) | **Dashboard screenshot** (`Unit02/dashboard.png`) + change the elastic / kibana_system passwords |
| P03 Config | Loader broken for all 3 environments, `.env.*` corrupted | ✅ done & tested (8/8) | Decide whether `config.yaml` is committed (see P03_DELIVERABLE.md) |
| P04 Release | GitHub repo with only "Initial commit" | ⏳ to do | §4 below (≈ 2 h + GitKraken 30 min) |
| P05 Rollback | not started | ⏳ to do | §5 below (≈ 2 h) |

Run all the tests again:

```bash
cd ~/…/DEVOP2/EXERCISES          # /mnt/c/Users/lanfr144/Documents/semestre_3/DEVOP2/EXERCISES
Unit01/test_p01.sh               # isolated stack, deleted at the end
Unit02/test_p02.sh               # needs the Unit02 stack running (docker compose up -d --wait)
Unit03/test_p03.sh
```

## 2. What was changed and why

The originals are saved in `.backup_2026-10-26/` (git-ignored, because it contains secrets).

### Common rule for secrets
* Every password is in a **`.env`** file, listed in `.gitignore`. Nothing in the compose files, scripts or reports.
* Every unit has a **`.env.example`** where each password's value is its own name: `PASSWORD_MONGO_ROOT=PASSWORD_MONGO_ROOT`, `PASSWORD_ELASTIC=PASSWORD_ELASTIC`, …
* Password variables were renamed with the `PASSWORD_*` prefix:

| Old | New | Unit |
|---|---|---|
| `MONGO_ROOT_PASSWORD` | `PASSWORD_MONGO_ROOT` | 01 |
| `EXPRESS_BASICAUTH_PASSWORD` | `PASSWORD_EXPRESS_BASICAUTH` | 01 |
| `ELASTIC_PASSWORD` | `PASSWORD_ELASTIC` | 02 |
| `KIBANA_PASSWORD` | `PASSWORD_KIBANA` | 02 |

* New `EXERCISES/.gitignore` (`.env`, `.env.*`, backups, venv). The `.gitignore` files are now LF (Unit03 was CRLF).

### P01 – `Unit01/`
| File | Change |
|---|---|
| `docker-compose.yml` | Passwords → `PASSWORD_*`. **mongo-express healthcheck fixed**: `localhost` → `127.0.0.1` (BusyBox resolved IPv6 `::1`, connection refused, so it was always *unhealthy*) and `/status` (no Basic Auth). Seed script mounted. Container names can be overridden (for the test). |
| `init/01-seed-logs.js` (new) | Loads `logs.ndjson` on the first start, **converting `timestamp` to a Date**, idempotent (upsert), adds indexes. |
| `load_logs.sh` (new) | Same load, on demand, for an existing volume. |
| `queries.js`, `run_queries.sh` (new) | The 3 queries with **NOW = 2025-09-18T10:00Z, window [NOW-24 h; NOW[**. Refuses to run on an empty collection. |
| `log_to_mongo.py` (new) | Python `logging` handler → writes logs **directly** into MongoDB (your remark "direct the logger to the database"). |
| `todo.sh` | The clear-text password is removed; it now reads `.env`. |
| `.env.example`, `.gitignore` (new) | Template with dummy values; `.env` ignored. |
| `P01_DELIVERABLE.md` (new) | Deliverable: queries, outputs, **interpretation paragraph**, explanations. |
| `queries_output.txt`, `test_p01.sh`, `test_p01_output.txt` (new) | Proof and test. |

**About your remark "insert logs before querying":** that's right, and it was the real cause. The live database was **empty**, and when the data came from `mongoimport`, `timestamp` was a **String**, so `$gte: ISODate(...)` never matched. Using an old date (2025-01-01) hid the problem. Now the seed script fills the database with real Dates, and the query uses the exact window the exercise asks for. The result (3) is the same, but it is now correct by construction.

### P02 – `Unit02/`
| File | Change |
|---|---|
| `docker-compose.yml` | Header comments; `PASSWORD_ELASTIC` / `PASSWORD_KIBANA`. The rendered config is **identical** (checked with `docker compose config` before/after), so no restart was needed. Healthchecks: ES + Kibana (setup = one-shot job). |
| `.env` (new, local) | Copy of the root `.env`, renamed keys. Before, the stack used `../.env`. |
| `.env.example` | Replaces `dot_env` (dummy values). |
| `Elasticsearch.docx` | The **2 clear-text passwords** (elastic and kibana_system, compose section) are replaced with `${PASSWORD_ELASTIC}` / `${PASSWORD_KIBANA}`. The 11 screenshots were checked (password masked). |
| `kibana/p02-dashboard.ndjson` + `create_dashboard.sh` (new) | Data view + Lens "Logs by service" + 2nd panel "Logs by level" + dashboard, imported through the API. |
| `P02_DELIVERABLE.md` (new) | Deliverable with the **Unit 01 / Unit 02 comparison**. |
| `test_p02.sh`, `test_p02_output.txt` (new) | Test. |

### P03 – `Unit03/`
| File | Change |
|---|---|
| `config_loader.py`, `config_loader_validated.py` | **Bug**: read `data["environments"]` (it used to raise ValueError for every environment). Path resolved next to the script. |
| `.env.dev/.staging/.prod/.bad` | URLs repaired (`postgresql=//user=pass@host=5432` → `postgresql://user:pass@host:5432`). |
| `.env.example` (new), `.gitignore` (LF) | Template + ignore. |
| `venv` | `pyyaml` and `python-dotenv` installed (they were missing). |
| `terminal_output_3_envs.txt` (new) | **Required deliverable**: output for the 3 environments. |
| `P03_DELIVERABLE.md`, `test_p03.sh`, `test_p03_output.txt` (new) | Deliverable + test. |

## 3. Immediate actions (you, 15 min)

1. **Change the passwords that were in clear text** (they appeared in `todo.sh`, the docx, and this session's output):
   ```bash
   # Elastic
   docker exec -it elasticsearch bin/elasticsearch-reset-password -u elastic -i
   docker exec -it elasticsearch bin/elasticsearch-reset-password -u kibana_system -i
   # → update PASSWORD_ELASTIC / PASSWORD_KIBANA in Unit02/.env (and ../.env), then:
   cd Unit02 && docker compose up -d --wait
   ```
   For Mongo, the root password is only set when the volume is created. Either change it in mongosh
   (`db.getSiblingDB("admin").changeUserPassword("admin", passwordPrompt())`), then update
   `PASSWORD_MONGO_ROOT` in `Unit01/.env` and run `docker compose up -d`; or delete the volume
   (`docker compose down -v`), change `.env`, and run `up` again (the seed script reloads the logs).
2. **P02 screenshot**: open <http://localhost:5602/app/dashboards#/view/p02-dashboard>, check both panels, save the screenshot as `Unit02/dashboard.png`.
3. `Unit02/LISEZMOI.md` is a copy of the **Unit03** README (wrong folder). Delete it or replace it with a Unit 02 README.

## 4. P04 – Release management (to do, ≈ 2 h 30)

Source: `Unit04/Unit 04b - Release Management Lab.docx`. The repo `github.com/lanfr144/release-strategies-lab` exists but has only "Initial commit", so **continue from that repo**.

```bash
cd ~ && git clone https://github.com/lanfr144/release-strategies-lab.git && cd release-strategies-lab
```

| Step | Commands / content | Done when |
|---|---|---|
| 1.2 v1.0.0 | `echo "print('Hello, version 1.0.0')" > app.py` → commit → `git tag -a v1.0.0 -m "First release"` | `git tag` shows v1.0.0 |
| 1.3 v1.1.0 | append `print('New feature: logging enabled')` → commit → `git tag -a v1.1.0 -m "Logging"` | |
| 1.4 v2.0.0 | `printf "def start_app():\n    print('App starting with new API')\n" > app.py` → commit → `git tag -a v2.0.0 -m "Breaking API"` | |
| Question 1 | bug fix after v2.0.0 → **v2.0.1** (PATCH); new endpoint with no breaking change → **v2.1.0** (MINOR) | answer in the deliverable |
| 2.2 Notes | `RELEASE_NOTES.md`, newest first, breaking change clearly marked (start from `Unit04/RELEASE_NOTES.md`, add `##` headings and the WARNING) | |
| 2.3 Push | `git push origin main --tags` | 3 tags + notes visible on GitHub |
| 3.1 Blue/green | branches `blue`, `green`, `deployment.txt`, `git merge green` into main | `git log --oneline --graph --all` + 1 sentence |
| 3.2 Rolling | `server1..3/version.txt`: v1.0.0 → v1.1.0 one server at a time, 1 commit per batch | answer: what to check between batches |
| 3.3 Canary | `server1` → `v2.0.0 (canary)` | metrics + stop threshold (e.g. errors > 1 %, p95 > 2× baseline) |
| 4 Rollback | `git revert --no-edit HEAD` (not reset) | canary commit still in the history |
| Debrief | answer the lab's questions | |
| 04b GitKraken | install + connect GitHub, clone `unit04`, branch `1.1-release`, commit, push, **revert** | screenshots of the graph |

Deliverable: `Unit04/P04_DELIVERABLE.md` with the commands, `git log --oneline --graph --all --decorate`, the answers, and the GitKraken screenshots.
Test to add (`Unit04/test_p04.sh`): `git tag` contains the 3 versions; `git ls-remote --tags origin` shows them on GitHub; `RELEASE_NOTES.md` exists on main; there is a revert commit (`git log --grep '^Revert'`); `server1/version.txt` = stable version.

## 5. P05 – Rollbacks with Git (to do, ≈ 2 h)

Source: `Unit05/Unit 05 - Rollback Strategies-1.pdf`. Create a new practice repo, e.g. `rollback-lab` (local, push optional).

| Part | Goal | Key command | Proof to keep |
|---|---|---|---|
| 3 | Undo an uncommitted change | `git restore file` | `git status` before/after |
| 4 | Unstage a file | `git restore --staged file` (or `git reset file`) | `git status` |
| 5 | Undo a published commit | `git revert <hash>` | `git log --oneline` (the revert commit is visible) |
| 6 | Compare resets | `git reset --soft/--mixed/--hard HEAD~1` | where the changes end up (index / working tree / lost) |
| 7 | Recover after `--hard` | `git reflog` → `git reset --hard HEAD@{n}` (or `git branch rescue <hash>`) | reflog output |
| 8 | Restore a deleted file | `git restore --source=HEAD~1 file` / `git checkout <hash> -- file` | `ls` before/after |
| 9 | Tags + revert vs reset | tags v1.0.0 / v2.0.0, then `revert` vs `reset --hard` + `push --force` (on a test branch!) | explain why force push is dangerous |
| 10 | Hotfix | `git switch -c hotfix/x v2.0.0` → fix → merge → tag v2.0.1 | graph |

Quiz (answer in the deliverable):
1. revert creates a new inverse commit and keeps the history; reset moves the branch and rewrites history.
2. `reset --hard` deletes uncommitted changes with no undo, and rewrites shared history if you push.
3. After a hard reset: `git reflog`, then `git reset --hard HEAD@{n}` or create a branch on the hash.
4. Deleted file: `git restore --source=<commit> -- file`.
5. On a shared branch, use a hotfix (or revert). Keep reset for local, unpublished commits.

Deliverable: `Unit05/P05_DELIVERABLE.md` (commands + outputs + quiz). Test to add: script checking for a `Revert` commit, the `v1.0.0`/`v2.0.0`/`v2.0.1` tags, and a merged `hotfix/*` branch.

## 6. Recommended order

1. §3 (passwords + screenshot): 15 min
2. P04: 2 h 30
3. P05: 2 h
4. Run the 3 tests again and check that `git status` shows no `.env` before any push

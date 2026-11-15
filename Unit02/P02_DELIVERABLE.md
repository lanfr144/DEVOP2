# DEVOP2 – Unit 02 – P02 deliverable: Elasticsearch & Kibana

Author: François Lange · Date: 2026-10-26
Detailed walkthrough (commands and screenshots): `Elasticsearch.docx`.

## Files

| File | Role |
|---|---|
| `docker-compose.yml` | Elasticsearch 8.15.3 (TLS + auth) + Kibana, with healthchecks; `setup` generates the certificates |
| `.env.example` | Variables to define (dummy values `PASSWORD_ELASTIC=PASSWORD_ELASTIC`…). Copy to `.env` (git-ignored) |
| `query_a_search.json` | Part A, full-text search "payment" → 4 hits |
| `query_b_filter.json` | Part A, filter level = ERROR → 5 hits |
| `query_c_agg_level.json` | Part A, aggregation by level → ERROR 5 / INFO 6 / WARN 4 |
| `query_custom_agg.json` | Part A, custom aggregation: top 3 services → auth-api 5 / orders-api 5 / payment-api 5 |
| `logs-demo-export.json` | Part A, index export (15 documents) |
| `kibana/p02-dashboard.ndjson` + `kibana/create_dashboard.sh` | Part B: data view + 4 Lens + dashboard, as code |
| `test_p02.sh` / `test_p02_output.txt` | Automated test (10 checks, all PASS) |
| `dashboard.png` | **To add:** dashboard screenshot (manual step, see below) |

## Part A – Elasticsearch

* 15 documents ingested into `logs-demo` with `_bulk` (the Unit 01 dataset, re-dated): 3 services (`auth-api`, `orders-api`, `payment-api`), 3 levels (INFO, WARN, ERROR).
* The 3 required queries and the custom aggregation are saved in the `query_*.json` files.
  `test_p02.sh` re-runs them live and checks that the result equals the saved file.
* Export: `_search?size=100` → `logs-demo-export.json`. The default `size` is 10, so without it the export would be incomplete.

### Unit 01 (MongoDB) vs Unit 02 (Elasticsearch)

Elasticsearch makes free-text log search much easier: the inverted index finds "payment" in any message and ranks the results by relevance, where MongoDB needs a regex or a dedicated text index. Aggregations (count by level, top services) take a few lines of JSON, return instantly, and Kibana turns them into charts without writing any code. MongoDB, on the other hand, is still better as the primary store: a flexible document model, field updates, transactions, and precise queries on structured fields (`user_id`, time window), as in Unit 01. Elasticsearch is also heavier to run: TLS certificates, the `kibana_system` account, at least 1 GB of JVM memory, and a mapping (`text` vs `keyword`) that you have to understand to filter correctly (`level.keyword`). In practice the two complement each other: the application writes to MongoDB (the source of truth), and the logs are indexed into Elasticsearch for search and dashboards.

## Part B – Kibana

1. **Data view** `Logs-Demo-01`, pattern `logs-demo*`, time field `@timestamp` (made by hand, screenshot in the docx).
   `create_dashboard.sh` also creates `P02 logs-demo`, the same thing as code.
2. **Discover**: time range "Last 1 year", KQL `level : "ERROR"` → **5 documents** = `query_b_filter.json` (Part A).
   KQL on a `text` field is case-insensitive (the field is analysed); `level.keyword : "ERROR"` would be case-sensitive.
3. **Lens "P02 - Logs by service"**: stacked bars, X = `service.keyword`, Y = count, broken down by `level.keyword`.
4. **Second panel "P02 - Logs by level"**: donut, count by `level.keyword`.
5. **Two more panels** (added 2026-11-15): "P02 - Errors by service" (bars, KQL `level.keyword : "ERROR"`, total must be 5 as in Part A) and "P02 - Logs over time" (date histogram on `@timestamp`, broken down by level).
6. **Dashboard "P02 - Logs demo dashboard"**: the four panels, saved time range = last year.

```bash
./kibana/create_dashboard.sh     # (re)creates the 4 objects; overwrite=true, no duplicates
```

### Remaining manual step: the screenshot

1. Open <http://localhost:5602/app/dashboards#/view/p02-dashboard> (login `elastic` / `PASSWORD_ELASTIC` from `.env`).
2. Check that the four panels show data (time range "Last 1 year"). If one doesn't, open it in Lens with *Edit*, fix it, and *Save*.
3. Take the screenshot (Windows: `Win + Shift + S`) and save it as `Unit02/dashboard.png`.

To build it by hand instead of the script (what the exercise asks you to practise):
*Dashboards → Create dashboard → Create visualization* → drag `service.keyword` onto the X axis, choose "Bar vertical stacked", drag `level.keyword` onto "Breakdown" → *Save and return*. Then *Create visualization* again → "Donut", `level.keyword` → *Save and return* → *Save* the dashboard.

## Security

* No password in the compose file, the report, or the docx. The two passwords that were pasted into the compose section of `Elasticsearch.docx` have been replaced with `${PASSWORD_ELASTIC}` and `${PASSWORD_KIBANA}`. The screenshots were checked: the password field is masked.
* `.env` (real values) is git-ignored; `.env.example` holds the variable name as the value.
* Those passwords were in clear text, so consider them compromised and **change them**:
  * `elastic`: `docker exec -it elasticsearch bin/elasticsearch-reset-password -u elastic -i`, then update `PASSWORD_ELASTIC`;
  * `kibana_system`: the same with `-u kibana_system`, update `PASSWORD_KIBANA`, then `docker compose up -d kibana`.
* `curl -k` / `verificationMode` are acceptable locally only (self-signed certificate). See the explanation in the docx.

## Test

```bash
docker compose up -d --wait
./test_p02.sh 2>&1 | tee test_p02_output.txt
```

Result on 2026-10-26: **ALL TESTS PASSED**.

1. compose valid with healthchecks
2. no secret outside `.env` (docx contents included)
3. ES and Kibana healthy
4. 15 docs, 3 services, 3 levels
5. the 4 queries give the same results as the saved files
6. complete export
7. Kibana available, data view on `@timestamp`, dashboard with 2 Lens panels, ERROR count in Kibana = Part A

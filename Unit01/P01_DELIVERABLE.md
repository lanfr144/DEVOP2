# DEVOP2 – Unit 01 – P01 deliverable: MongoDB & logs

Author: François Lange · Date: 2026-10-26

## Files

| File | Role |
|---|---|
| `docker-compose.yml` | Part 1 + Part 3 bonus: `mongo:7` (persistent volume, authentication) + `mongo-express`, both with a healthcheck |
| `.env.example` | Variables to define (dummy values). Copy it to `.env`; `.env` is git-ignored |
| `init/01-seed-logs.js` | Loads `logs.ndjson` into `unit01.logs` with **real Date** timestamps (runs automatically on the first start) |
| `load_logs.sh` | Same load, by hand, on an existing volume (idempotent, no duplicates) |
| `queries.js` / `run_queries.sh` | Part 2: the 3 queries |
| `queries_output.txt` | Raw output of the 3 queries (live stack, 2026-10-26) |
| `log_to_mongo.py` | Python `logging` handler that writes logs **directly** into MongoDB |
| `test_p01.sh` / `test_p01_output.txt` | Automated test of the whole deliverable (8 checks, all PASS) |

## Part 1 – Container, import, shell

```bash
cp .env.example .env            # set PASSWORD_MONGO_ROOT and PASSWORD_EXPRESS_BASICAUTH
docker compose up -d --wait     # waits until both healthchecks are "healthy"
./load_logs.sh                  # only needed if the volume existed before
docker exec -it mongodb_service mongosh -u admin -p --authenticationDatabase admin unit01
```

* Persistent volume: `mongo_data:/data/db`. The data survives `docker compose down` / `up`.
* Authentication: `MONGO_INITDB_ROOT_USERNAME` / `_PASSWORD`, read from `.env`.
* `-p` with no value makes mongosh **prompt** for the password, so it never appears in the shell history.

### Why the first queries were empty (and the fix)

1. **No data.** A query on a collection that doesn't exist returns `0` / `[]`, with no error.
   The logs must be inserted *before* querying. The seed script now does this on the first start.
2. **Timestamp stored as a string.** `mongoimport` keeps `"2025-09-17T08:12:21Z"` as a **String**.
   `{timestamp: {$gte: ISODate(...)}}` compares a Date with a String, so nothing ever matches.
   The seed script converts each value with `new Date(...)`, so the field is a BSON `Date`.
   (Fix for data that was already imported:
   `db.logs.updateMany({timestamp: {$type: "string"}}, [{$set: {timestamp: {$toDate: "$timestamp"}}}])`.)
3. That's why the first version used an old date (`2025-01-01`). It is replaced by the real 24 h window below.

## Part 2 – Queries (NOW = 2025-09-18T10:00:00Z)

```js
const NOW   = ISODate('2025-09-18T10:00:00Z');
const SINCE = new Date(NOW.getTime() - 24*60*60*1000);   // 2025-09-17T10:00:00Z

// Q1 - number of ERRORs in the last 24 h
db.logs.countDocuments({ level: 'ERROR', timestamp: { $gte: SINCE, $lt: NOW } })
// -> 3

// Q2 - actions of user U12345
db.logs.find({ user_id: 'U12345' }, { _id: 0, timestamp: 1, service: 1, action: 1 }).sort({ timestamp: 1 })
// -> 5 actions

// Q3 - distinct services that emitted a WARN
db.logs.distinct('service', { level: 'WARN' })
// -> [ 'auth-api', 'orders-api', 'payment-api' ]
```

| Query | Result |
|---|---|
| Q1 ERROR between 2025-09-17T10:00Z and 2025-09-18T10:00Z | **3**: payment-api `transaction_failed` (17/09 10:42), orders-api `create_order_failed` (18/09 06:15), payment-api `transaction_failed` (18/09 07:42) |
| Q2 U12345 | **5**: `create_order_retry` (orders-api) → `transaction_failed` (payment-api) → `transaction_retry` (payment-api) → `logout` (auth-api) → `transaction_latency_high` (payment-api) |
| Q3 WARN services | **auth-api, orders-api, payment-api** |

The full raw output is in `queries_output.txt`.

### Interpretation

Over the last 24 hours the platform logged three errors. Two of them come from `payment-api`, which makes it the most fragile service in this window. User U12345's history shows an incident from the user's point of view: an order retry, then a failed payment on ORD-1001, then a payment retry. Later, the same user hits high latency on `payment-api` (p95 = 910 ms), which suggests a lasting performance problem rather than an isolated failure. All three services emitted WARNs, and the WARN in `auth-api` (7 login attempts by U88888) points to a brute-force attempt, a security signal that has nothing to do with payments. To prioritise, I would investigate `payment-api` latency and errors first, then add an alert on brute-force attempts in `auth-api`.

## Part 3 – Bonus: mongo + mongo-express with docker compose

* `mongo-express` starts only when `mongo` is **healthy** (`depends_on: condition: service_healthy`).
* Both services have a healthcheck:
  * mongo: `mongosh --eval 'db.adminCommand("ping")'`;
  * mongo-express: `wget --spider http://127.0.0.1:8081/status`.
    The old version used `localhost`, which BusyBox resolves to IPv6 `::1` while mongo-express only listens on IPv4, so the container was always "unhealthy". `/status` is the only page that answers without Basic Auth.
* Web UI: <http://localhost:8082> (Basic Auth from `.env`).

## Going further – sending logs directly to MongoDB

`log_to_mongo.py` attaches a `MongoHandler` to Python's `logging`: every `logger.info/warning/error` becomes a document in `unit01.logs`, with the same fields as the dataset and a real `Date`. No more file + `mongoimport` step, and the collection fills up as the application runs.

```bash
pip install pymongo
set -a; . ./.env; set +a; MONGO_HOST_PORT=27018 python log_to_mongo.py
```

## Security

* No password in the versioned files. Everything is in `.env` (git-ignored); `.env.example` holds the variable name as the value (`PASSWORD_MONGO_ROOT=PASSWORD_MONGO_ROOT`).
* `todo.sh` used to contain the password in clear text. It now reads it from `.env`.
* The old password was written in clear text, so consider it **compromised and change it**.

## Test

```bash
./test_p01.sh 2>&1 | tee test_p01_output.txt
```

The test starts an **isolated** stack (separate project, ports and volume), checks the 8 points below, then deletes everything. Result on 2026-10-26: **ALL TESTS PASSED**.

1. compose valid
2. no secret outside `.env`
3. both containers healthy
4. automatic seed (10 docs, Date timestamps)
5. idempotent reload
6. Q1 = 3, Q2 = 5, Q3 = 3 services
7. mongo-express `/status` = 200 and `/` = 401
8. Python logger writes into MongoDB

// ==============================================================================
// DEVOP2 - Unit 01 - Seed script: load logs.ndjson into unit01.logs
// ==============================================================================
// Why this script exists:
//   1. Queries on an empty collection return nothing -> logs must be inserted
//      BEFORE running the P01 queries.
//   2. `mongoimport` keeps "timestamp" as a STRING ("2025-09-17T08:12:21Z").
//      A comparison such as { timestamp: { $gte: ISODate(...) } } compares a
//      Date with a String, which never matches -> the 24 h query was empty.
//      Here every timestamp is converted to a real BSON Date (new Date(...)).
//
// When it runs:
//   - automatically, by the mongo image, on the FIRST start of an empty volume
//     (mounted in /docker-entrypoint-initdb.d by docker-compose.yml);
//   - manually at any time with ./load_logs.sh (safe to run several times).
//
// Idempotent: each document is upserted on (timestamp, service, user_id,
// action), so running it twice does not create duplicates and does not delete
// logs written by other sources (e.g. log_to_mongo.py).
// ==============================================================================

const fs = require('fs');

const SEED_FILE = '/seed/logs.ndjson';
const target = db.getSiblingDB('unit01');

// NDJSON = one JSON document per line; ignore empty lines.
const docs = fs.readFileSync(SEED_FILE, 'utf8')
  .split('\n')
  .filter(line => line.trim().length > 0)
  .map(line => {
    const doc = JSON.parse(line);
    doc.timestamp = new Date(doc.timestamp); // String -> BSON Date
    return doc;
  });

const ops = docs.map(doc => ({
  updateOne: {
    filter: {
      timestamp: doc.timestamp,
      service: doc.service,
      user_id: doc.user_id,
      action: doc.action,
    },
    update: { $setOnInsert: doc },
    upsert: true,
  },
}));

const res = target.logs.bulkWrite(ops);

// Indexes used by the P01 queries (time window, level, user, service).
target.logs.createIndex({ timestamp: 1 });
target.logs.createIndex({ level: 1, timestamp: 1 });
target.logs.createIndex({ user_id: 1 });

print(`seed: ${docs.length} lines read, ${res.upsertedCount} inserted, ` +
      `${docs.length - res.upsertedCount} already present; ` +
      `unit01.logs now holds ${target.logs.countDocuments()} documents`);

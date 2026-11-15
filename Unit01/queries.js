// ==============================================================================
// DEVOP2 - Unit 01 - P01 Part 2: the three queries
// ==============================================================================
// Run:  ./run_queries.sh        (or ./test_p01.sh, which also checks results)
//
// Reference time imposed by the exercise: NOW = 2025-09-18T10:00:00Z.
// We do NOT use new Date() (the real "now", 2026) because the dataset is from
// September 2025: "last 24 h" relative to the real clock would always be empty.
// The window is therefore [NOW - 24 h ; NOW[ = [2025-09-17T10:00Z ; 2025-09-18T10:00Z[.
//
// Correction vs. the first version: the first version counted ERRORs since
// 2025-01-01. It returned the right number (3) only by chance (all ERRORs of
// the dataset happen to be inside the last 24 h). The window below is the one
// the exercise asks for.
// ==============================================================================

db = db.getSiblingDB('unit01');

const NOW = ISODate('2025-09-18T10:00:00Z');
const SINCE = new Date(NOW.getTime() - 24 * 60 * 60 * 1000); // NOW - 24 h

// Safety check: a query on an empty collection silently returns 0 / [].
if (db.logs.countDocuments() === 0) {
  print('ERROR: unit01.logs is empty -> run ./load_logs.sh first');
  quit(1);
}

// ------------------------------------------------------------------------------
// Q1 - Count the ERROR logs of the last 24 h
// ------------------------------------------------------------------------------
print('Q1 - ERROR count between ' + SINCE.toISOString() + ' and ' + NOW.toISOString());
const q1 = db.logs.countDocuments({
  level: 'ERROR',
  timestamp: { $gte: SINCE, $lt: NOW },
});
print(q1);
// Detail (proof of the count):
printjson(db.logs.find(
  { level: 'ERROR', timestamp: { $gte: SINCE, $lt: NOW } },
  { _id: 0, timestamp: 1, service: 1, action: 1 }
).sort({ timestamp: 1 }).toArray());

// ------------------------------------------------------------------------------
// Q2 - List the actions of user_id = "U12345" (chronological order)
// ------------------------------------------------------------------------------
print('Q2 - actions of user U12345');
const q2 = db.logs.find(
  { user_id: 'U12345' },
  { _id: 0, timestamp: 1, service: 1, action: 1 }
).sort({ timestamp: 1 }).toArray();
printjson(q2);

// ------------------------------------------------------------------------------
// Q3 - Distinct services that emitted at least one WARN
// ------------------------------------------------------------------------------
print('Q3 - distinct services with WARN');
const q3 = db.logs.distinct('service', { level: 'WARN' });
printjson(q3);

// Machine-readable summary line, parsed by test_p01.sh
print('RESULT q1=' + q1 + ' q2=' + q2.length + ' q3=' + q3.slice().sort().join(','));

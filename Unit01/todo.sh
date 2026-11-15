#!/bin/sh
# Security (2026-10-26): the password is no longer written in this file.
# It is read from .env (ignored by Git, see .gitignore); copy .env.example to
# .env and set PASSWORD_MONGO_ROOT there.
set -a; . "$(dirname "$0")/.env"; set +a
# The password is handed to Docker through the environment (-e NAME, no value):
# it never appears on a command line. Inside the container, mongosh and
# mongoimport read it from MONGO_INITDB_ROOT_PASSWORD.
export MONGO_INITDB_ROOT_PASSWORD="${PASSWORD_MONGO_ROOT:?PASSWORD_MONGO_ROOT missing in .env}"
docker volume create mongo_data
docker run -d --name mongodb -p 27017:27017 -e MONGO_INITDB_ROOT_USERNAME=admin -e MONGO_INITDB_ROOT_PASSWORD -v mongo_data:/data/db mongo:7
docker logs -f mongodb
docker exec -it mongodb sh -c 'mongosh -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin'
docker cp logs.ndjson mongodb:/data/db/logs.ndjson
docker exec -it mongodb sh -c 'mongoimport -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --db unit01 --collection logs --file /tmp/logs.ndjson'
docker exec -it mongodb sh -c 'mongosh -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin'

echo "
//Essential shell commands
//mongosh
//open the MongoDB shell
show dbs
show databases
print(db)
#use unit01
# OR
db = db.getSiblingDB('unit01');
//switch to / create a database
#db
# OR
print(db);
//show the current database
#db.stats()
# OR
printjson(db.stats());

//create a collection
db.createCollection("logs")

// Show collection
db.getCollectionNames()
//database statistics
//db.dropDatabase ()
//delete the database
" | grep -v '#' | mongosh

docker exec -it mongodb sh -c 'mongoimport -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --db unit01 --collection logs --file /data/db/logs.ndjson'
echo "2026-09-30T09:21:04.468+0000    connected to: mongodb://localhost/"
echo "2026-09-30T09:21:04.475+0000    10 document(s) imported successfully. 0 document(s) failed to import."


docker exec -it mongodb sh -c 'mongosh -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin'

echo "
db = db.getSiblingDB('unit01');
// View the first 20 documents formatted cleanly
db.logs.find()

// View just one document in detail
db.logs.findOne()

// Limit the output to 5 documents
db.logs.find().limit(5)

// Find logs matching a specific level (e.g., "ERROR") Case sansitif
db.logs.find({ level: "ERROR" })

// Find logs where status code is 500
db.logs.find({ status: 500 })

// Project only specific fields (e.g., timestamp and message, hide _id)
db.logs.find({}, { timestamp: 1, message: 1, _id: 0 }).limit(10)

"
# mongosh --eval "
# show dbs;
# print(db);
# // switch to / create a database
# db = db.getSiblingDB('unit01');
# print(db);
# 
# // create a collection
# db.createCollection('logs');
# 
# // database statistics
# printjson(db.stats());
# 
# // delete the database
# db.dropDatabase();
# "
# 


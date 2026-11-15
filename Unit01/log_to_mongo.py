"""DEVOP2 - Unit 01 - Send Python application logs directly to MongoDB.

Instead of writing logs to a file and importing them later (mongoimport), the
application pushes every log record straight into unit01.logs. The database is
populated continuously, so the queries are never run on an empty collection.

Each record is stored with the same fields as logs.ndjson:
    timestamp (real BSON Date, UTC), level, service, user_id, action, + extras

Configuration comes from environment variables (the same names as .env):
    MONGO_HOST (default localhost), MONGO_HOST_PORT (default 27017),
    MONGO_ROOT_USER, PASSWORD_MONGO_ROOT
Never hard-code the password in this file.

Usage:
    pip install pymongo
    set -a; . ./.env; set +a          # load .env into the shell
    python log_to_mongo.py            # writes a few demo logs
"""
import logging
import os
from datetime import datetime, timezone
from urllib.parse import quote_plus

from pymongo import MongoClient


class MongoHandler(logging.Handler):
    """logging.Handler that inserts each record as a document in MongoDB."""

    def __init__(self, collection, service):
        super().__init__()
        self.collection = collection
        self.service = service

    def emit(self, record):
        try:
            doc = {
                # Real datetime -> stored as BSON Date, so date queries work.
                "timestamp": datetime.fromtimestamp(record.created, tz=timezone.utc),
                "level": record.levelname,  # INFO / WARNING / ERROR ...
                "service": self.service,
                "user_id": getattr(record, "user_id", "system"),
                "action": record.getMessage(),
            }
            # Extra fields passed with extra={"fields": {...}}
            doc.update(getattr(record, "fields", {}))
            self.collection.insert_one(doc)
        except Exception:
            # Never crash the application because logging failed.
            self.handleError(record)


def get_collection():
    user = quote_plus(os.environ["MONGO_ROOT_USER"])
    password = quote_plus(os.environ["PASSWORD_MONGO_ROOT"])
    host = os.getenv("MONGO_HOST", "localhost")
    port = os.getenv("MONGO_HOST_PORT", "27017")
    uri = f"mongodb://{user}:{password}@{host}:{port}/?authSource=admin"
    client = MongoClient(uri, serverSelectionTimeoutMS=5000)
    return client["unit01"]["logs"]


def main():
    # The dataset uses WARN, Python uses WARNING: align the name.
    logging.addLevelName(logging.WARNING, "WARN")

    logger = logging.getLogger("demo-app")
    logger.setLevel(logging.INFO)
    logger.addHandler(MongoHandler(get_collection(), service="demo-logger"))

    logger.info("app_started", extra={"user_id": "system"})
    logger.warning("slow_request", extra={"user_id": "U00001", "fields": {"p95_ms": 750}})
    logger.error("db_timeout", extra={"user_id": "U00001", "fields": {"timeout_s": 5}})
    print("demo-logger: 3 log documents written to unit01.logs")


if __name__ == "__main__":
    main()

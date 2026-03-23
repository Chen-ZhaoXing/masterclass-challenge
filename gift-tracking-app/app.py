import json
import os
import time
import logging

from pymongo import MongoClient
from pymongo.errors import ConnectionFailure

# Configure basic logging to stream directly to standard output/error (unbuffered)
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(message)s", datefmt="%H:%M:%S"
)
logger = logging.getLogger(__name__)

# Use environment variables for connection or default to the statefulset values
MONGO_USER = os.getenv("MONGO_INITDB_ROOT_USERNAME", "admin")
MONGO_PASS = os.getenv("MONGO_INITDB_ROOT_PASSWORD", "supersecurepassword123")
MONGO_HOST = os.getenv("MONGO_HOST", "mongodb")
MONGO_PORT = os.getenv("MONGO_PORT", "27017")

MONGO_URI = (
    f"mongodb://{MONGO_USER}:{MONGO_PASS}@{MONGO_HOST}:{MONGO_PORT}/?authSource=admin"
)

BACKUP_DIR = os.getenv("BACKUP_DIR", "/app/data")


def connect_to_mongo():
    logger.info(f"Attempting to connect to MongoDB at {MONGO_HOST}:{MONGO_PORT}...")
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)

    while True:
        try:
            # The ismaster command is cheap and does not require auth.
            client.admin.command("ping")
            logger.info("✅ Successfully connected to MongoDB!")
            break
        except ConnectionFailure:
            logger.warning("❌ MongoDB not available yet, retrying in 5 seconds...")
            time.sleep(5)

    return client


def main():
    if not os.path.exists(BACKUP_DIR):
        logger.warning(
            f"⚠️ WARNING: Backup directory {BACKUP_DIR} does not exist! Is the volume mounted?"
        )
    else:
        logger.info(f"✅ Backup directory {BACKUP_DIR} exists! Data will be backed up.")

    client = connect_to_mongo()
    db = client["northpole"]
    gifts_collection = db["gifts"]

    while True:
        try:
            # Insert a record
            gift = {
                "name": "Bicycle",
                "recipient": "Timmy",
                "status": "Packed",
                "timestamp": time.time(),
            }
            result = gifts_collection.insert_one(gift)
            logger.info(f"🎁 Inserted gift record with ID: {result.inserted_id}")

            # Backup to the persistent volume
            if os.path.exists(BACKUP_DIR):
                try:
                    import json

                    backup_file = os.path.join(BACKUP_DIR, "gifts_backup.jsonl")
                    with open(backup_file, "a") as f:
                        gift_copy = gift.copy()
                        gift_copy["_id"] = str(result.inserted_id)
                        f.write(json.dumps(gift_copy) + "\n")
                except Exception as e:
                    logger.error(f"⚠️ Error writing to backup volume: {e}")

            # Count records
            count = gifts_collection.count_documents({})
            logger.info(f"📊 Total gifts in database: {count}")

        except Exception as e:
            logger.error(f"⚠️ Error interacting with database: {e}")

        time.sleep(10)


if __name__ == "__main__":
    main()

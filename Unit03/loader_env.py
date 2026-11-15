# Appendix: the .env alternative (one file per environment, loaded with python-dotenv).
# Needs a file named .env.dev / .env.staging / .env.prod (never committed), for example:
#   DB_URL=postgresql://dev_user:dev_pass@localhost:5432/dev_db
#   API_KEY=dev-12345
#   DEBUG=true
import os
from dotenv import load_dotenv

env = os.getenv("APP_ENV", "dev")
load_dotenv(f".env.{env}")

DB_URL = os.getenv("DB_URL")
API_KEY = os.getenv("API_KEY")
DEBUG = os.getenv("DEBUG", "false").lower() == "true"  # .env values are always strings

if __name__ == "__main__":
    print("Loaded environment:", env)
    print("Is DEBUG Right=", DEBUG)

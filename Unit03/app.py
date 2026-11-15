# app.py - Exercise 3: use the loader, never print a secret in clear text.
#   python app.py                    -> dev (default)
#   APP_ENV=staging python app.py
#   APP_ENV=prod python app.py
# The DB password and most of the API key are masked in the output.
import re
from config_loader import load_config


def mask_url(url):
    # postgresql://user:pass@host/db -> postgresql://user:****@host/db
    return re.sub(r"(://[^:]+:)[^@]+@", r"\1****@", url)


def main():
    cfg = load_config()

    if cfg["DEBUG"]:
        print("[DEBUG MODE] Verbose logs enabled")
    else:
        print("[PRODUCTION MODE] Logging minimal")

    print(f"Connecting to DB: {mask_url(cfg['DB_URL'])}")
    print(f"Using API key: {cfg['API_KEY'][:4]}... (masked)")


if __name__ == "__main__":
    main()

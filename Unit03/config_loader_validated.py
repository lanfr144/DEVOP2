# Exercise 2, step 2 (optional): load_config() with required-key validation.
# Replace load_config() in config_loader.py with this version.
# Same fix as config_loader.py (2026-10-26): read the "environments" section.
import os
from pathlib import Path

import yaml

DEFAULT_CONFIG = Path(__file__).with_name("config.yaml")


def load_config(path=DEFAULT_CONFIG):
    env = os.getenv("APP_ENV", "dev").lower()

    with open(path, "r") as f:
        data = yaml.safe_load(f)

    # Environments live under "environments:" (fallback: top level).
    configs = data.get("environments", data)

    if env not in configs:
        raise ValueError(
            f"Invalid APP_ENV: {env}. Choose from {list(configs.keys())}"
        )

    config = configs[env]

    # Validate required keys: fail at startup, not later in the middle of a request
    required = ["DB_URL", "API_KEY", "DEBUG"]
    missing = [k for k in required if k not in config]
    if missing:
        raise KeyError(f"Missing required keys: {missing}")

    # Normalize types
    if isinstance(config.get("DEBUG"), str):
        config["DEBUG"] = config["DEBUG"].lower() == "true"

    return config


if __name__ == "__main__":
    cfg = load_config()
    print("Loaded environment:", os.getenv("APP_ENV", "dev"))
    print("DEBUG =", cfg["DEBUG"])

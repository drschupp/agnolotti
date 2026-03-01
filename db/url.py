"""Build database URL from environment variables."""

import os


def get_db_url() -> str:
    driver = os.getenv("DB_DRIVER", "postgresql+psycopg")
    user = os.getenv("DB_USER", "ai")
    password = os.getenv("DB_PASS", "ai")
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "5432")
    database = os.getenv("DB_DATABASE", "ai")
    return f"{driver}://{user}:{password}@{host}:{port}/{database}"

"""Database session management."""

from agno.db.postgres import PostgresDb

from db.url import get_db_url


def get_agent_db() -> PostgresDb:
    return PostgresDb(db_url=get_db_url())

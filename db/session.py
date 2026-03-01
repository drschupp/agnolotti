"""Database session management."""

from agno.db.postgres import PgDb

from db.url import get_db_url


def get_agent_db() -> PgDb:
    return PgDb(db_url=get_db_url())

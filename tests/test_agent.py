"""Basic tests for Agnolotti."""

from unittest.mock import patch


def test_db_url_defaults():
    from db.url import get_db_url

    url = get_db_url()
    assert url == "postgresql+psycopg://ai:ai@localhost:5432/ai"


def test_db_url_from_env():
    with patch.dict(
        "os.environ",
        {
            "DB_USER": "testuser",
            "DB_PASS": "testpass",
            "DB_HOST": "dbhost",
            "DB_PORT": "5433",
            "DB_DATABASE": "testdb",
        },
    ):
        from importlib import reload

        import db.url

        reload(db.url)
        url = db.url.get_db_url()
        assert url == "postgresql+psycopg://testuser:testpass@dbhost:5433/testdb"

# Agnolotti

Agentic AI project built with [Agno](https://docs.agno.com) and Claude Sonnet, served via AgentOS.

## Quick Start (Docker)

```bash
# Clone and configure
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY

# Run with Docker Compose
docker compose up --build
```

The API will be available at http://localhost:8000. Test it at http://localhost:8000/docs.

### Connect to AgentOS UI

1. Open [os.agno.com](https://os.agno.com) and sign in.
2. Click "Add new OS" in the top navigation.
3. Select "Local" and enter `http://localhost:8000` as the endpoint.

## Local Development

```bash
# Install dependencies with uv
uv sync

# Configure environment
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY

# Start Postgres (via Docker)
docker compose up pgvector -d

# Run the app
uv run python app.py
```

## Development

```bash
# Run tests
uv run pytest

# Lint
uv run ruff check .
```

## Deploy to DigitalOcean

This project includes a DigitalOcean App Platform spec in `.do/app.yaml`.

1. Push this repo to GitHub.
2. In the [DigitalOcean App Platform](https://cloud.digitalocean.com/apps), click **Create App**.
3. Select this GitHub repo.
4. DigitalOcean will detect `.do/app.yaml` and configure the app automatically.
5. Set the `ANTHROPIC_API_KEY` secret in the app settings.
6. Deploy.

The spec provisions a `professional-xs` instance and a dev-size managed PostgreSQL database.

## Project Structure

```
agnolotti/
├── agents/
│   └── assistant.py      # Example agent (Claude + DuckDuckGo)
├── db/
│   ├── session.py         # Agno PgDb factory
│   └── url.py             # DB URL from env vars
├── scripts/
│   └── entrypoint.sh      # Docker entrypoint
├── tests/
│   └── test_agent.py
├── .do/
│   └── app.yaml           # DigitalOcean App Platform spec
├── app.py                 # AgentOS FastAPI application
├── compose.yaml           # Docker Compose for local dev
├── Dockerfile
├── pyproject.toml
└── requirements.txt
```

## License

MIT

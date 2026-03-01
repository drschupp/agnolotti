# Agnolotti

Agentic AI project built with [Agno](https://docs.agno.com) and OpenAI, served via AgentOS.

## Quick Start (Docker)

```bash
# Clone and configure
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY

# Run with Docker Compose
docker compose up --build
```

Services are available via Traefik reverse proxy:

- **API:** http://api.localhost (Swagger docs at http://api.localhost/docs)
- **Dashboard:** http://dash.localhost (Agno Agent UI)
- **Traefik Dashboard:** http://localhost:8080

### Connect to AgentOS UI

1. Open [os.agno.com](https://os.agno.com) and sign in.
2. Click "Add new OS" in the top navigation.
3. Select "Local" and enter `http://api.localhost` as the endpoint.

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

The project deploys to [DigitalOcean App Platform](https://docs.digitalocean.com/products/app-platform/) using the spec in `.do/app.yaml`. It provisions:

- **API** (`professional-xs`) at `/api` — path prefix is trimmed, so the app receives requests at `/`
- **Dashboard** (`basic-xs`) at `/` — Agno Agent UI
- **PostgreSQL** (`db-s-dev-database`) — managed database

### Automated deploy (recommended)

Requires the [doctl CLI](https://docs.digitalocean.com/reference/doctl/how-to/install/) authenticated via `doctl auth init`.

**Bash** (Linux/macOS/WSL):

```bash
./scripts/do-deploy.sh              # deploy and wait
./scripts/do-deploy.sh --no-wait    # deploy without waiting
./scripts/do-logs.sh                # API logs (default)
./scripts/do-logs.sh dashboard      # dashboard logs
./scripts/do-teardown.sh            # tear down app + database
```

**PowerShell** (Windows):

```powershell
.\scripts\do-deploy.ps1              # deploy and wait
.\scripts\do-deploy.ps1 -NoWait      # deploy without waiting
.\scripts\do-logs.ps1                # API logs (default)
.\scripts\do-logs.ps1 -Component dashboard
.\scripts\do-teardown.ps1            # tear down app + database
```

After the first deploy, set the `OPENAI_API_KEY` secret in the App Platform console.

### Manual deploy

1. Push this repo to GitHub.
2. In the [DigitalOcean App Platform](https://cloud.digitalocean.com/apps), click **Create App**.
3. Select this GitHub repo — DO will detect `.do/app.yaml` automatically.
4. Set the `OPENAI_API_KEY` secret in the app settings.
5. Deploy.

Once deployed, open the Dashboard in your browser and configure it to connect to `https://<your-app>.ondigitalocean.app/api`.

## Project Structure

```
agnolotti/
├── agents/
│   └── assistant.py      # Example agent (Claude + DuckDuckGo)
├── db/
│   ├── session.py         # Agno PostgresDb factory
│   └── url.py             # DB URL from env vars
├── scripts/
│   ├── entrypoint.sh      # Docker entrypoint
│   ├── do-deploy.sh       # Deploy to DO App Platform (bash)
│   ├── do-deploy.ps1      # Deploy to DO App Platform (PowerShell)
│   ├── do-teardown.sh     # Tear down the DO app (bash)
│   ├── do-teardown.ps1    # Tear down the DO app (PowerShell)
│   ├── do-logs.sh         # Stream DO app logs (bash)
│   └── do-logs.ps1        # Stream DO app logs (PowerShell)
├── tests/
│   └── test_agent.py
├── .do/
│   └── app.yaml           # DigitalOcean App Platform spec
├── app.py                 # AgentOS FastAPI application
├── compose.yaml           # Docker Compose (API, dashboard, pgvector, Traefik)
├── Dockerfile
├── Dockerfile.dashboard   # Dashboard (Agno Agent UI) build
├── pyproject.toml
└── requirements.txt
```

## License

MIT

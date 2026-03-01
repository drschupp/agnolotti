#!/usr/bin/env bash
set -euo pipefail

# Stream logs for an agnolotti component on DigitalOcean App Platform.
#
# Usage:
#   ./scripts/do-logs.sh              # stream API logs (default)
#   ./scripts/do-logs.sh dashboard    # stream dashboard logs
#   ./scripts/do-logs.sh api build    # stream API build logs

APP_NAME="agnolotti"
COMPONENT="${1:-api}"
LOG_TYPE="${2:-run}"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

if ! command -v doctl &>/dev/null; then
    error "doctl CLI not found."
    exit 1
fi

app_id=$(doctl apps list --format ID,Spec.Name --no-header 2>/dev/null | \
    awk -v name="$APP_NAME" '$2 == name {print $1; exit}')

if [[ -z "$app_id" ]]; then
    error "No app named '$APP_NAME' found."
    exit 1
fi

info "Streaming $LOG_TYPE logs for '$COMPONENT' (Ctrl+C to stop)..."
doctl apps logs "$app_id" "$COMPONENT" --type "$LOG_TYPE" --follow

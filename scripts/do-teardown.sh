#!/usr/bin/env bash
set -euo pipefail

# Tear down the agnolotti DigitalOcean App Platform app.
# This deletes the app AND its managed database.
#
# Usage:
#   ./scripts/do-teardown.sh            # interactive confirmation
#   ./scripts/do-teardown.sh --force    # skip confirmation

APP_NAME="agnolotti"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

if ! command -v doctl &>/dev/null; then
    error "doctl CLI not found."
    exit 1
fi

app_id=$(doctl apps list --format ID,Spec.Name --no-header 2>/dev/null | \
    awk -v name="$APP_NAME" '$2 == name {print $1; exit}')

if [[ -z "$app_id" ]]; then
    warn "No app named '$APP_NAME' found."
    exit 0
fi

info "Found app '$APP_NAME' (ID: $app_id)"

if [[ "${1:-}" != "--force" ]]; then
    warn "This will permanently delete the app and its managed database."
    read -rp "Type the app name to confirm: " confirm
    if [[ "$confirm" != "$APP_NAME" ]]; then
        info "Aborted."
        exit 0
    fi
fi

info "Deleting app..."
doctl apps delete "$app_id" --force
info "App '$APP_NAME' deleted."

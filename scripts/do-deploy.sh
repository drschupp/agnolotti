#!/usr/bin/env bash
set -euo pipefail

# Deploy agnolotti to DigitalOcean App Platform.
# Prerequisites: doctl CLI installed and authenticated (`doctl auth init`).
#
# Usage:
#   ./scripts/do-deploy.sh              # deploy and wait for completion
#   ./scripts/do-deploy.sh --no-wait    # deploy without waiting

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_SPEC="$PROJECT_DIR/.do/app.yaml"
APP_NAME="agnolotti"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

check_prerequisites() {
    if ! command -v doctl &>/dev/null; then
        error "doctl CLI not found. Install: https://docs.digitalocean.com/reference/doctl/how-to/install/"
        exit 1
    fi
    if ! doctl account get &>/dev/null; then
        error "doctl not authenticated. Run: doctl auth init"
        exit 1
    fi
    if [[ ! -f "$APP_SPEC" ]]; then
        error "App spec not found: $APP_SPEC"
        exit 1
    fi
}

get_app_id() {
    doctl apps list --format ID,Spec.Name --no-header 2>/dev/null | \
        awk -v name="$APP_NAME" '$2 == name {print $1; exit}'
}

validate_spec() {
    info "Validating app spec..."
    if ! doctl apps spec validate "$APP_SPEC" &>/dev/null; then
        error "App spec validation failed:"
        doctl apps spec validate "$APP_SPEC"
        exit 1
    fi
    info "App spec is valid."
}

deploy() {
    local app_id
    app_id=$(get_app_id)

    if [[ -z "$app_id" ]]; then
        info "Creating new app '$APP_NAME'..."
        app_id=$(doctl apps create --spec "$APP_SPEC" --format ID --no-header)
        info "App created with ID: $app_id"
        echo
        warn "Remember to set the OPENAI_API_KEY secret:"
        warn "  1. Visit https://cloud.digitalocean.com/apps/$app_id/settings"
        warn "  2. Or redeploy after setting it in the DO console."
    else
        info "Updating existing app '$APP_NAME' (ID: $app_id)..."
        doctl apps update "$app_id" --spec "$APP_SPEC" --format ID --no-header >/dev/null
        info "App updated."
    fi

    echo "$app_id"
}

wait_for_deployment() {
    local app_id="$1"
    local timeout="${2:-600}"
    local elapsed=0
    local interval=15

    info "Waiting for deployment to complete (timeout: ${timeout}s)..."
    while [[ $elapsed -lt $timeout ]]; do
        local phase
        phase=$(doctl apps get "$app_id" --format ActiveDeployment.Phase --no-header 2>/dev/null | tr -d '[:space:]')

        case "$phase" in
            ACTIVE)
                echo
                info "Deployment successful!"
                return 0
                ;;
            ERROR|CANCELED|UNKNOWN)
                echo
                error "Deployment failed (phase: $phase)"
                error "View logs: ./scripts/do-logs.sh api"
                return 1
                ;;
            *)
                printf "."
                sleep "$interval"
                elapsed=$((elapsed + interval))
                ;;
        esac
    done

    echo
    warn "Timeout after ${timeout}s. Check status: doctl apps get $app_id"
    return 1
}

print_app_info() {
    local app_id="$1"
    echo
    info "App details:"
    doctl apps get "$app_id" --format ID,DefaultIngress,ActiveDeployment.Phase,Updated
    echo
    local url
    url=$(doctl apps get "$app_id" --format DefaultIngress --no-header 2>/dev/null | tr -d '[:space:]')
    if [[ -n "$url" ]]; then
        info "Dashboard: https://$url"
        info "API:       https://$url/api"
        info "API docs:  https://$url/api/docs"
    fi
}

main() {
    info "Deploying $APP_NAME to DigitalOcean App Platform"
    echo

    check_prerequisites
    validate_spec

    local app_id
    app_id=$(deploy)

    if [[ "${1:-}" != "--no-wait" ]]; then
        wait_for_deployment "$app_id"
    fi

    print_app_info "$app_id"
}

main "$@"

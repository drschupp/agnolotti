#Requires -Version 7.0
<#
.SYNOPSIS
    Deploy agnolotti to DigitalOcean App Platform.
.DESCRIPTION
    Creates or updates the DO app using doctl. Validates the spec and
    optionally waits for deployment to complete.
.PARAMETER NoWait
    Skip waiting for deployment to finish.
.EXAMPLE
    .\scripts\do-deploy.ps1
    .\scripts\do-deploy.ps1 -NoWait
#>
param(
    [switch]$NoWait
)

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $ProjectDir) { $ProjectDir = Split-Path -Parent $PSScriptRoot }
$AppSpec = Join-Path $PSScriptRoot ".." ".do" "app.yaml" | Resolve-Path -ErrorAction SilentlyContinue
if (-not $AppSpec) {
    $AppSpec = Join-Path (Split-Path -Parent $PSScriptRoot) ".do" "app.yaml"
}
$AppName = "agnolotti"

function Write-Info  { param($Msg) Write-Host "[INFO] $Msg" -ForegroundColor Green }
function Write-Warn  { param($Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Write-Err   { param($Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }

function Test-Prerequisites {
    if (-not (Get-Command doctl -ErrorAction SilentlyContinue)) {
        Write-Err "doctl CLI not found. Install: https://docs.digitalocean.com/reference/doctl/how-to/install/"
        exit 1
    }
    $null = doctl account get 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "doctl not authenticated. Run: doctl auth init"
        exit 1
    }
    if (-not (Test-Path $AppSpec)) {
        Write-Err "App spec not found: $AppSpec"
        exit 1
    }
}

function Get-AppId {
    $lines = doctl apps list --format ID,Spec.Name --no-header 2>$null
    foreach ($line in $lines) {
        $parts = $line -split '\s+'
        if ($parts.Count -ge 2 -and $parts[1] -eq $AppName) {
            return $parts[0]
        }
    }
    return $null
}

function Test-Spec {
    Write-Info "Validating app spec..."
    $null = doctl apps spec validate $AppSpec 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "App spec validation failed:"
        doctl apps spec validate $AppSpec
        exit 1
    }
    Write-Info "App spec is valid."
}

function Invoke-Deploy {
    $appId = Get-AppId

    if (-not $appId) {
        Write-Info "Creating new app '$AppName'..."
        $appId = (doctl apps create --spec $AppSpec --format ID --no-header).Trim()
        Write-Info "App created with ID: $appId"
        Write-Host ""
        Write-Warn "Remember to set the OPENAI_API_KEY secret:"
        Write-Warn "  1. Visit https://cloud.digitalocean.com/apps/$appId/settings"
        Write-Warn "  2. Or redeploy after setting it in the DO console."
    }
    else {
        Write-Info "Updating existing app '$AppName' (ID: $appId)..."
        $null = doctl apps update $appId --spec $AppSpec --format ID --no-header
        Write-Info "App updated."
    }

    return $appId
}

function Wait-ForDeployment {
    param(
        [string]$AppId,
        [int]$Timeout = 600
    )

    Write-Info "Waiting for deployment to complete (timeout: ${Timeout}s)..."
    $elapsed = 0
    $interval = 15

    while ($elapsed -lt $Timeout) {
        $phase = (doctl apps get $AppId --format ActiveDeployment.Phase --no-header 2>$null).Trim()

        switch ($phase) {
            "ACTIVE" {
                Write-Host ""
                Write-Info "Deployment successful!"
                return $true
            }
            { $_ -in "ERROR", "CANCELED", "UNKNOWN" } {
                Write-Host ""
                Write-Err "Deployment failed (phase: $phase)"
                Write-Err "View logs: .\scripts\do-logs.ps1 -Component api"
                return $false
            }
            default {
                Write-Host "." -NoNewline
                Start-Sleep -Seconds $interval
                $elapsed += $interval
            }
        }
    }

    Write-Host ""
    Write-Warn "Timeout after ${Timeout}s. Check status: doctl apps get $AppId"
    return $false
}

function Write-AppInfo {
    param([string]$AppId)

    Write-Host ""
    Write-Info "App details:"
    doctl apps get $AppId --format ID,DefaultIngress,ActiveDeployment.Phase,Updated
    Write-Host ""

    $url = (doctl apps get $AppId --format DefaultIngress --no-header 2>$null).Trim()
    if ($url) {
        Write-Info "Dashboard: https://$url"
        Write-Info "API:       https://$url/api"
        Write-Info "API docs:  https://$url/api/docs"
    }
}

# Main
Write-Info "Deploying $AppName to DigitalOcean App Platform"
Write-Host ""

Test-Prerequisites
Test-Spec

$appId = Invoke-Deploy

if (-not $NoWait) {
    $success = Wait-ForDeployment -AppId $appId
    if (-not $success) { exit 1 }
}

Write-AppInfo -AppId $appId

#Requires -Version 7.0
<#
.SYNOPSIS
    Tear down the agnolotti DigitalOcean App Platform app.
.DESCRIPTION
    Deletes the app and its managed database. Prompts for confirmation
    unless -Force is specified.
.PARAMETER Force
    Skip the confirmation prompt.
.EXAMPLE
    .\scripts\do-teardown.ps1
    .\scripts\do-teardown.ps1 -Force
#>
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$AppName = "agnolotti"

function Write-Info { param($Msg) Write-Host "[INFO] $Msg" -ForegroundColor Green }
function Write-Warn { param($Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Write-Err  { param($Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }

if (-not (Get-Command doctl -ErrorAction SilentlyContinue)) {
    Write-Err "doctl CLI not found."
    exit 1
}

$appId = $null
$lines = doctl apps list --format ID,Spec.Name --no-header 2>$null
foreach ($line in $lines) {
    $parts = $line -split '\s+'
    if ($parts.Count -ge 2 -and $parts[1] -eq $AppName) {
        $appId = $parts[0]
        break
    }
}

if (-not $appId) {
    Write-Warn "No app named '$AppName' found."
    exit 0
}

Write-Info "Found app '$AppName' (ID: $appId)"

if (-not $Force) {
    Write-Warn "This will permanently delete the app and its managed database."
    $confirm = Read-Host "Type the app name to confirm"
    if ($confirm -ne $AppName) {
        Write-Info "Aborted."
        exit 0
    }
}

Write-Info "Deleting app..."
doctl apps delete $appId --force
Write-Info "App '$AppName' deleted."

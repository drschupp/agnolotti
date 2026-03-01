#Requires -Version 7.0
<#
.SYNOPSIS
    Stream logs for an agnolotti component on DigitalOcean App Platform.
.PARAMETER Component
    The component to stream logs for. Default: api.
.PARAMETER LogType
    The log type: run or build. Default: run.
.EXAMPLE
    .\scripts\do-logs.ps1
    .\scripts\do-logs.ps1 -Component dashboard
    .\scripts\do-logs.ps1 -Component api -LogType build
#>
param(
    [string]$Component = "api",
    [ValidateSet("run", "build")]
    [string]$LogType = "run"
)

$ErrorActionPreference = "Stop"
$AppName = "agnolotti"

function Write-Info { param($Msg) Write-Host "[INFO] $Msg" -ForegroundColor Green }
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
    Write-Err "No app named '$AppName' found."
    exit 1
}

Write-Info "Streaming $LogType logs for '$Component' (Ctrl+C to stop)..."
doctl apps logs $appId $Component --type $LogType --follow

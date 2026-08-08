<#
.SYNOPSIS
    Main Rosace polling daemon. Runs indefinitely until stopped with Ctrl+C.
.DESCRIPTION
    Each cycle:
      1. Scans inbox for new VDM SR assignment emails
      2. Syncs sent items (moves SR emails, detects LQR auto-close)
    Interval configured via pollIntervalMinutes in config.json.
.EXAMPLE
    .\src\Start-Rosace.ps1
#>
[CmdletBinding()]
param()

. "$PSScriptRoot\Rosace.Common.ps1"
. "$PSScriptRoot\Get-RosaceState.ps1"
. "$PSScriptRoot\Initialize-RosaceFolders.ps1"

# Ensure connected
$ctx = Get-MgContext -ErrorAction SilentlyContinue
if (-not $ctx) {
    Write-Host "Not connected. Connecting..." -ForegroundColor Cyan
    & "$PSScriptRoot\Connect-Rosace.ps1"
}

# Bootstrap folder structure
Initialize-RosaceFolders | Out-Null

$cfg = Get-RosaceConfig
$interval = $cfg.pollIntervalMinutes * 60  # seconds

Write-Host ""
Write-Host "  ✦ Rosace is running  ✦" -ForegroundColor Magenta
Write-Host "  Poll interval : $($cfg.pollIntervalMinutes) min" -ForegroundColor Gray
Write-Host "  Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host ""

$cycle = 0
while ($true) {
    $cycle++
    $cycleStart = Get-Date
    Write-RosaceLog INFO "── Cycle $cycle started ──"

    # Step 1: VDM inbox scan
    try {
        & "$PSScriptRoot\Invoke-RosaceVDMScan.ps1"
    }
    catch {
        Write-RosaceLog ERROR "VDM scan failed: $_"
    }

    # Step 2: Sent items sync
    try {
        & "$PSScriptRoot\Sync-RosaceSentItems.ps1"
    }
    catch {
        Write-RosaceLog ERROR "Sent sync failed: $_"
    }

    $elapsed = ((Get-Date) - $cycleStart).TotalSeconds
    Write-RosaceLog INFO "── Cycle $cycle done in $([math]::Round($elapsed,1))s ──"

    # Wait for next cycle (interruptible)
    $remaining = [math]::Max(0, $interval - $elapsed)
    Write-Host "  Next cycle in $([math]::Round($remaining/60,1)) min  ($((Get-Date).AddSeconds($remaining).ToString('HH:mm')))" -ForegroundColor DarkGray

    Start-Sleep -Seconds $remaining
}

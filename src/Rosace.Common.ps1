<#
.SYNOPSIS
    Shared utilities for Rosace: config loader, logger, paths.
    Dot-source this at the top of every Rosace script:
        . "$PSScriptRoot\Rosace.Common.ps1"
#>

#region ── Paths ──────────────────────────────────────────────────────────────

function Get-RosaceHomePath {
    $path = Join-Path $HOME '.rosace'
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
    return $path
}

function Get-RosaceStatePath  { Join-Path (Get-RosaceHomePath) 'state.json' }
function Get-RosaceLogPath    { Join-Path (Get-RosaceHomePath) 'rosace.log' }

function Get-RosaceConfigPath {
    # Config lives next to the src\ folder
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $path = Join-Path $repoRoot 'config\config.json'
    if (-not (Test-Path $path)) {
        throw "Config file not found at '$path'. Copy config\config.example.json to config\config.json and edit it."
    }
    return $path
}

#endregion

#region ── Config ─────────────────────────────────────────────────────────────

$script:_RosaceConfig = $null

function Get-RosaceConfig {
    if ($script:_RosaceConfig) { return $script:_RosaceConfig }

    $configPath = Get-RosaceConfigPath
    $raw = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $defaults = @{
        pollIntervalMinutes = 5
        caseFolderRoot      = 'Cases'
        activeFolderName    = 'Active'
        closedFolderName    = 'Closed'
        archiveFolderName   = 'Archive'
        lqrKeyPhrase        = 'Your feedback is important to us. After this interaction, you will receive a separate closure email with an opportunity to share your experience.'
        vdmSenderAddress    = 'sbamanager@microsoft.com'
    }

    # Merge defaults with user config (user wins)
    foreach ($key in $defaults.Keys) {
        if ($null -eq $raw.$key) { $raw | Add-Member -NotePropertyName $key -NotePropertyValue $defaults[$key] -Force }
    }

    $script:_RosaceConfig = $raw
    return $script:_RosaceConfig
}

#endregion

#region ── Logging ────────────────────────────────────────────────────────────

function Write-RosaceLog {
    [CmdletBinding()]
    param(
        [ValidateSet('INFO','WARN','ERROR')] [string]$Level = 'INFO',
        [Parameter(Mandatory, Position = 1)] [string]$Message
    )

    $logPath = Get-RosaceLogPath
    $line    = "[{0:u}] [{1,-5}] {2}" -f (Get-Date), $Level, $Message

    # Console output
    $color = switch ($Level) {
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red' }
        default { 'Gray' }
    }
    Write-Host $line -ForegroundColor $color

    # File output
    Add-Content -Path $logPath -Value $line -Encoding UTF8

    # Rotate: keep last 7 days
    Invoke-RosaceLogRotate
}

function Invoke-RosaceLogRotate {
    $logPath = Get-RosaceLogPath
    if (-not (Test-Path $logPath)) { return }

    $cutoff  = (Get-Date).AddDays(-7).ToString('u').Substring(0,10)
    $lines   = Get-Content $logPath -Encoding UTF8
    $kept    = $lines | Where-Object { $_ -match '^\[(\d{4}-\d{2}-\d{2})' -and $Matches[1] -ge $cutoff }
    if ($kept.Count -lt $lines.Count) {
        $kept | Set-Content $logPath -Encoding UTF8
    }
}

#endregion

#region ── Graph helpers ──────────────────────────────────────────────────────

function Assert-RosaceConnected {
    $ctx = Get-MgContext -ErrorAction SilentlyContinue
    if (-not $ctx) {
        throw "Not connected to Microsoft Graph. Run .\src\Connect-Rosace.ps1 first."
    }
}

#endregion

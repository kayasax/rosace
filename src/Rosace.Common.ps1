<#
.SYNOPSIS
    Shared config loader, logger, and path helpers for Rosace.
    No Microsoft.Graph module dependency.
    Dot-source at the top of every Rosace script:
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
    $path = Join-Path $HOME '.copilot\m-skills\rosace\config\config.json'
    if (-not (Test-Path $path)) {
        throw "Config not found. Re-run the Rosace install prompt in Scout."
    }
    return $path
}

#endregion

#region ── Config ─────────────────────────────────────────────────────────────

$script:_Config = $null
function Get-RosaceConfig {
    if ($script:_Config) { return $script:_Config }
    $raw = Get-Content (Get-RosaceConfigPath) -Raw | ConvertFrom-Json
    @{ pollIntervalMinutes=5; caseFolderRoot='Cases'; activeFolderName='Active';
       closedFolderName='Closed'; archiveFolderName='Archive';
       lqrKeyPhrase='Your feedback is important to us. After this interaction, you will receive a separate closure email with an opportunity to share your experience.';
       vdmSenderAddress='sbamanager@microsoft.com'
    }.GetEnumerator() | ForEach-Object {
        if ($null -eq $raw.$($_.Key)) { $raw | Add-Member -NotePropertyName $_.Key -NotePropertyValue $_.Value -Force }
    }
    $script:_Config = $raw
    return $script:_Config
}

#endregion

#region ── Logging ────────────────────────────────────────────────────────────

function Write-RosaceLog {
    param([ValidateSet('INFO','WARN','ERROR')][string]$Level='INFO', [Parameter(Mandatory,Position=1)][string]$Message)
    $line = "[{0:u}] [{1,-5}] {2}" -f (Get-Date), $Level, $Message
    $color = @{WARN='Yellow';ERROR='Red';INFO='Gray'}[$Level]
    Write-Host $line -ForegroundColor $color
    Add-Content (Get-RosaceLogPath) $line -Encoding UTF8
    # Rotate to 7 days
    $cutoff = (Get-Date).AddDays(-7).ToString('yyyy-MM-dd')
    $lines  = Get-Content (Get-RosaceLogPath) -Encoding UTF8
    $kept   = $lines | Where-Object { ($_ -match '^\[(\d{4}-\d{2}-\d{2})') -and ($Matches[1] -ge $cutoff) }
    if ($kept.Count -lt $lines.Count) { $kept | Set-Content (Get-RosaceLogPath) -Encoding UTF8 }
}

#endregion


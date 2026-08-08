<#
.SYNOPSIS
    Read/write operations for the Rosace state registry (~/.rosace/state.json).
    All other scripts use these functions — never write state.json directly.
.EXAMPLE
    . "$PSScriptRoot\Get-RosaceState.ps1"
    $state = Get-RosaceState
    Register-RosaceSR -SRId '2608070030002432' -FriendlyName 'Organizational messages' -FolderId 'AAMk...' -RuleId 'AQA...'
    Update-RosaceSRStatus -SRId '2608070030002432' -Status 'closed'
#>

. "$PSScriptRoot\Rosace.Common.ps1"

#region ── Default state ──────────────────────────────────────────────────────

function New-RosaceDefaultState {
    return @{
        version          = 1
        lastSentSyncTime = $null
        srs              = @{}
    }
}

#endregion

#region ── Read / Write ───────────────────────────────────────────────────────

function Get-RosaceState {
    $path = Get-RosaceStatePath

    if (-not (Test-Path $path)) {
        Write-RosaceLog INFO "State file not found — creating default at '$path'."
        $default = New-RosaceDefaultState
        Save-RosaceState $default
        return $default
    }

    try {
        $json = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
        # Ensure srs key exists
        if (-not $json.ContainsKey('srs')) { $json['srs'] = @{} }
        return $json
    }
    catch {
        Write-RosaceLog ERROR "State file corrupt: $_. Backing up and resetting."
        Copy-Item $path "$path.bak.$(Get-Date -Format 'yyyyMMddHHmmss')" -Force
        $default = New-RosaceDefaultState
        Save-RosaceState $default
        return $default
    }
}

function Save-RosaceState {
    [CmdletBinding()]
    param([hashtable]$State)

    $path    = Get-RosaceStatePath
    $tmpPath = "$path.tmp"

    try {
        $State | ConvertTo-Json -Depth 10 | Set-Content $tmpPath -Encoding UTF8
        Move-Item $tmpPath $path -Force   # atomic replace
    }
    catch {
        Write-RosaceLog ERROR "Failed to save state: $_"
        throw
    }
}

#endregion

#region ── SR operations ──────────────────────────────────────────────────────

function Register-RosaceSR {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$SRId,
        [Parameter(Mandatory)] [string]$FriendlyName,
        [Parameter(Mandatory)] [string]$FolderId,
        [Parameter(Mandatory)] [string]$ParentFolderId,
        [Parameter(Mandatory)] [string]$RuleId
    )

    $state = Get-RosaceState

    if ($state.srs.ContainsKey($SRId)) {
        Write-RosaceLog WARN "SR $SRId already registered — skipping."
        return
    }

    $state.srs[$SRId] = @{
        srId           = $SRId
        friendlyName   = $FriendlyName
        status         = 'active'
        folderId       = $FolderId
        parentFolderId = $ParentFolderId
        ruleId         = $RuleId
        openedAt       = (Get-Date -Format 'o')
        closedAt       = $null
        archivedAt     = $null
    }

    Save-RosaceState $state
    Write-RosaceLog INFO "Registered SR $SRId as '$FriendlyName'."
}

function Update-RosaceSRStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$SRId,
        [ValidateSet('active','closed','archived')] [string]$Status,
        [string]$FolderId       = $null,
        [string]$ParentFolderId = $null,
        [string]$RuleId         = $null
    )

    $state = Get-RosaceState

    if (-not $state.srs.ContainsKey($SRId)) {
        throw "SR $SRId not found in state registry."
    }

    $sr = $state.srs[$SRId]
    $sr['status'] = $Status

    if ($FolderId)       { $sr['folderId']       = $FolderId }
    if ($ParentFolderId) { $sr['parentFolderId']  = $ParentFolderId }

    switch ($Status) {
        'closed'   {
            $sr['ruleId']    = $null
            $sr['closedAt']  = (Get-Date -Format 'o')
        }
        'active'   {
            $sr['ruleId']    = $RuleId
            $sr['closedAt']  = $null
        }
        'archived' {
            $sr['archivedAt'] = (Get-Date -Format 'o')
        }
    }

    $state.srs[$SRId] = $sr
    Save-RosaceState $state
    Write-RosaceLog INFO "SR $SRId status → $Status."
}

function Get-RosaceSR {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$SRId
    )

    $state = Get-RosaceState
    if (-not $state.srs.ContainsKey($SRId)) {
        throw "SR $SRId not found in state registry."
    }
    return $state.srs[$SRId]
}

function Get-RosaceActiveSRIds {
    $state = Get-RosaceState
    return $state.srs.Keys | Where-Object { $state.srs[$_].status -eq 'active' }
}

function Update-RosaceLastSentSyncTime {
    [CmdletBinding()]
    param([string]$Timestamp = (Get-Date -Format 'o'))

    $state = Get-RosaceState
    $state['lastSentSyncTime'] = $Timestamp
    Save-RosaceState $state
}

#endregion

<#
.SYNOPSIS State registry — read/write ~/.rosace/state.json. No module dependency.
#>
. "$PSScriptRoot\Rosace.Common.ps1"

function Get-RosaceState {
    $path = Get-RosaceStatePath
    if (-not (Test-Path $path)) {
        $default = @{ version=1; lastSentSyncTime=$null; srs=@{}; folderIds=@{} }
        Save-RosaceState $default; return $default
    }
    try   { return Get-Content $path -Raw | ConvertFrom-Json -AsHashtable }
    catch {
        Write-RosaceLog ERROR "State corrupt — resetting. Backup at $path.bak"
        Copy-Item $path "$path.bak" -Force
        $default = @{ version=1; lastSentSyncTime=$null; srs=@{}; folderIds=@{} }
        Save-RosaceState $default; return $default
    }
}

function Save-RosaceState([hashtable]$State) {
    $tmp = "$(Get-RosaceStatePath).tmp"
    $State | ConvertTo-Json -Depth 10 | Set-Content $tmp -Encoding UTF8
    Move-Item $tmp (Get-RosaceStatePath) -Force
}

function Register-RosaceSR([string]$SRId, [string]$FriendlyName, [string]$FolderId, [string]$ParentFolderId, [string]$RuleId) {
    $state = Get-RosaceState
    if ($state.srs.ContainsKey($SRId)) { Write-RosaceLog WARN "SR $SRId already registered."; return }
    $state.srs[$SRId] = @{ srId=$SRId; friendlyName=$FriendlyName; status='active';
        folderId=$FolderId; parentFolderId=$ParentFolderId; ruleId=$RuleId;
        openedAt=(Get-Date -Format 'o'); closedAt=$null; archivedAt=$null }
    Save-RosaceState $state
    Write-RosaceLog INFO "Registered SR $SRId as '$FriendlyName'."
}

function Update-RosaceSRStatus([string]$SRId, [string]$Status, [string]$FolderId=$null, [string]$ParentFolderId=$null, [string]$RuleId=$null) {
    $state = Get-RosaceState
    if (-not $state.srs.ContainsKey($SRId)) { throw "SR $SRId not in state." }
    $sr = $state.srs[$SRId]
    $sr['status'] = $Status
    if ($FolderId)       { $sr['folderId']       = $FolderId }
    if ($ParentFolderId) { $sr['parentFolderId']  = $ParentFolderId }
    switch ($Status) {
        'closed'   { $sr['ruleId']=$null; $sr['closedAt']=(Get-Date -Format 'o') }
        'active'   { $sr['ruleId']=$RuleId; $sr['closedAt']=$null }
        'archived' { $sr['archivedAt']=(Get-Date -Format 'o') }
    }
    $state.srs[$SRId] = $sr
    Save-RosaceState $state
    Write-RosaceLog INFO "SR $SRId -> $Status."
}

function Get-RosaceSR([string]$SRId) {
    $state = Get-RosaceState
    if (-not $state.srs.ContainsKey($SRId)) { throw "SR $SRId not found." }
    return $state.srs[$SRId]
}

function Update-RosaceLastSentSyncTime([string]$Timestamp=(Get-Date -Format 'o')) {
    $state = Get-RosaceState; $state['lastSentSyncTime'] = $Timestamp; Save-RosaceState $state
}

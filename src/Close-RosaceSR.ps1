<#
.SYNOPSIS
    Closes an SR: moves folder Active→Closed, deletes the EXO inbox rule.
.PARAMETER SRId
    16-digit SR number.
.EXAMPLE
    .\src\Close-RosaceSR.ps1 -SRId "2608070030002432"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidatePattern('^\d{16}$')] [string]$SRId
)

. "$PSScriptRoot\Rosace.Common.ps1"
. "$PSScriptRoot\Get-RosaceState.ps1"
. "$PSScriptRoot\Initialize-RosaceFolders.ps1"

Assert-RosaceConnected

$sr = Get-RosaceSR -SRId $SRId
if ($sr.status -ne 'active') {
    Write-RosaceLog WARN "SR $SRId is not active (status: $($sr.status)). Skipping close."
    return
}

$folderIds = Get-RosaceFolderIds

#region ── Move folder Active → Closed ───────────────────────────────────────
try {
    $moved = Invoke-MgGraphRequest -Method POST `
             -Uri "https://graph.microsoft.com/v1.0/me/mailFolders/$($sr.folderId)/move" `
             -Body (@{ destinationId = $folderIds.closed } | ConvertTo-Json) `
             -ContentType 'application/json'
    Write-RosaceLog INFO "SR $SRId folder moved to Closed (new ID: $($moved.id))"
}
catch {
    Write-RosaceLog ERROR "Failed to move SR $SRId folder to Closed: $_"
    throw
}
#endregion

#region ── Delete EXO inbox rule ─────────────────────────────────────────────
if ($sr.ruleId) {
    try {
        Invoke-MgGraphRequest -Method DELETE `
            -Uri "https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messageRules/$($sr.ruleId)"
        Write-RosaceLog INFO "EXO rule Rosace-$SRId deleted."
    }
    catch {
        Write-RosaceLog WARN "Could not delete EXO rule $($sr.ruleId): $_"
    }
}
#endregion

Update-RosaceSRStatus -SRId $SRId -Status 'closed' -FolderId $moved.id -ParentFolderId $folderIds.closed
Write-Host "SR $SRId closed. Folder moved to Closed/, inbox rule removed." -ForegroundColor Yellow

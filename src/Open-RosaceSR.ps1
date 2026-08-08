<#
.SYNOPSIS
    Reopens a closed SR: moves folder Closed→Active, recreates the EXO inbox rule.
.PARAMETER SRId
    16-digit SR number.
.EXAMPLE
    .\src\Open-RosaceSR.ps1 -SRId "2608070030002432"
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
if ($sr.status -ne 'closed') {
    Write-RosaceLog WARN "SR $SRId is not closed (status: $($sr.status)). Skipping reopen."
    return
}

$folderIds = Get-RosaceFolderIds

#region ── Move folder Closed → Active ───────────────────────────────────────
try {
    $moved = Invoke-MgGraphRequest -Method POST `
             -Uri "https://graph.microsoft.com/v1.0/me/mailFolders/$($sr.folderId)/move" `
             -Body (@{ destinationId = $folderIds.active } | ConvertTo-Json) `
             -ContentType 'application/json'
    Write-RosaceLog INFO "SR $SRId folder moved back to Active (new ID: $($moved.id))"
}
catch {
    Write-RosaceLog ERROR "Failed to move SR $SRId folder to Active: $_"
    throw
}
#endregion

#region ── Recreate EXO inbox rule ───────────────────────────────────────────
$ruleBody = @{
    displayName = "Rosace-$SRId"
    sequence    = 100
    isEnabled   = $true
    conditions  = @{ subjectContains = @($SRId) }
    actions     = @{ moveToFolder = $moved.id; stopProcessingRules = $true }
}

try {
    $rule = Invoke-MgGraphRequest -Method POST `
            -Uri 'https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messageRules' `
            -Body ($ruleBody | ConvertTo-Json -Depth 5) `
            -ContentType 'application/json'
    Write-RosaceLog INFO "EXO rule recreated: Rosace-$SRId (ID: $($rule.id))"
}
catch {
    Write-RosaceLog ERROR "Failed to recreate EXO rule for SR $SRId: $_"
    throw
}
#endregion

Update-RosaceSRStatus -SRId $SRId -Status 'active' `
    -FolderId $moved.id -ParentFolderId $folderIds.active -RuleId $rule.id
Write-Host "SR $SRId reopened. Folder in Active/, inbox rule recreated." -ForegroundColor Green

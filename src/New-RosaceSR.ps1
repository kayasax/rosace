<#
.SYNOPSIS
    Creates an SR folder under Cases/Active/ and an EXO inbox rule for it.
.PARAMETER SRId
    16-digit SR number.
.PARAMETER FriendlyName
    Human-readable label appended to the folder name, e.g. "Organizational messages".
.EXAMPLE
    .\src\New-RosaceSR.ps1 -SRId "2608070030002432" -FriendlyName "Organizational messages"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidatePattern('^\d{16}$')] [string]$SRId,
    [Parameter(Mandatory)] [string]$FriendlyName
)

. "$PSScriptRoot\Rosace.Common.ps1"
. "$PSScriptRoot\Get-RosaceState.ps1"
. "$PSScriptRoot\Initialize-RosaceFolders.ps1"

Assert-RosaceConnected

# Idempotency: skip if already registered
$state = Get-RosaceState
if ($state.srs.ContainsKey($SRId)) {
    Write-RosaceLog WARN "SR $SRId already registered. Skipping."
    return
}

$folderIds   = Get-RosaceFolderIds
$folderName  = "$SRId $FriendlyName"

Write-RosaceLog INFO "Creating SR $SRId — '$FriendlyName'"

#region ── Create mailbox folder ──────────────────────────────────────────────
try {
    $folder = New-MgUserMailFolderChildFolder -UserId 'me' -MailFolderId $folderIds.active `
              -BodyParameter @{ displayName = $folderName }
    Write-RosaceLog INFO "Folder created: $folderName (ID: $($folder.Id))"
}
catch {
    Write-RosaceLog ERROR "Failed to create folder '$folderName': $_"
    throw
}
#endregion

#region ── Create EXO inbox rule ──────────────────────────────────────────────
$ruleBody = @{
    displayName = "Rosace-$SRId"
    sequence    = 100
    isEnabled   = $true
    conditions  = @{
        subjectContains = @($SRId)
    }
    actions     = @{
        moveToFolder     = $folder.Id
        stopProcessingRules = $true
    }
}

try {
    $rule = Invoke-MgGraphRequest -Method POST `
            -Uri 'https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messageRules' `
            -Body ($ruleBody | ConvertTo-Json -Depth 5) `
            -ContentType 'application/json'
    Write-RosaceLog INFO "EXO rule created: Rosace-$SRId (ID: $($rule.id))"
}
catch {
    Write-RosaceLog ERROR "Failed to create EXO rule for SR $SRId : $_"
    # Clean up the folder we just created to avoid orphans
    Remove-MgUserMailFolder -UserId 'me' -MailFolderId $folder.Id -ErrorAction SilentlyContinue
    throw
}
#endregion

#region ── Register in state ──────────────────────────────────────────────────
Register-RosaceSR -SRId          $SRId `
                  -FriendlyName  $FriendlyName `
                  -FolderId      $folder.Id `
                  -ParentFolderId $folderIds.active `
                  -RuleId        $rule.id
#endregion

Write-Host "SR $SRId registered — folder '$folderName' created and inbox rule active." -ForegroundColor Green

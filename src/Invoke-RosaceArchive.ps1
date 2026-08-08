<#
.SYNOPSIS
    Batch-archives all closed SRs: moves folders Closed→Archive.
.EXAMPLE
    .\src\Invoke-RosaceArchive.ps1
#>
[CmdletBinding()]
param()

. "$PSScriptRoot\Rosace.Common.ps1"
. "$PSScriptRoot\Get-RosaceState.ps1"
. "$PSScriptRoot\Initialize-RosaceFolders.ps1"

Assert-RosaceConnected

$state     = Get-RosaceState
$folderIds = Get-RosaceFolderIds

$closedSRs = $state.srs.Keys | Where-Object { $state.srs[$_].status -eq 'closed' }

if (-not $closedSRs) {
    Write-Host "No closed SRs to archive." -ForegroundColor Cyan
    return
}

$count = 0
foreach ($SRId in $closedSRs) {
    $sr = $state.srs[$SRId]
    try {
        $moved = Invoke-MgGraphRequest -Method POST `
                 -Uri "https://graph.microsoft.com/v1.0/me/mailFolders/$($sr.folderId)/move" `
                 -Body (@{ destinationId = $folderIds.archive } | ConvertTo-Json) `
                 -ContentType 'application/json'

        Update-RosaceSRStatus -SRId $SRId -Status 'archived' `
            -FolderId $moved.id -ParentFolderId $folderIds.archive

        Write-RosaceLog INFO "Archived SR $SRId."
        $count++
    }
    catch {
        Write-RosaceLog ERROR "Failed to archive SR $SRId : $_"
    }
}

Write-Host "Archived $count SR(s)." -ForegroundColor Green

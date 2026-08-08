<#
.SYNOPSIS
    Folder operations for Rosace via direct Graph API calls.
    No Microsoft.Graph module — uses Rosace.Auth.ps1 (pure Invoke-RestMethod).
    This is the ONLY script requiring token auth — all email/rule operations
    are handled by the Scout skill via workiq_* tools.
#>

. "$PSScriptRoot\Rosace.Auth.ps1"
. "$PSScriptRoot\Get-RosaceState.ps1"

function New-RosaceMailFolder {
    <#
    .SYNOPSIS Creates a subfolder under a parent folder ID.
    .OUTPUTS  Graph mailFolder object (with .id property)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][string]$ParentFolderId
    )

    # Idempotent: return existing folder if already present
    $existing = (Invoke-RosaceGraph -Path "/me/mailFolders/$ParentFolderId/childFolders").value |
                Where-Object { $_.displayName -eq $DisplayName } |
                Select-Object -First 1
    if ($existing) { return $existing }

    return Invoke-RosaceGraph -Method POST `
        -Path "/me/mailFolders/$ParentFolderId/childFolders" `
        -Body @{ displayName = $DisplayName }
}

function Move-RosaceMailFolder {
    <#
    .SYNOPSIS Moves a mail folder to a new parent.
    .OUTPUTS  The moved folder object (new ID from Graph)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FolderId,
        [Parameter(Mandatory)][string]$DestinationParentId
    )

    return Invoke-RosaceGraph -Method POST `
        -Path "/me/mailFolders/$FolderId/move" `
        -Body @{ destinationId = $DestinationParentId }
}

function Initialize-RosaceFolderStructure {
    <#
    .SYNOPSIS Ensures Cases/Active/Closed/Archive exist. Stores their IDs in state.
    #>
    [CmdletBinding()]
    param()

    $cfg   = Get-RosaceConfig
    $state = Get-RosaceState

    if ($state.ContainsKey('folderIds') -and $state.folderIds.root) {
        return $state.folderIds  # Already bootstrapped
    }

    Write-Host "Bootstrapping Rosace folder structure..." -ForegroundColor Cyan

    # Get or create root Cases/ folder
    $rootFolders = (Invoke-RosaceGraph -Path "/me/mailFolders").value
    $root = $rootFolders | Where-Object { $_.displayName -eq $cfg.caseFolderRoot } | Select-Object -First 1
    if (-not $root) {
        $root = Invoke-RosaceGraph -Method POST -Path "/me/mailFolders" -Body @{ displayName = $cfg.caseFolderRoot }
    }

    $active  = New-RosaceMailFolder -DisplayName $cfg.activeFolderName  -ParentFolderId $root.id
    $closed  = New-RosaceMailFolder -DisplayName $cfg.closedFolderName  -ParentFolderId $root.id
    $archive = New-RosaceMailFolder -DisplayName $cfg.archiveFolderName -ParentFolderId $root.id

    $folderIds = @{ root = $root.id; active = $active.id; closed = $closed.id; archive = $archive.id }
    $state['folderIds'] = $folderIds
    Save-RosaceState $state

    Write-Host "Folder structure ready." -ForegroundColor Green
    return $folderIds
}

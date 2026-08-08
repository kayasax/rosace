<#
.SYNOPSIS
    Ensures the Cases/Active/Closed/Archive folder structure exists in the mailbox.
    Stores folder IDs in state for fast lookup by other scripts.
    Called once at startup by Start-Rosace.ps1.
#>
[CmdletBinding()]
param()

. "$PSScriptRoot\Rosace.Common.ps1"
. "$PSScriptRoot\Get-RosaceState.ps1"

function Initialize-RosaceFolders {
    Assert-RosaceConnected
    $cfg = Get-RosaceConfig

    Write-RosaceLog INFO "Bootstrapping folder structure..."

    # Get or create a top-level folder by display name
    function Get-OrCreateFolder {
        param([string]$DisplayName, [string]$ParentId = $null)

        if ($ParentId) {
            $existing = Get-MgUserMailFolderChildFolder -UserId 'me' -MailFolderId $ParentId -All |
                        Where-Object { $_.DisplayName -eq $DisplayName } |
                        Select-Object -First 1
            if ($existing) { return $existing }

            $body = @{ displayName = $DisplayName }
            return New-MgUserMailFolderChildFolder -UserId 'me' -MailFolderId $ParentId -BodyParameter $body
        }
        else {
            $existing = Get-MgUserMailFolder -All |
                        Where-Object { $_.DisplayName -eq $DisplayName } |
                        Select-Object -First 1
            if ($existing) { return $existing }

            $body = @{ displayName = $DisplayName }
            return New-MgUserMailFolder -UserId 'me' -BodyParameter $body
        }
    }

    $root   = Get-OrCreateFolder -DisplayName $cfg.caseFolderRoot
    $active = Get-OrCreateFolder -DisplayName $cfg.activeFolderName  -ParentId $root.Id
    $closed = Get-OrCreateFolder -DisplayName $cfg.closedFolderName  -ParentId $root.Id
    $archive= Get-OrCreateFolder -DisplayName $cfg.archiveFolderName -ParentId $root.Id

    # Persist folder IDs in state for fast lookup
    $state = Get-RosaceState
    $state['folderIds'] = @{
        root    = $root.Id
        active  = $active.Id
        closed  = $closed.Id
        archive = $archive.Id
    }
    Save-RosaceState $state

    Write-RosaceLog INFO "Folder structure OK: $($cfg.caseFolderRoot)/$($cfg.activeFolderName|$cfg.closedFolderName|$cfg.archiveFolderName)"
    return $state.folderIds
}

function Get-RosaceFolderIds {
    $state = Get-RosaceState
    if (-not $state.ContainsKey('folderIds')) {
        return Initialize-RosaceFolders
    }
    return $state.folderIds
}

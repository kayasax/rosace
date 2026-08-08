<#
.SYNOPSIS
    Scans Sent Items for SR-related emails and moves them to the correct SR folder.
    Also detects LQR key phrase to trigger auto-close.
.DESCRIPTION
    Called by the polling daemon. Uses lastSentSyncTime as an incremental cursor.
#>
[CmdletBinding()]
param()

. "$PSScriptRoot\Rosace.Common.ps1"
. "$PSScriptRoot\Get-RosaceState.ps1"

Assert-RosaceConnected

$cfg   = Get-RosaceConfig
$state = Get-RosaceState

# Build SR lookup: srId → folderId (active only — closed/archived get no more routing)
$activeSRs = @{}
foreach ($id in $state.srs.Keys) {
    if ($state.srs[$id].status -eq 'active') {
        $activeSRs[$id] = $state.srs[$id].folderId
    }
}

if ($activeSRs.Count -eq 0) {
    Write-RosaceLog INFO "Sent sync: no active SRs to scan."
    return
}

# Build $filter for Graph: receivedDateTime ge lastSentSyncTime
$since = if ($state.lastSentSyncTime) { $state.lastSentSyncTime } else { (Get-Date).AddDays(-30).ToString('o') }
$syncStart = Get-Date -Format 'o'

Write-RosaceLog INFO "Sent sync: scanning since $since for $($activeSRs.Count) active SR(s)."

$srPattern = ($activeSRs.Keys | ForEach-Object { [regex]::Escape($_) }) -join '|'
$srRegex   = [regex]"($srPattern)"

$filter = "sentDateTime ge $since"
$uri    = "https://graph.microsoft.com/v1.0/me/mailFolders/sentItems/messages?`$filter=$([uri]::EscapeDataString($filter))&`$select=id,subject,bodyPreview,body&`$top=50"

$moved = 0
$lqrClosed = @()

do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($msg in $page.value) {
        $subject = $msg.subject ?? ''
        $body    = $msg.body.content ?? $msg.bodyPreview ?? ''

        # Find matching SR ID in subject
        $match = $srRegex.Match($subject)
        if (-not $match.Success) { continue }

        $srId    = $match.Value
        $folderId = $activeSRs[$srId]

        # Move to SR folder
        try {
            Invoke-MgGraphRequest -Method POST `
                -Uri "https://graph.microsoft.com/v1.0/me/messages/$($msg.id)/move" `
                -Body (@{ destinationId = $folderId } | ConvertTo-Json) `
                -ContentType 'application/json' | Out-Null
            $moved++
            Write-RosaceLog INFO "Moved sent email to SR $srId : '$subject'"
        }
        catch {
            Write-RosaceLog WARN "Could not move sent email $($msg.id): $_"
        }

        # LQR auto-close detection
        if ($body -like "*$($cfg.lqrKeyPhrase)*" -and $srId -notin $lqrClosed) {
            Write-RosaceLog INFO "LQR phrase detected in sent email for SR $srId — auto-closing."
            $lqrClosed += $srId
        }
    }

    $uri = $page.'@odata.nextLink'
} while ($uri)

# Auto-close SRs where LQR phrase was detected
foreach ($srId in $lqrClosed) {
    try {
        & "$PSScriptRoot\Close-RosaceSR.ps1" -SRId $srId
    }
    catch {
        Write-RosaceLog ERROR "Auto-close failed for SR $srId : $_"
    }
}

Update-RosaceLastSentSyncTime -Timestamp $syncStart
Write-RosaceLog INFO "Sent sync complete: $moved email(s) moved, $($lqrClosed.Count) SR(s) auto-closed."

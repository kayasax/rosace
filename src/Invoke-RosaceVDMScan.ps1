<#
.SYNOPSIS
    Polls the inbox for VDM SR assignment emails and auto-registers new SRs.
.DESCRIPTION
    Detects emails from sbamanager matching "VDM has assigned SR {SR_ID} to {alias}",
    parses the friendly name from the Support Topic field, and calls New-RosaceSR.ps1.
    Called by the polling daemon.
#>
[CmdletBinding()]
param()

. "$PSScriptRoot\Rosace.Common.ps1"
. "$PSScriptRoot\Get-RosaceState.ps1"

Assert-RosaceConnected

$cfg   = Get-RosaceConfig
$state = Get-RosaceState

$srRegex           = [regex]'\b(\d{16})\b'
$supportTopicRegex = [regex]'Support Topic[:\s]*(.+)'

# Filter: unread messages from VDM sender
$sender = $cfg.vdmSenderAddress
$filter = "from/emailAddress/address eq '$sender' and isRead eq false"
$uri    = "https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messages?`$filter=$([uri]::EscapeDataString($filter))&`$select=id,subject,body&`$top=50"

$registered = 0

do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($msg in $page.value) {
        $subject = $msg.subject ?? ''
        $body    = $msg.body.content ?? ''

        # Extract SR ID from subject
        $srMatch = $srRegex.Match($subject)
        if (-not $srMatch.Success) { continue }
        $srId = $srMatch.Groups[1].Value

        # Skip if already registered
        if ($state.srs.ContainsKey($srId)) {
            # Mark as read so we don't re-process it
            Invoke-MgGraphRequest -Method PATCH `
                -Uri "https://graph.microsoft.com/v1.0/me/messages/$($msg.id)" `
                -Body '{"isRead":true}' -ContentType 'application/json' | Out-Null
            continue
        }

        # Parse friendly name from Support Topic (last backslash-delimited segment)
        $friendlyName = "SR $srId"   # fallback
        $topicMatch = $supportTopicRegex.Match($body -replace '<[^>]+>','')  # strip HTML tags
        if ($topicMatch.Success) {
            $topic = $topicMatch.Groups[1].Value.Trim()
            $segments = $topic -split '\\'
            $lastSegment = ($segments | Select-Object -Last 1).Trim()
            if ($lastSegment) { $friendlyName = $lastSegment }
        }

        Write-RosaceLog INFO "VDM email detected: SR $srId — '$friendlyName'"

        try {
            # Create folder + rule + register in state
            & "$PSScriptRoot\New-RosaceSR.ps1" -SRId $srId -FriendlyName $friendlyName

            # Move the assignment email itself into the SR folder
            $newState = Get-RosaceState
            $folderId = $newState.srs[$srId].folderId
            Invoke-MgGraphRequest -Method POST `
                -Uri "https://graph.microsoft.com/v1.0/me/messages/$($msg.id)/move" `
                -Body (@{ destinationId = $folderId } | ConvertTo-Json) `
                -ContentType 'application/json' | Out-Null

            $registered++
        }
        catch {
            Write-RosaceLog ERROR "Failed to register SR $srId from VDM email: $_"
            # Mark as read anyway to avoid infinite retry on bad emails
            Invoke-MgGraphRequest -Method PATCH `
                -Uri "https://graph.microsoft.com/v1.0/me/messages/$($msg.id)" `
                -Body '{"isRead":true}' -ContentType 'application/json' | Out-Null
        }
    }

    $uri = $page.'@odata.nextLink'
} while ($uri)

if ($registered -gt 0) {
    Write-RosaceLog INFO "VDM scan: $registered new SR(s) registered."
}

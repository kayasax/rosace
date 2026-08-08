<#
.SYNOPSIS
    Authenticates to Microsoft Graph with the scopes required by Rosace.
.DESCRIPTION
    Uses the Microsoft.Graph PowerShell module (delegated auth).
    Token is cached automatically by the module — subsequent calls skip the browser prompt.
.EXAMPLE
    .\src\Connect-Rosace.ps1
#>
[CmdletBinding()]
param()

. "$PSScriptRoot\Rosace.Common.ps1"

$requiredScopes = @('Mail.ReadWrite', 'MailboxSettings.ReadWrite')

# Check if already connected with the right scopes
$ctx = Get-MgContext -ErrorAction SilentlyContinue
if ($ctx) {
    $missing = $requiredScopes | Where-Object { $_ -notin $ctx.Scopes }
    if (-not $missing) {
        Write-RosaceLog INFO "Already connected as $($ctx.Account) — scopes OK."
        return
    }
    Write-RosaceLog WARN "Connected but missing scopes: $($missing -join ', '). Reconnecting."
}

try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes $requiredScopes -NoWelcome -ErrorAction Stop

    $ctx = Get-MgContext
    Write-RosaceLog INFO "Connected as $($ctx.Account)"
    Write-Host "Connected as: $($ctx.Account)" -ForegroundColor Green
}
catch {
    Write-RosaceLog ERROR "Authentication failed: $_"
    throw
}

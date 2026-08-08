<#
.SYNOPSIS
    Module-free OAuth 2.0 device code authentication for Microsoft Graph.
    No external module required — pure Invoke-RestMethod.
    Run once: user authenticates interactively, refresh token cached locally.
.NOTES
    Uses the well-known Microsoft Graph PowerShell client ID (public client, no secret needed).
#>

$script:ClientId  = "14d82eec-204b-4c2f-b7e8-296a70dab67e"  # Graph PS public client
$script:TenantId  = "common"
$script:Scopes    = "Mail.ReadWrite MailboxSettings.ReadWrite offline_access"
$script:TokenPath = Join-Path $HOME ".rosace\tokens.json"

function Get-RosaceToken {
    # Try cached refresh token first
    if (Test-Path $script:TokenPath) {
        try {
            $cached = Get-Content $script:TokenPath -Raw | ConvertFrom-Json
            if ($cached.refresh_token) {
                $body = @{
                    grant_type    = "refresh_token"
                    client_id     = $script:ClientId
                    refresh_token = $cached.refresh_token
                    scope         = $script:Scopes
                }
                $response = Invoke-RestMethod -Method Post `
                    -Uri "https://login.microsoftonline.com/$($script:TenantId)/oauth2/v2.0/token" `
                    -Body $body -ErrorAction Stop
                Save-RosaceToken $response
                return $response.access_token
            }
        }
        catch { <# Refresh expired — fall through to device code #> }
    }

    # Device code flow — interactive, one-time
    $deviceResponse = Invoke-RestMethod -Method Post `
        -Uri "https://login.microsoftonline.com/$($script:TenantId)/oauth2/v2.0/devicecode" `
        -Body @{ client_id = $script:ClientId; scope = $script:Scopes }

    Write-Host ""
    Write-Host "  Open: $($deviceResponse.verification_uri)" -ForegroundColor Cyan
    Write-Host "  Code: $($deviceResponse.user_code)" -ForegroundColor Yellow
    Write-Host ""
    Start-Process $deviceResponse.verification_uri

    # Poll until user completes auth
    $deadline = (Get-Date).AddSeconds($deviceResponse.expires_in)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds $deviceResponse.interval
        try {
            $token = Invoke-RestMethod -Method Post `
                -Uri "https://login.microsoftonline.com/$($script:TenantId)/oauth2/v2.0/token" `
                -Body @{
                    grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
                    client_id   = $script:ClientId
                    device_code = $deviceResponse.device_code
                } -ErrorAction Stop
            Save-RosaceToken $token
            Write-Host "  Authenticated." -ForegroundColor Green
            return $token.access_token
        }
        catch {
            if ($_.Exception.Response.StatusCode -ne 400) { throw }
            # 400 = authorization_pending — keep polling
        }
    }
    throw "Authentication timed out."
}

function Save-RosaceToken([psobject]$token) {
    $dir = Split-Path $script:TokenPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $token | ConvertTo-Json | Set-Content $script:TokenPath -Encoding UTF8
}

function Invoke-RosaceGraph {
    [CmdletBinding()]
    param(
        [string]$Method = 'GET',
        [Parameter(Mandatory)][string]$Path,
        [hashtable]$Body = $null
    )

    $token   = Get-RosaceToken
    $headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
    $uri     = "https://graph.microsoft.com/v1.0$Path"

    $params  = @{ Method = $Method; Uri = $uri; Headers = $headers; ErrorAction = 'Stop' }
    if ($Body) { $params['Body'] = ($Body | ConvertTo-Json -Depth 10) }

    return Invoke-RestMethod @params
}

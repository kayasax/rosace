# Rosace

> *Like a compass rose, every email finds its place.*

Rosace is a PowerShell-based replacement for the OLHelper Outlook COM add-in. It automatically classifies SR-related emails into organized Outlook folders using Microsoft Graph and Exchange Online rules — no fat client, no COM, works with new Outlook and OWA.

## Features

- **Auto-detection** of new SR assignments from VDM emails
- **Automatic folder creation** under Cases/Active/{SR_ID} {friendly_name}/
- **EXO inbox rules** via Graph API — near-instant routing of incoming emails
- **Sent items sync** — periodic scan routes your outgoing SR emails
- **Lifecycle management** — Open / Close / Reopen / Archive per SR
- **Auto-close detection** via LQR key phrase in outbound emails

## Requirements

- PowerShell 7+
- Microsoft.Graph PowerShell module
- Microsoft 365 account (delegated auth)

## Quick Start

```powershell
# Install Graph module
Install-Module Microsoft.Graph -Scope CurrentUser

# Copy and edit config
Copy-Item config\config.example.json config\config.json

# Connect (once)
.\src\Connect-Rosace.ps1

# Start the background daemon
.\src\Start-Rosace.ps1
```

## Folder Structure

```
Cases/
  Active/
    {SR_ID} {friendly_name}/
  Closed/
    {SR_ID} {friendly_name}/
  Archive/
    {SR_ID} {friendly_name}/
```

## License

MIT

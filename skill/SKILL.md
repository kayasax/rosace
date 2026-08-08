---
name: rosace
description: >
  Manages SR email classification in Outlook via Microsoft Graph and Exchange Online rules.
  Use this skill whenever the user mentions SR email routing, Rosace, registering a new SR,
  closing/reopening/archiving an SR, checking SR email status, or starting the Rosace daemon.
  Also trigger on "classify my emails", "route SR emails", "where are my SR emails",
  "create SR folder", or any request related to organizing support case emails in Outlook.
  The skill maps natural language to PowerShell scripts in the Rosace repo at C:\dev\rosace\src\.
---

# Rosace Skill

Rosace is a PowerShell-based SR email classifier. It automatically routes SR-related emails
into organized Outlook folders using Microsoft Graph and Exchange Online inbox rules.

## Repo location
`C:\dev\rosace\src\` — all scripts are here and must be called with `pwsh`.

## Step 0 — Always check connection first

Before running any script other than Connect-Rosace.ps1, verify the user is connected:

```powershell
pwsh -NoProfile -Command "
  . 'C:\dev\rosace\src\Rosace.Common.ps1'
  `$ctx = Get-MgContext -ErrorAction SilentlyContinue
  if (-not `$ctx) { Write-Host 'NOT_CONNECTED' } else { Write-Host `$ctx.Account }
"
```

If not connected, run `Connect-Rosace.ps1` first (it opens a browser for delegated auth).

---

## Commands & Triggers

### Start the daemon
**Triggers:** "start rosace", "run rosace", "start email routing", "start classifying emails"

```powershell
pwsh -NoProfile -File "C:\dev\rosace\src\Start-Rosace.ps1"
```

The daemon polls every N minutes (default 5). Tell the user to leave the terminal open or
register it as a scheduled task (see Scheduled Task section below).

---

### Register a new SR manually
**Triggers:** "register SR {ID}", "create SR folder for {ID}", "add SR {ID} {name}"

Extract SR ID (16 digits) and friendly name from the user's message.
If friendly name is missing, ask for it before running.

```powershell
pwsh -NoProfile -File "C:\dev\rosace\src\New-RosaceSR.ps1" `
  -SRId "{SR_ID}" -FriendlyName "{friendly_name}"
```

---

### Close an SR
**Triggers:** "close SR {ID}", "mark SR {ID} as closed", "SR {ID} is done"

```powershell
pwsh -NoProfile -File "C:\dev\rosace\src\Close-RosaceSR.ps1" -SRId "{SR_ID}"
```

Effect: moves folder Active→Closed, deletes EXO inbox rule permanently.

---

### Reopen an SR
**Triggers:** "reopen SR {ID}", "SR {ID} is active again", "re-open {ID}"

```powershell
pwsh -NoProfile -File "C:\dev\rosace\src\Open-RosaceSR.ps1" -SRId "{SR_ID}"
```

---

### Archive all closed SRs
**Triggers:** "archive closed SRs", "archive", "clean up closed cases", "invoke archive"

```powershell
pwsh -NoProfile -File "C:\dev\rosace\src\Invoke-RosaceArchive.ps1"
```

---

### Check status / list tracked SRs
**Triggers:** "rosace status", "what SRs are tracked", "list my SRs", "show active SRs"

```powershell
pwsh -NoProfile -Command "
  . 'C:\dev\rosace\src\Rosace.Common.ps1'
  . 'C:\dev\rosace\src\Get-RosaceState.ps1'
  `$state = Get-RosaceState
  `$state.srs.Values | Sort-Object status, srId |
    Format-Table srId, friendlyName, status, openedAt -AutoSize
"
```

Present the results as a formatted table in your response.

---

### Register Rosace as a scheduled task (auto-start on login)
**Triggers:** "schedule rosace", "run rosace automatically", "auto-start rosace"

```powershell
$action  = New-ScheduledTaskAction -Execute 'pwsh.exe' `
             -Argument '-NoProfile -WindowStyle Hidden -File "C:\dev\rosace\src\Start-Rosace.ps1"'
$trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -TaskName 'Rosace' -Action $action -Trigger $trigger `
  -Description 'Rosace SR email classifier daemon' -RunLevel Limited -Force
```

---

## SR ID extraction

SR IDs are always **16 consecutive digits**. Regex: `\b\d{16}\b`

If the user mentions a partial number or a non-16-digit format, ask for clarification
before running any script.

---

## Error handling

If a script fails, show the user:
1. The error message
2. The last 20 lines of the log

```powershell
pwsh -NoProfile -Command "Get-Content (Join-Path $HOME '.rosace\rosace.log') -Tail 20"
```

Most common fixes:
- `NOT_CONNECTED` → run `Connect-Rosace.ps1`
- `config.json not found` → copy `config\config.example.json` to `config\config.json`
- Graph permission error → reconnect with `Connect-Rosace.ps1` (re-consents scopes)

---

## First-time setup (new engineer onboarding)

If the user is setting up Rosace for the first time:

1. Install the Graph module: `Install-Module Microsoft.Graph -Scope CurrentUser`
2. Copy config: `Copy-Item C:\dev\rosace\config\config.example.json C:\dev\rosace\config\config.json`
3. Edit `config.json` — set `lqrKeyPhrase` if different from default
4. Authenticate: `pwsh -File C:\dev\rosace\src\Connect-Rosace.ps1`
5. Start daemon: `pwsh -File C:\dev\rosace\src\Start-Rosace.ps1`
   or schedule it (see above)

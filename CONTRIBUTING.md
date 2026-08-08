# Contributing to Rosace

This document gives a coding agent or contributor everything needed to continue building Rosace from the current state.

---

## Quick Context

Rosace replaces the OLHelper Outlook COM add-in. It classifies SR-related emails into Outlook folders automatically, using Microsoft Graph API and Exchange Online inbox rules. No COM, no fat client — works with new Outlook and OWA.

**Read these first:**
1. [`docs/CAHIER_DES_CHARGES.md`](docs/CAHIER_DES_CHARGES.md) — full functional spec
2. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — technical decisions, API map, state schema
3. [`CHANGELOG.md`](CHANGELOG.md) — what's done and what's planned

---

## Current State

| Component | Status |
|-----------|--------|
| Project structure | ✅ Done |
| Documentation | ✅ Done |
| `Connect-Rosace.ps1` | 🔲 Stub only |
| `Get-RosaceState.ps1` | 🔲 Stub only |
| `New-RosaceSR.ps1` | 🔲 Stub only |
| `Close-RosaceSR.ps1` | 🔲 Stub only |
| `Open-RosaceSR.ps1` | 🔲 Stub only |
| `Invoke-RosaceArchive.ps1` | 🔲 Stub only |
| `Sync-RosaceSentItems.ps1` | 🔲 Stub only |
| `Start-Rosace.ps1` | 🔲 Stub only |

**Start with `Connect-Rosace.ps1` → `Get-RosaceState.ps1` → then the rest in order.**

---

## Build Order (Dependency Graph)

```
Connect-Rosace.ps1          ← start here (auth foundation)
     │
Get-RosaceState.ps1         ← state CRUD (all others need this)
     │
     ├── New-RosaceSR.ps1           ← creates folder + EXO rule
     │        │
     │   Close-RosaceSR.ps1        ← moves folder, deletes rule
     │   Open-RosaceSR.ps1         ← moves folder, recreates rule
     │   Invoke-RosaceArchive.ps1  ← batch close→archive
     │
Sync-RosaceSentItems.ps1    ← needs state (SR list + lastSyncTime)
     │
Start-Rosace.ps1            ← orchestrates everything above
```

---

## Coding Standards

- **PowerShell 7+** syntax only
- Use **approved verbs** (`Get-`, `New-`, `Remove-`, `Invoke-`, `Start-`, `Sync-`, `Connect-`)
- All functions must have `[CmdletBinding()]` and `param()` blocks
- Use `try/catch` everywhere Graph API is called
- Write errors to `~/.rosace/rosace.log` (structured, timestamped)
- Never hardcode credentials, tenant IDs, or email addresses — use `config.json`
- Config is loaded via a shared helper (to be created: `src\Get-RosaceConfig.ps1`)

---

## Graph API Notes

- Use **`Microsoft.Graph` PowerShell module** (not raw REST)
- Connect with: `Connect-MgGraph -Scopes "Mail.ReadWrite","MailboxSettings.ReadWrite"`
- All folder operations: `Microsoft.Graph.Mail` cmdlets
- Message move: `Move-MgUserMessage` or `Invoke-MgGraphRequest POST /me/messages/{id}/move`
- Inbox rules: `Invoke-MgGraphRequest` (no dedicated PS cmdlets for messageRules yet)

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full API endpoint reference.

---

## State File

Location: `~/.rosace/state.json`  
Managed exclusively by `Get-RosaceState.ps1` — never write to it directly from other scripts.

See schema in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md#state-file-schema).

---

## GitHub Workflow

1. Check open issues — pick one, assign yourself, move to In Progress
2. Create a branch: `feature/{issue-number}-{short-description}`
3. Implement, test manually against a real M365 mailbox
4. Update `CHANGELOG.md` under `[Unreleased]`
5. Open PR referencing the issue (`Closes #N`)

---

## Testing

No automated test framework yet. Manual testing approach:
1. Run against a real M365 test mailbox (delegated auth)
2. Verify folder creation in Outlook Web
3. Verify EXO rule appears in Outlook Settings → Rules
4. Send a test email with SR number in subject → verify routing

Future: Pester tests for pure logic (state parsing, regex, subject parsing).

---

## Environment Setup

```powershell
# 1. Install Graph module
Install-Module Microsoft.Graph -Scope CurrentUser

# 2. Copy config
Copy-Item config\config.example.json config\config.json
# Edit config\config.json as needed

# 3. Authenticate
.\src\Connect-Rosace.ps1

# 4. Run a component
.\src\New-RosaceSR.ps1 -SRId "2608070030002432" -FriendlyName "Test SR"
```

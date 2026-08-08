# Architecture — Rosace

## Overview

**Design principle: Scout-native. Zero module installation.**

```
┌─────────────────────────────────────────────────────────┐
│               Scout Automation (polling)                │
│          "every 5 min — VDM scan + sent sync"           │
│                                                         │
│   ┌────────────────────────────────────────────────┐   │
│   │         Scout skill (skill/SKILL.md)           │   │
│   │                                                │   │
│   │  workiq_list_emails  → VDM + sent scan         │   │
│   │  workiq_move_email   → route emails            │   │
│   │  workiq_*_rule       → EXO inbox rules CRUD    │   │
│   │  filesystem tools    → state.json              │   │
│   │  pwsh Rosace.Folders → folder create/move      │   │
│   │   (Invoke-RestMethod, device code, NO module)  │   │
│   └────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## Component Map

| Script | Role | Depends on |
|--------|------|------------|
| `Connect-Rosace.ps1` | Auth — connects to Graph, caches token | Microsoft.Graph module |
| `Get-RosaceState.ps1` | Read/write `~/.rosace/state.json` | — |
| `New-RosaceSR.ps1` | Create folder + EXO rule, register in state | `Get-RosaceState`, Graph |
| `Close-RosaceSR.ps1` | Move folder Active→Closed, delete rule, update state | `Get-RosaceState`, Graph |
| `Open-RosaceSR.ps1` | Move folder Closed→Active, recreate rule, update state | `Get-RosaceState`, Graph |
| `Invoke-RosaceArchive.ps1` | Batch move all Closed→Archive | `Get-RosaceState`, Graph |
| `Sync-RosaceSentItems.ps1` | Scan sent items, move matching emails, detect LQR | `Get-RosaceState`, Graph |
| `Start-Rosace.ps1` | Main polling loop — orchestrates all components | All of the above |

---

## Graph API Endpoints Used

### Mail Folders
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/me/mailFolders` | List root folders |
| `GET` | `/me/mailFolders/{id}/childFolders` | List subfolders |
| `POST` | `/me/mailFolders` | Create root folder |
| `POST` | `/me/mailFolders/{id}/childFolders` | Create subfolder |
| `PATCH` | `/me/mailFolders/{id}` | Rename folder |

### Messages
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/me/mailFolders/inbox/messages` | Poll inbox for VDM emails |
| `GET` | `/me/mailFolders/sentItems/messages` | Poll sent items |
| `POST` | `/me/messages/{id}/move` | Move message to folder |

### Inbox Rules
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/me/mailFolders/inbox/messageRules` | List rules |
| `POST` | `/me/mailFolders/inbox/messageRules` | Create rule |
| `DELETE` | `/me/mailFolders/inbox/messageRules/{id}` | Delete rule (on close/archive) |

---

## Key Design Decisions

### 1. Polling over Webhooks
Webhooks require a publicly accessible HTTPS endpoint. Polling via Graph API requires only delegated auth and works from any laptop. 5-minute delay is acceptable per requirements.

### 2. EXO Rules deleted on Close (not disabled)
Graph API's `messageRules` supports `isEnabled: false` but we delete on close/archive to keep the rule list clean. Rules are recreated on Reopen.

### 3. State in local JSON
The folder structure itself could theoretically be the state (derive SR list from `Cases/Active/` subfolder names), but a local JSON state file allows storing:
- EXO rule IDs (needed for deletion)
- Timestamps (needed for incremental sent sync)
- Status transitions
- Metadata without folder name parsing

### 4. VDM email as the authoritative SR source
All SR assignments come from `sbamanager@microsoft.com`. The friendly name is parsed from the `Support Topic:` field in the email body (last `\`-delimited segment).

### 5. Sent items handled separately
EXO inbox rules only apply to incoming mail. Sent items sync is a separate polling pass using the `lastSentSyncTime` cursor stored in state.

### 6. LQR auto-close detected in sent items sync
During each sent items poll, if an outbound email body contains the configured LQR key phrase AND its subject contains a known SR ID → trigger `Close-RosaceSR.ps1` for that SR automatically.

---

## PowerShell Module Requirements

```powershell
# Required
Install-Module Microsoft.Graph -Scope CurrentUser

# Key sub-modules used
Microsoft.Graph.Mail       # mailFolders, messages, messageRules
Microsoft.Graph.Users      # /me endpoint
```

Minimum version: `Microsoft.Graph 2.0.0`  
PowerShell: `7.0+`

---

## State File Schema

Path: `~/.rosace/state.json`

```jsonc
{
  "version": 1,
  "lastSentSyncTime": "2026-08-08T18:00:00Z",  // ISO 8601 UTC cursor for sent sync
  "srs": {
    "{SR_ID}": {
      "srId": "2608070030002432",
      "friendlyName": "Organizational messages",
      "status": "active",           // active | closed | archived
      "folderId": "AAMkAGI...",     // Graph folder ID for the SR subfolder
      "parentFolderId": "AAMkAGJ...", // Graph ID of Active/Closed/Archive parent
      "ruleId": "AQAAAA...",        // Graph inbox rule ID (null when closed/archived)
      "openedAt": "2026-08-07T09:06:00Z",
      "closedAt": null,
      "archivedAt": null
    }
  }
}
```

---

## Error Handling Conventions

- All scripts use `try/catch` and write structured errors to `~/.rosace/rosace.log`
- Non-fatal errors (e.g. single email move fails) are logged and skipped — daemon continues
- Fatal errors (auth failure, state corruption) stop the daemon and alert via `Write-Error`
- Log rotation: keep last 7 days of log entries

---

## Future Considerations (v2+)

- Graph change notifications (webhooks) for real-time inbox detection
- OWA/new Outlook add-in panel for manual SR operations
- Multi-engineer shared state (team inbox scenarios)
- ICM/Bug linking
- Scout skill wrapper (`/rosace` command)

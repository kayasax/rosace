# Cahier des Charges — Rosace

> Version 1.0 — 2026-08-08  
> Author: Loïc Michel  
> Status: **Approved**

---

## 1. Context & Problem

**OLHelper** is a COM-based Outlook add-in used by Microsoft support engineers to organize SR-related emails into dedicated folders. It works well but requires the Outlook fat client (Win32) and a COM registration — incompatible with new Outlook (web-based) and OWA.

**Rosace** replaces the email classification core of OLHelper using Microsoft Graph API and Exchange Online inbox rules. It is portable, distributable, requires no COM registration, and works with new Outlook, OWA, and any M365-authenticated engineer.

---

## 2. Target Users

Microsoft support engineers (Identity/Entra team and beyond) who:
- Receive SR assignments via VDM (Virtual Duty Manager)
- Manage active cases via Outlook
- Need fast, reliable email routing per SR without manual intervention

No dependency on Merlin, DFM, case-brain, or any internal tooling.  
Each engineer authenticates with their own M365 account (delegated auth).

---

## 3. Folder Structure

Replicated from OLHelper. Must match exactly:

```
Cases/
  Active/
    {SR_ID} {friendly_name}/     ← e.g. "2608070030002432 Organizational messages"
  Closed/
    {SR_ID} {friendly_name}/
  Archive/
    {SR_ID} {friendly_name}/
```

- `Cases/` is a top-level mail folder (sibling of Inbox)
- `Active/`, `Closed/`, `Archive/` are subfolders of `Cases/`
- Each SR has a subfolder named `{16-digit SR ID} {friendly name}`
- Folder names are configurable (see `config.example.json`)

---

## 4. SR Number Format

- Always **16 digits**, numeric only
- Example: `2608070030002432`
- Regex: `\b\d{16}\b`

---

## 5. Features

### F1 — Auto SR Detection (Primary)

**Trigger:** Incoming email from VDM (`sbamanager@microsoft.com`)  
**Subject pattern:** `VDM has assigned SR {SR_ID} to {alias}`  
**Action:**
1. Extract 16-digit SR ID from subject
2. Parse email body for `Support Topic:` field → extract last `\`-delimited segment as friendly name
3. Create folder `Cases/Active/{SR_ID} {friendly_name}/`
4. Create EXO inbox rule for this SR (see F2)
5. Register SR in state registry (see F5)
6. Move the assignment email itself into the new SR folder

**Example body parsing:**
```
Support Topic:: Microsoft 365\User and Domain Management\M365 Admin Portal\Organizational Messages
                                                                            ↑ this becomes the friendly name
```

**Fallback (F1b):** If VDM email is missing or malformed, user can manually register:
```powershell
.\src\New-RosaceSR.ps1 -SRId "2608070030002432" -FriendlyName "Organizational messages"
```

---

### F2 — EXO Inbox Rule per SR

**Created when:** SR is opened (F1 or F1b)  
**Deleted when:** SR is closed or archived (NOT disabled — fully deleted)

**Rule definition:**
- Name: `Rosace-{SR_ID}`
- Condition: subject contains `{SR_ID}` (16-digit string)
- Action: move message to `Cases/Active/{SR_ID} {name}/`
- Applied to: Inbox only (EXO rules are inbox-only by design)

**Graph API endpoint:** `POST /me/mailFolders/inbox/messageRules`

> ⚠️ EXO inbox rules only fire on **incoming** mail. Sent items are handled by F3.

---

### F3 — Sent Items Auto-sync

**Mechanism:** Periodic polling (every 5 minutes, configurable)  
**Logic:**
1. Fetch recent messages from `sentItems` folder (since last sync timestamp)
2. For each message, scan subject for any known SR ID (from state registry)
3. If match found → move message to corresponding SR folder
4. Update last sync timestamp in state

**Handles:** Replies to customers, forwarded emails, any outbound mail referencing an SR.

---

### F4 — SR Lifecycle

| Action | Trigger | Effect on folder | Effect on EXO rule |
|--------|---------|------------------|--------------------|
| **Open** | Auto (F1) or manual (F1b) | Create under `Active/` | Create rule |
| **Close** | LQR key phrase detected in sent email OR user command | Move `Active/` → `Closed/` | **Delete** rule |
| **Reopen** | User command | Move `Closed/` → `Active/` | Recreate rule (new destination) |
| **Archive** | User command (batch) | Move all `Closed/` → `Archive/` | Rules already deleted at close time |

**LQR key phrase (default, configurable per user):**
> `"Your feedback is important to us. After this interaction, you will receive a separate closure email with an opportunity to share your experience."`

Detection: during F3 sent items scan, if an outbound email body contains the LQR phrase AND its subject contains a known SR ID → trigger auto-close for that SR.

---

### F5 — State Registry

**Location:** `~/.rosace/state.json`  
**Managed by:** `Get-RosaceState.ps1`

**Schema:**
```json
{
  "version": 1,
  "lastSentSyncTime": "2026-08-08T18:00:00Z",
  "srs": {
    "2608070030002432": {
      "srId": "2608070030002432",
      "friendlyName": "Organizational messages",
      "status": "active",
      "folderId": "AAMkAGI...",
      "ruleId": "AQAAAA...",
      "openedAt": "2026-08-07T09:06:00Z",
      "closedAt": null
    }
  }
}
```

---

## 6. Polling Daemon

`Start-Rosace.ps1` runs a loop:

```
Every N minutes (default: 5):
  1. Poll Inbox for new VDM assignment emails (F1)
  2. Scan Sent Items since last sync (F3)
     → detect LQR phrase → auto-close (F4)
  3. Save state
```

Intended to run as a background job or scheduled task.  
For MVP: user starts it manually. Future: auto-start on login.

---

## 7. Authentication

- **Type:** Delegated OAuth (user authenticates interactively once)
- **Module:** `Microsoft.Graph` PowerShell module
- **Scopes required:**
  - `Mail.ReadWrite` — read/move/organize messages
  - `MailboxSettings.ReadWrite` — create/delete inbox rules
- **Token cache:** persisted locally by MSAL (via Graph module)
- **Command:** `Connect-MgGraph -Scopes "Mail.ReadWrite","MailboxSettings.ReadWrite"`

---

## 8. Configuration

File: `config/config.json` (gitignored, copy from `config.example.json`)

| Key | Default | Description |
|-----|---------|-------------|
| `pollIntervalMinutes` | `5` | Polling frequency |
| `caseFolderRoot` | `"Cases"` | Root mail folder name |
| `activeFolderName` | `"Active"` | Active subfolder name |
| `closedFolderName` | `"Closed"` | Closed subfolder name |
| `archiveFolderName` | `"Archive"` | Archive subfolder name |
| `lqrKeyPhrase` | *(see above)* | Phrase triggering auto-close |
| `vdmSenderAddress` | `"sbamanager@microsoft.com"` | VDM sender to watch |

---

## 9. Out of Scope (v1)

- ICM/Bug linking
- Email templates ("Send email template" button)
- Save attachments
- OWA/Outlook add-in panel UI
- DFM / case-brain integration
- Webhook-based real-time detection (use polling for MVP)
- Multi-mailbox support

---

## 10. Non-Functional Requirements

- Works with new Outlook (web-based), OWA, and Outlook Win32
- No COM registration
- No admin privileges required
- Distributable to any MS engineer with M365 access
- PowerShell 7+ required
- Microsoft.Graph module v2.0+

---
name: rosace
description: >
  SR email classifier for Microsoft support engineers. Organizes SR-related emails
  into Outlook folders automatically using Scout's built-in M365 tools — no module
  installation required. Use this skill whenever the user mentions SR email routing,
  Rosace, registering/closing/reopening/archiving an SR, checking SR status, setting
  up email classification, "classify my emails", "route SR emails", "create SR folder",
  "where are my SR emails", or anything about organizing support case emails in Outlook.
  Also trigger on first-time setup requests: "set up rosace", "install rosace", "configure rosace".
---

# Rosace Skill

Rosace is a Scout-native SR email classifier. It uses workiq_* tools (already in Scout)
for all email and rule operations. The ONLY external step is a one-time device code auth
for folder creation (pure PowerShell Invoke-RestMethod, no module).

## Folder structure
```
Cases/
  Active/    {SR_ID} {friendly_name}/
  Closed/    {SR_ID} {friendly_name}/
  Archive/   {SR_ID} {friendly_name}/
```

## State file: `~/.rosace/state.json`
Read/write this file using filesystem tools to track SR metadata and folder IDs.

---

## FIRST-TIME SETUP
**Triggers:** "set up rosace", "install rosace", "configure rosace"

1. Copy config: `Copy-Item C:\dev\rosace\config\config.example.json C:\dev\rosace\config\config.json`
2. Bootstrap folder structure (one-time device code auth — browser opens automatically):
   ```powershell
   pwsh -NoProfile -File "C:\dev\rosace\src\Rosace.Folders.ps1" -Command Initialize-RosaceFolderStructure
   ```
3. Create the polling automation (see AUTOMATION section below).

---

## SR REGISTRATION
**Triggers:** "register SR {ID}", "create SR folder for {ID}", "add SR {ID}", any new VDM detection

### Step 1 — Get folder IDs from state
Read `~/.rosace/state.json` → extract `folderIds.active`.

### Step 2 — Create the SR subfolder (PowerShell, no module)
```powershell
pwsh -NoProfile -Command "
  . 'C:\dev\rosace\src\Rosace.Common.ps1'
  . 'C:\dev\rosace\src\Rosace.Auth.ps1'
  . 'C:\dev\rosace\src\Rosace.Folders.ps1'
  \$folder = New-RosaceMailFolder -DisplayName '{SR_ID} {friendly_name}' -ParentFolderId '{active_folder_id}'
  Write-Output \$folder.id
"
```

### Step 3 — Create EXO inbox rule (workiq tool — no auth needed)
Call `workiq_create_message_rule` with:
- `displayName`: `"Rosace-{SR_ID}"`
- `sequence`: 100
- `conditions`: `{ "subjectContains": ["{SR_ID}"] }`
- `actions`: `{ "moveToFolder": "{new_folder_id}", "stopProcessingRules": true }`

### Step 4 — Save to state
Update `~/.rosace/state.json` with new SR entry (srId, friendlyName, status=active, folderId, ruleId).

---

## CLOSE SR
**Triggers:** "close SR {ID}", "SR {ID} is done", LQR phrase detected in sent email

### Step 1 — Read state → get folderId, ruleId, closedFolderId

### Step 2 — Delete EXO inbox rule (workiq tool)
Call `workiq_delete_message_rule` with the ruleId from state.

### Step 3 — Move folder Active → Closed (PowerShell)
```powershell
pwsh -NoProfile -Command "
  . 'C:\dev\rosace\src\Rosace.Common.ps1'
  . 'C:\dev\rosace\src\Rosace.Auth.ps1'
  . 'C:\dev\rosace\src\Rosace.Folders.ps1'
  Move-RosaceMailFolder -FolderId '{folderId}' -DestinationParentId '{closed_folder_id}'
"
```

### Step 4 — Update state: status=closed, ruleId=null, closedAt=now

---

## REOPEN SR
**Triggers:** "reopen SR {ID}", "SR {ID} is active again"

### Step 1 — Read state → get folderId, activeFolderId

### Step 2 — Move folder Closed → Active (PowerShell, same as above with activeFolderId)

### Step 3 — Recreate EXO inbox rule (workiq_create_message_rule, new folderId)

### Step 4 — Update state: status=active, ruleId=new rule id, closedAt=null

---

## ARCHIVE
**Triggers:** "archive closed SRs", "archive", "clean up closed cases"

For each SR with status=closed in state:
1. Move folder Closed → Archive (PowerShell: Move-RosaceMailFolder)
2. Update state: status=archived, archivedAt=now

---

## STATUS
**Triggers:** "rosace status", "what SRs are tracked", "list active SRs"

Read `~/.rosace/state.json` → display as table (srId, friendlyName, status, openedAt).

---

## VDM DETECTION (called by automation)
**Triggers:** polling automation, "scan for new SRs"

Use `workiq_list_emails` with:
- `folder`: "inbox"
- `from`: config.vdmSenderAddress (default: sbamanager@microsoft.com)
- `isRead`: false

For each matching email:
1. Extract 16-digit SR ID from subject with regex `\b\d{16}\b`
2. Skip if SR already in state
3. Get full email body with `workiq_get_email` → parse `Support Topic:` last segment → friendly name
4. Register the SR (steps above)
5. Mark email as read with `workiq_mark_email`
6. Move VDM email to new SR folder with `workiq_move_email`

---

## SENT ITEMS SYNC (called by automation)
**Triggers:** polling automation, "sync sent items"

1. Read `lastSentSyncTime` from state (default: 30 days ago)
2. Use `workiq_list_emails` with:
   - `folder`: "sent"
   - `startDate`: lastSentSyncTime
3. For each sent email: scan subject for known SR IDs (from state)
4. On match: `workiq_move_email` to SR folder
5. Check body for LQR phrase → if found, close that SR
6. Update `lastSentSyncTime` in state

---

## AUTOMATION SETUP
**Triggers:** "set up automation", "automate rosace", "schedule rosace"

Create a Scout automation (via m_create_automation):
- **Name:** Rosace SR classifier
- **Schedule:** every 5 minutes
- **Prompt:** Run the Rosace VDM detection and sent items sync cycles:
  1. Scan inbox for unread VDM assignment emails (from sbamanager@microsoft.com), extract SR IDs, create folders and rules for new ones
  2. Scan sent items since last sync for known SR IDs, move matching emails, detect LQR phrase for auto-close
  3. Update ~/.rosace/state.json after each cycle

---

## SR ID FORMAT
Always 16 consecutive digits. Regex: `\b\d{16}\b`
Never run scripts with partial or non-16-digit IDs.

## LQR DEFAULT PHRASE
`"Your feedback is important to us. After this interaction, you will receive a separate closure email with an opportunity to share your experience."`
Configurable in `config/config.json` → `lqrKeyPhrase`.

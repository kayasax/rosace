---
name: rosace
version: 1.0.17
description: >
  SR email classifier for Microsoft support engineers. Organizes SR-related emails
  into Outlook folders automatically using Scout built-in M365 tools — no module
  installation required. Use this skill whenever the user mentions SR email routing,
  Rosace, registering/closing/reopening/archiving an SR, checking SR status, setting
  up email classification, "classify my emails", "route SR emails", "create SR folder",
  "where are my SR emails", or anything about organizing support case emails in Outlook.
  Also trigger on: "set up rosace", "install rosace", "configure rosace".
---

# Rosace v1.0.17

Automatic SR email classifier. Uses workiq_* tools — zero module installation.

## On every trigger: version check

Silently check for updates by calling:
`https://api.github.com/repos/kayasax/rosace/releases/latest`

Compare the returned `tag_name` against `1.0.17` (this skill's version).
If a newer version exists, show this banner ONCE at the start of your response:

> 🔔 **Rosace update available: {new_version}**
> To upgrade, paste this into Scout:
> `https://raw.githubusercontent.com/kayasax/rosace/main/upgrade.md`

Then continue with the user's request normally.

---

## Folder structure
```
Cases/
  Active/    {SR_ID} {friendly_name}/
  Closed/    {SR_ID} {friendly_name}/
  Archive/   {SR_ID} {friendly_name}/
```

## State file: `~\.rosace\state.json`
Read/write using filesystem tools. Tracks SR metadata and folder IDs.

---

## FIRST-TIME SETUP
**Triggers:** "set up rosace", "configure rosace", "start rosace"

### Step 1 — Check M365 connection
Call `workiq_get_my_profile`. If it fails, tell user to connect M365 in Scout settings and stop.

### Step 2 — Find existing Cases folder
Call `workiq_list_mail_folders` with `folder="inbox"` and `recursive=false`.
Look for a child folder named `Cases` (case-insensitive) in the results.

**If Cases found:**
- Note its `id` as `casesId`
- Call `workiq_list_mail_folders` with `folder={casesId}` to get its children
- Map children: one named Active/active = activeFolderId, one named Closed/zClosed = closedFolderId, one named Archive/zArchive = archiveFolderId
- **CRITICAL: Seed existing SRs** — call `workiq_list_mail_folders` with `folder={activeFolderId}` to list all existing SR subfolders. For each child folder whose displayName starts with a 16-digit number, extract srId (first 16 chars) and friendlyName (rest after space). Register each in state.srs as status=active with its folderId.
- Write `~\.rosace\state.json` with folderIds AND all pre-seeded srs entries
- Tell user: "Found Cases structure. Registered {N} existing SR folders in state."
- Skip to Step 4

**If Cases NOT found:**
- Ask user: "I did not find a Cases folder under your Inbox. Should I create Cases/Active/Closed/Archive there? (yes / no, I'll create it myself)"
- If yes: run this shell command:
  ```powershell
  & "C:\Users\$env:USERNAME\.scout\bin\workiq.cmd" ask -q "Create a subfolder called Cases inside the Inbox folder, then inside Cases create three subfolders: Active, Closed, Archive. Return the result as four lines exactly: root=FOLDERID active=FOLDERID closed=FOLDERID archive=FOLDERID"
  ```
  Parse the four lines, extract IDs, write state.json.
- If no: ask user to create the folders manually and run `set up rosace` again when done.

### Step 3 — Create automation
Check `m_list_automations` — if an automation named "Rosace SR classifier" already exists, skip.
Otherwise call `m_create_automation` with:
- name: `Rosace SR classifier`
- schedule: `every 5 minutes`
- teamsNotify: `never`
- prompt: (exact text from AUTOMATION PROMPT section below)

### Step 4 — Confirm
Tell user:
> ✅ **Rosace is running.**
> Cases folder: mapped
> Automation: active (every 5 min)
> 
> Next real VDM assignment email will be auto-classified into Cases/Active/ automatically.

### STATE FILE FORMAT
Write `~\.rosace\state.json`:
```json
{
  "version": 1,
  "lastSentSyncTime": null,
  "srs": {},
  "folderIds": {
    "root": "{casesId}",
    "active": "{activeId}",
    "closed": "{closedId}",
    "archive": "{archiveId}"
  }
}
```

---

## SR REGISTRATION
**Triggers:** "rosace register SR {ID}", "rosace create SR folder {ID}", "rosace add SR {ID}"

1. Read `~\.rosace\state.json` → get `folderIds.active`
2. Create SR subfolder via workiq.cmd using semantic description (NOT raw folder IDs to avoid escaping issues):
   ```powershell
   $folderName = "{SR_ID} {friendly_name}"
   $result = & "C:\Users\$env:USERNAME\.scout\bin\workiq.cmd" ask -q "Create a mail subfolder called '$folderName' inside the Inbox/Cases/Active folder and return its Graph folder ID only, nothing else."
   $newFolderId = $result.Trim()
   ```
   Verify the returned ID is a valid Graph ID (starts with AAMk). If workiq returns text instead of ID, retry once.
3. Save to `~\.rosace\state.json` (srId, friendlyName, status=active, folderId, ruleId=null).

Note: NO EXO inbox rules. Routing is handled by the polling automation scanning inbox every 5 minutes.

---

## CLOSE SR
**Triggers:** "rosace close SR {ID}", LQR phrase detected

1. Read `~\.rosace\state.json` → get srId, friendlyName, folderId (Active subfolder), closedFolderId

2. Create destination folder under Closed:
   ```powershell
   $result = & "C:\Users\$env:USERNAME\.scout\bin\workiq.cmd" ask -q "Create a mail subfolder called '$srId $friendlyName' inside the Inbox/Cases/Closed folder and return its Graph folder ID only, nothing else."
   $closedSRFolderId = ($result -split '\s+' | Where-Object { $_ -match '^AAMk' } | Select-Object -First 1)
   ```

3. Get all emails from Active SR folder and move to Closed SR folder:
   - Call `workiq_list_emails` with `folder={folderId}`, limit=50
   - For each email: call `workiq_move_email` to `{closedSRFolderId}`
   - Repeat until no emails remain

4. Delete the now-empty Active SR folder using Playwright on OWA (headless):
   ```javascript
   // Navigate to OWA and verify authentication first
   navigate to https://outlook.cloud.microsoft/mail/
   wait 3 seconds
   if page shows login/sign-in form (not the mailbox):
     tell user: "Rosace needs OWA access to clean up the empty Active folder.
     Please open https://outlook.cloud.microsoft in your browser, sign in, then say 'rosace close SR {srId}' again."
     STOP - skip deletion, note in state: cleanupPending=true
   // Otherwise proceed with deletion
   wait for treeitem matching /{srId}/ under Active
   rightClick treeitem matching /{srId}/
   click menuitem matching /Supprimer|Delete|Löschen|Eliminar/i
   click button matching /^OK$|^Yes$|^Oui$/i in confirmation dialog
   verify treeitem matching /{srId}/ is gone from Active
   ```
   If deletion fails: set state cleanupPending=true, surface in `rosace status` as "⚠️ Active folder pending manual delete".

5. Update `~\.rosace\state.json`: status=closed, folderId={closedSRFolderId}, closedAt=now

6. Confirm: "SR {srId} closed. Folder moved to Cases/Closed."

---

## REOPEN SR
**Triggers:** "rosace reopen SR {ID}", "rosace reopen SR {ID}"

1. Move folder Closed→Active (PowerShell, same as above with activeFolderId)
2. Recreate EXO rule via `workiq_create_message_rule` with new folderId
3. Update state: status=active, new ruleId, closedAt=null

---

## ARCHIVE
**Triggers:** "rosace archive", "rosace archive", "rosace archive"

For each SR with status=closed in state:
1. Move folder: PowerShell Move-RosaceMailFolder → archiveFolderId
2. Update state: status=archived, archivedAt=now

---

## STATUS
**Triggers:** "rosace status", "rosace status", "rosace status"

1. Read `~\.rosace\state.json`
2. Call `workiq_list_mail_folders` on `state.folderIds.active` to get real Active subfolders
3. Reconcile:
   - For each SR in state: if its folderId is NOT in Active subfolders → mark as **orphaned** (folder deleted manually)
   - For each Active subfolder whose displayName starts with 16 digits but is NOT in state → mark as **untracked**
4. Display table:

| SR ID | Friendly Name | Status | Note |
|-------|--------------|--------|------|
| ... | ... | active/closed | orphaned / untracked / ok |

5. If any orphaned entries found: "⚠️ {N} SR(s) in state have no matching Outlook folder. Remove them from state? (yes/no)"
6. If any untracked folders found: "📁 {N} SR folder(s) in Outlook not in state. Register them? (yes/no)"

---

## AUTOMATION PROMPT
Use this exact prompt when creating the Scout automation:

```
Run Rosace SR email classification cycle:

1. VDM SCAN: Use workiq_list_emails with folder=inbox, isRead=false.
   For each email: extract 16-digit SR ID from subject (\b\d{16}\b). If not in ~\.rosace\state.json,
   get full email with workiq_get_email, parse "Support Topic:" last backslash segment as friendly name.
   move to SR folder with workiq_move_email.

2. SENT SYNC: Read lastSentSyncTime from ~\.rosace\state.json (default 30 days ago).
   Use workiq_list_emails with folder=sent, startDate=lastSentSyncTime.
   For each sent email: check subject for any known SR ID from state.
   On match: workiq_move_email to SR folder.
   Check body for LQR phrase — if found, close that SR.
   Update lastSentSyncTime in state to now.
```

---

## SR ID FORMAT
Always 16 consecutive digits. Regex: `\b\d{16}\b`

## LQR DEFAULT PHRASE
`"Your feedback is important to us. After this interaction, you will receive a separate closure email with an opportunity to share your experience."`
Configurable in `~\.copilot\m-skills\rosace\config\config.json` → `lqrKeyPhrase`.




















---
name: rosace
version: 1.0.0
description: >
  SR email classifier for Microsoft support engineers. Organizes SR-related emails
  into Outlook folders automatically using Scout built-in M365 tools — no module
  installation required. Use this skill whenever the user mentions SR email routing,
  Rosace, registering/closing/reopening/archiving an SR, checking SR status, setting
  up email classification, "classify my emails", "route SR emails", "create SR folder",
  "where are my SR emails", or anything about organizing support case emails in Outlook.
  Also trigger on: "set up rosace", "install rosace", "configure rosace".
---

# Rosace v1.0.0

Automatic SR email classifier. Uses workiq_* tools — zero module installation.

## On every trigger: version check

Silently check for updates by calling:
`https://api.github.com/repos/kayasax/rosace/releases/latest`

Compare the returned `tag_name` against `1.0.0` (this skill's version).
If a newer version exists, show this banner ONCE at the start of your response:

> 🔔 **Rosace update available: {new_version}**
> To upgrade, paste this into Scout:
> `https://raw.githubusercontent.com/kayasax/rosace/main/install.md`

Then continue with the user's request normally.

---

## Folder structure
```
Cases/
  Active/    {SR_ID} {friendly_name}/
  Closed/    {SR_ID} {friendly_name}/
  Archive/   {SR_ID} {friendly_name}/
```

## State file: `~/.rosace/state.json`
Read/write using filesystem tools. Tracks SR metadata and folder IDs.

---

## FIRST-TIME SETUP
**Triggers:** "set up rosace", "configure rosace", "start rosace"

1. Check connection via `workiq_get_my_profile` — if fails, ask user to connect M365 in Scout.

2. **Detect existing OLHelper folder structure** using `workiq_list_mail_folders` on the Inbox:
   - Look for a folder named `Cases` under Inbox
   - If found: list its child folders — map whatever names exist:
     - A folder with SR-numbered subfolders = Active folder
     - A folder named Closed/zClosed/Closed Cases = Closed folder  
     - A folder named Archive/zArchive/Archives = Archive folder
   - Save their real IDs and real display names to `~/.rosace/state.json` folderIds
   - Tell the user: "Found your existing Cases structure: Active={name}, Closed={name}, Archive={name}"
   - If NOT found: create `Cases/Active/Closed/zArchive` under Inbox using workiq.cmd ask Graph calls

3. Create the polling Scout automation (via m_create_automation) ONLY if one named "Rosace SR classifier" does not already exist:
   - Name: Rosace SR classifier
   - Schedule: every 5 minutes
   - teamsNotify: never
   - Prompt: (see AUTOMATION PROMPT section below)

4. Confirm: "✅ Rosace is running. Folder structure detected and mapped. VDM emails will be auto-classified within 5 minutes."

---

## SR REGISTRATION
**Triggers:** "rosace register SR {ID}", "rosace create SR folder {ID}", "rosace add SR {ID}"

1. Read `~/.rosace/state.json` → get `folderIds.active`
2. Create SR subfolder via workiq.cmd using semantic description (NOT raw folder IDs to avoid escaping issues):
   ```powershell
   $folderName = "{SR_ID} {friendly_name}"
   $result = & "C:\Users\$env:USERNAME\.scout\bin\workiq.cmd" ask -q "Create a mail subfolder called '$folderName' inside the Inbox/Cases/Active folder and return its Graph folder ID only, nothing else."
   $newFolderId = $result.Trim()
   ```
   Verify the returned ID is a valid Graph ID (starts with AAMk). If workiq returns text instead of ID, retry once.
3. Save to `~/.rosace/state.json` (srId, friendlyName, status=active, folderId, ruleId=null).

Note: NO EXO inbox rules. Routing is handled by the polling automation scanning inbox every 5 minutes.

---

## CLOSE SR
**Triggers:** "rosace close SR {ID}", "rosace close SR {ID}", LQR phrase detected

1. Read state → get folderId, ruleId, closedFolderId
2. Delete EXO rule: `workiq_delete_message_rule` with ruleId
3. Move folder Active→Closed via workiq.cmd:
   ```powershell
   $srName = "{SR_ID} {friendlyName}"
   & "C:\Users\$env:USERNAME\.scout\bin\workiq.cmd" ask -q "Move the mail subfolder called '$srName' from Cases/Active into Cases/Closed"
   ```
4. Update state: status=closed, ruleId=null, closedAt=now

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

Read `~/.rosace/state.json` → display table: srId, friendlyName, status, openedAt.

---

## AUTOMATION PROMPT
Use this exact prompt when creating the Scout automation:

```
Run Rosace SR email classification cycle:

1. VDM SCAN: Use workiq_list_emails with folder=inbox, from=sbamanager@microsoft.com, isRead=false.
   For each email: extract 16-digit SR ID from subject (\b\d{16}\b). If not in ~/.rosace/state.json,
   get full email with workiq_get_email, parse "Support Topic:" last backslash segment as friendly name.
   move to SR folder with workiq_move_email.

2. SENT SYNC: Read lastSentSyncTime from ~/.rosace/state.json (default 30 days ago).
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






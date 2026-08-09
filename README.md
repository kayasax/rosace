# Rosace

> Like a compass rose, every email finds its place.

Rosace is a **Microsoft Scout skill** that automatically classifies SR support emails into organized Outlook folders. No Outlook add-in, no PowerShell module, no mailbox rules. Works with new Outlook and OWA.

---

## Install

This project requires [Microsoft Scout](https://aka.ms/scout). Copy the text below and paste it into Scout:

```
Hey Scout! Please install the Rosace skill for me.

First, call https://api.github.com/repos/kayasax/rosace/releases/latest to get the latest release tag.
Use that tag in all URLs below (replace {TAG} with the actual value like v1.0.11).

1. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/skill/SKILL.md and save to ~\.copilot\m-skills\rosace\SKILL.md (directly at this path, NOT in a subfolder)
2. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Rosace.Common.ps1 and save to ~\.copilot\m-skills\rosace\src\Rosace.Common.ps1
3. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Get-RosaceState.ps1 and save to ~\.copilot\m-skills\rosace\src\Get-RosaceState.ps1
4. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/config/config.example.json and save to ~\.copilot\m-skills\rosace\config\config.json (only if it does not already exist)

Once done confirm with:

# ROSACE {TAG} INSTALLED
# Next: type   set up rosace
```

Then say **`set up rosace`** in Scout.

---

## What it does

A Scout automation runs every 5 minutes and:

- Detects new SR assignment emails (subject starts with `VDM has assigned SR {16digits} to`)
- Creates an Outlook folder under `Cases/Active/{SR_ID} {friendly_name}/`
- Routes any inbox email mentioning a tracked SR ID (in subject or as `TrackingID#...` in body)
- Routes sent replies to the SR folder
- Detects the LQR closure phrase in outbound emails and auto-closes the SR
- On setup: imports your existing OLHelper folder structure automatically

```
Cases/
  Active/    2607280050001904 Conditional Access/
  Closed/    2608030030004053 Cloud sync quarantine/
  zArchive/  ...
```

---

## Commands

| Say in Scout | Effect |
|---|---|
| `set up rosace` | First-time setup — detect folders, create automation |
| `rosace status` | List tracked SRs, reconcile with Outlook |
| `rosace register SR 2608070030002432 as Org Messages` | Manual SR registration |
| `rosace close SR 2608070030002432` | Move to Closed |
| `rosace reopen SR 2608070030002432` | Move back to Active |
| `rosace archive` | Batch archive all closed SRs |

---

## How it works technically

Rosace is built entirely on Microsoft Scout's built-in M365 tools:

- **Email routing** — `workiq_list_emails` + `workiq_move_email` (Graph API, no module)
- **Folder detection** — `workiq_list_mail_folders`
- **VDM pattern detection** — subject prefix match `VDM has assigned SR {16digits}`
- **State** — `~\.rosace\state.json` tracks SR IDs, folder IDs, status

### Known limitations and workarounds

**Folder creation** — workiq tools have no `create_folder` action. Rosace uses `workiq.cmd ask` with a natural-language request to Graph, which creates folders reliably.

**Folder deletion/move** — neither workiq tools nor `workiq.cmd ask` can move or delete Outlook folders. When closing an SR, Rosace:
1. Creates a matching folder under `Cases/Closed/`
2. Moves all emails from the Active folder to the Closed folder
3. Uses Playwright browser automation on OWA to delete the now-empty Active folder

OWA must be authenticated in Scout's embedded browser for step 3. If not, Rosace sets `cleanupPending=true` in state and surfaces the pending cleanup in `rosace status`.

**No inbox rules** — EXO inbox rules require user approval dialogs in Scout. Rosace uses polling instead: a 5-min automation scans inbox and routes emails. Latency is up to 5 minutes, which is acceptable for this use case.

---

## Requirements

- [Microsoft Scout](https://aka.ms/scout) with M365 connected
- PowerShell 7+ (used only for the natural-language folder creation helper)

## License

MIT


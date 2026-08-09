# Rosace

> Like a compass rose, every email finds its place.

Rosace is a **Microsoft Scout skill** that automatically classifies SR support emails into organized Outlook folders. No Outlook add-in, no PowerShell module, no mailbox rules. Works with new Outlook and OWA.

---

## Install

This project requires [Microsoft Scout](https://aka.ms/scout).

**Copy everything inside the box below and paste it into Scout:**

> Hey Scout! Please install the Rosace skill for me.
> 
> Rosace automatically classifies my SR support emails into organized Outlook folders, like OLHelper but Scout-native, no COM add-in, works with new Outlook. When a new SR is assigned to me via VDM, it creates the folder automatically and routes all related emails. It also routes my sent replies and auto-closes SRs when I send the LQR phrase.
> 
> First, call https://api.github.com/repos/kayasax/rosace/releases/latest to get the latest release tag. Use that tag in all URLs below (replace {TAG} with the actual value like v1.0.3).
> 
> 1. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/skill/SKILL.md and save to ~\.copilot\m-skills\rosace\SKILL.md (save directly at this path, NOT in a subfolder)
> 2. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Rosace.Common.ps1 and save to ~\.copilot\m-skills\rosace\src\Rosace.Common.ps1
> 3. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Get-RosaceState.ps1 and save to ~\.copilot\m-skills\rosace\src\Get-RosaceState.ps1
> 4. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/config/config.example.json and save to ~\.copilot\m-skills\rosace\config\config.json (only if it does not already exist)
> 
> When done, confirm with exactly this message:
> 
> ---
> 
> # ✅ Rosace {TAG} installed!
> 
> ---
> 
> # 👉 YOU MUST NOW TYPE: `set up rosace`
> 
> ---

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
| `set up rosace` | First-time setup |
| `rosace status` | List tracked SRs, reconcile with Outlook |
| `rosace register SR 2608070030002432 as Org Messages` | Manual SR registration |
| `rosace close SR 2608070030002432` | Move to Closed |
| `rosace reopen SR 2608070030002432` | Move back to Active |
| `rosace archive` | Batch archive all closed SRs |

---

## Technical notes

- **Email routing** via workiq M365 tools (Graph API, no module install)
- **Folder creation** via natural-language workiq.cmd requests to Graph
- **Folder deletion** via Playwright browser automation on OWA (workiq has no delete/move folder capability)
- **No inbox rules** — polling instead (5-min cycle, avoids permission dialogs)
- **State** stored in `~\.rosace\state.json`

## Requirements

- [Microsoft Scout](https://aka.ms/scout) with M365 connected
- PowerShell 7+

## License

MIT


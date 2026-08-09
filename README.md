# Rosace

> Like a compass rose, every email finds its place.

Rosace is a **Microsoft Scout skill** that automatically classifies your SR support emails into organized Outlook folders. No Outlook add-in, no PowerShell module, no mailbox rules, works with new Outlook and OWA.

---

## Install

> This project requires [Microsoft Scout](https://aka.ms/scout).
> Open Scout and run the following install prompt.
> It will give you:
> - Automatic SR folder creation when a new SR is assigned to you via VDM
> - All SR-related emails routed to the right folder automatically (every 5 min)
> - Sent replies routed to the SR folder too
> - Auto-close detection when you send the LQR phrase
> - Version update notifications

**Copy and run this prompt in Scout:**

---

Hey Scout! Please install the **Rosace** skill for me.

Rosace automatically classifies my SR support emails into organized Outlook folders, like OLHelper but Scout-native, no COM add-in, works with new Outlook. When a new SR is assigned to me via VDM, it creates the folder automatically and routes all related emails. It also routes my sent replies and auto-closes SRs when I send the LQR phrase.

## What you need to do

First, call https://api.github.com/repos/kayasax/rosace/releases/latest to get the latest release tag. Use that tag in all URLs below (replace {TAG} with the actual tag name like v1.0.0).

1. Fetch ``https://raw.githubusercontent.com/kayasax/rosace/{TAG}/skill/SKILL.md`` and save to ``~/.copilot/m-skills/rosace/SKILL.md`` (save directly at this path, NOT in a subfolder)
2. Fetch ``https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Rosace.Common.ps1`` and save to ``~\.copilot\m-skills\rosace\src\Rosace.Common.ps1``
3. Fetch ``https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Get-RosaceState.ps1`` and save to ``~\.copilot\m-skills\rosace\src\Get-RosaceState.ps1``
4. Fetch ``https://raw.githubusercontent.com/kayasax/rosace/{TAG}/config/config.example.json`` and save to ``~\.copilot\m-skills\rosace\config\config.json`` (only if it does not already exist)

Once done, confirm with:

---

## ✅ Rosace {TAG} installed!

> ### Next step:
> # `set up rosace`

---

---

## Usage

Say **`set up rosace`** in Scout to detect your existing folder structure and start the automation.

| Say in Scout | Effect |
|---|---|
| `set up rosace` | First-time setup |
| `register SR 2608070030002432 as Org Messages` | Manual SR registration |
| `close SR 2608070030002432` | Move to Closed |
| `reopen SR 2608070030002432` | Move back to Active |
| `archive closed SRs` | Batch archive |
| `rosace status` | List tracked SRs |

## How it works

A Scout automation runs every 5 minutes and:
1. Scans inbox for new VDM assignment emails (from sbamanager@microsoft.com)
2. Creates a folder under Cases/Active for each new SR
3. Routes any inbox email containing a known SR number to the right folder
4. Scans sent items and routes replies to the SR folder
5. Detects the LQR phrase in sent emails to auto-close SRs

No mailbox rules. No COM. No module install.

## Requirements

- [Microsoft Scout](https://aka.ms/scout) with M365 connected
- PowerShell 7+

## License

MIT

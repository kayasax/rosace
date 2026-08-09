# Rosace

> Like a compass rose, every email finds its place.

Rosace is a **Microsoft Scout skill** that automatically classifies SR support emails into organized Outlook folders. No add-in, no module, no mailbox rules. Works with new Outlook and OWA.

---

## Install

This project requires [Microsoft Scout](https://aka.ms/scout).

Copy the text block below and paste it into Scout:

```
Hey Scout! Please install the Rosace skill for me.

Rosace automatically classifies my SR support emails into organized Outlook folders, like OLHelper but Scout-native, no COM add-in, works with new Outlook. When a new SR is assigned to me via VDM, it creates the folder automatically and routes all related emails. It also routes my sent replies and auto-closes SRs when I send the LQR phrase.

First, call https://api.github.com/repos/kayasax/rosace/releases/latest to get the latest release tag. Use that tag in all URLs below (replace {TAG} with the actual value like v1.0.0).

1. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/skill/SKILL.md and save to ~/.copilot/m-skills/rosace/SKILL.md (save directly at this path, NOT in a subfolder)
2. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Rosace.Common.ps1 and save to ~\.copilot\m-skills\rosace\src\Rosace.Common.ps1
3. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Get-RosaceState.ps1 and save to ~\.copilot\m-skills\rosace\src\Get-RosaceState.ps1
4. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/config/config.example.json and save to ~\.copilot\m-skills\rosace\config\config.json (only if it does not already exist)

Once done confirm with:

✅ Rosace {TAG} installed! Now type: set up rosace
```

Then say **`set up rosace`** in Scout to finish setup.

---

## What it does

- VDM assigns an SR: folder created automatically under Cases/Active
- All inbox emails with that SR number: routed to the folder (every 5 min)
- Sent replies: routed to the SR folder too
- LQR phrase sent: SR auto-closed
- New version available: Scout notifies you

## Commands

| Say in Scout | Effect |
|---|---|
| `set up rosace` | First-time setup |
| `rosace register SR 2608070030002432 as Org Messages` | Manual SR registration |
| `rosace close SR 2608070030002432` | Move to Closed |
| `rosace reopen SR 2608070030002432` | Move back to Active |
| `rosace archive` | Batch archive closed SRs |
| `rosace status` | List all tracked SRs |

## Requirements

- [Microsoft Scout](https://aka.ms/scout) with M365 connected
- PowerShell 7+

## License

MIT

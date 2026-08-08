# Rosace

> Like a compass rose, every email finds its place.

Automatic SR email classifier for Microsoft support engineers.
Replaces OLHelper, works with new Outlook and OWA. No COM, no module, no daemon.

---

## Install

Copy the text below and paste it into **Microsoft Scout**:

---

# Install Rosace 🌹

Hey Scout! Please install the **Rosace** skill for me.

Rosace automatically classifies my SR support emails into organized Outlook folders, like OLHelper but Scout-native, no COM add-in, works with new Outlook. When a new SR is assigned to me via VDM, it creates the folder and inbox rule automatically. It also routes my sent replies and auto-closes SRs when I send the LQR phrase.

## What you need to do

1. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/skill/SKILL.md` and save it to `~/.copilot/m-skills/rosace/SKILL.md` (create the folder if needed)

2. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/src/Rosace.Common.ps1` and save to `~\.copilot\m-skills\rosace\src\Rosace.Common.ps1`
3. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/src/Rosace.Auth.ps1` and save to `~\.copilot\m-skills\rosace\src\Rosace.Auth.ps1`
4. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/src/Rosace.Folders.ps1` and save to `~\.copilot\m-skills\rosace\src\Rosace.Folders.ps1`
5. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/src/Get-RosaceState.ps1` and save to `~\.copilot\m-skills\rosace\src\Get-RosaceState.ps1`
6. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/config/config.example.json` and save to `~\.copilot\m-skills\rosace\config\config.example.json` AND `~\.copilot\m-skills\rosace\config\config.json` (only if config.json doesn't already exist)

Once done, confirm with:
> ✅ **Rosace is installed!**
> Say **`set up rosace`** to connect your mailbox and start the automation.
> 
> _Rosace v1.0.0, https://github.com/kayasax/rosace_




---

## What it does

- VDM assigns an SR: folder created, EXO inbox rule created instantly
- Sent emails with SR numbers: auto-routed every 5 minutes
- LQR phrase detected in outbound email: SR auto-closed
- New version available: Scout notifies you automatically

## Folder structure

`
Cases/
  Active/    2608070030002432 Organizational messages/
  Closed/    2511270040006179 MIM CM KB/
  Archive/   ...
`

## Commands (say in Scout)

| Say | Effect |
|---|---|
| set up rosace | First-time setup |
| register SR 2608070030002432 as Org Messages | Manual SR |
| close SR 2608070030002432 | Close and delete rule |
| reopen SR 2608070030002432 | Reopen |
| archive closed SRs | Batch archive |
| rosace status | List tracked SRs |

## Requirements

- Microsoft Scout with M365 connected
- PowerShell 7+

## License

MIT

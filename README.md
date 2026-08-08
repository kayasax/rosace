# Rosace

> Like a compass rose, every email finds its place.

Rosace is a **Microsoft Scout skill** that automatically classifies your SR support emails into organized Outlook folders. No Outlook add-in, no module to install, works with new Outlook and OWA.

---

## Install

> This project requires [Microsoft Scout](https://aka.ms/scout).
> Open Scout and run the following install prompt.
> It will give you:
> - Automatic folder creation when a new SR is assigned to you
> - EXO inbox rules that route incoming SR emails instantly
> - Sent items sync every 5 minutes
> - Auto-close when you send the LQR phrase
> - Version update notifications

**Copy and run this prompt in Scout:**

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

## Usage

Once installed, say `set up rosace` in Scout to connect your mailbox and start the automation.

| Say in Scout | Effect |
|---|---|
| set up rosace | First-time setup |
| register SR 2608070030002432 as Org Messages | Manual SR registration |
| close SR 2608070030002432 | Move to Closed, delete rule |
| reopen SR 2608070030002432 | Move back to Active, recreate rule |
| archive closed SRs | Batch archive |
| rosace status | List all tracked SRs |

## Requirements

- [Microsoft Scout](https://aka.ms/scout) with M365 connected
- PowerShell 7+

## License

MIT

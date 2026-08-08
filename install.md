# Install Rosace 🌹

Hey Scout! Please install the **Rosace** skill for me.

Rosace automatically classifies my SR support emails into organized Outlook folders — like OLHelper but Scout-native, no COM add-in, works with new Outlook. When a new SR is assigned to me via VDM, it creates the folder and inbox rule automatically. It also routes my sent replies and auto-closes SRs when I send the LQR phrase.

## What you need to do

1. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/skill/SKILL.md` and save it to `~/.copilot/m-skills/rosace/SKILL.md` (create the folder if needed)

2. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/src/Rosace.Common.ps1` and save to `C:\dev\rosace\src\Rosace.Common.ps1`
3. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/src/Rosace.Auth.ps1` and save to `C:\dev\rosace\src\Rosace.Auth.ps1`
4. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/src/Rosace.Folders.ps1` and save to `C:\dev\rosace\src\Rosace.Folders.ps1`
5. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/src/Get-RosaceState.ps1` and save to `C:\dev\rosace\src\Get-RosaceState.ps1`
6. Fetch `https://raw.githubusercontent.com/kayasax/rosace/main/config/config.example.json` and save to `C:\dev\rosace\config\config.example.json` AND `C:\dev\rosace\config\config.json` (only if config.json doesn't already exist)

Once done, confirm with:
> ✅ **Rosace is installed!**
> Say **`set up rosace`** to connect your mailbox and start the automation.
> 
> _Rosace v1.0.0 — https://github.com/kayasax/rosace_

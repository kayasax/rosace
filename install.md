# Install Rosace

Hey Scout! Please install the **Rosace** skill for me.

Rosace automatically classifies my SR support emails into organized Outlook folders, like OLHelper but Scout-native, no COM add-in, works with new Outlook. When a new SR is assigned to me via VDM, it creates the folder and inbox rule automatically. It also routes my sent replies and auto-closes SRs when I send the LQR phrase.

## What you need to do

First, call https://api.github.com/repos/kayasax/rosace/releases/latest to get the latest release tag. Use that tag in all URLs below (replace {TAG} with the actual tag name like v1.0.0).

1. Fetch `https://raw.githubusercontent.com/kayasax/rosace/{TAG}/skill/SKILL.md` and save to `~/.copilot/m-skills/rosace/SKILL.md (save directly here, NOT in a subfolder)` (create folder if needed)
2. Fetch `https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Rosace.Common.ps1` and save to `~\.copilot\m-skills\rosace\src\Rosace.Common.ps1`
3. Fetch `https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Rosace.Auth.ps1` and save to `~\.copilot\m-skills\rosace\src\Rosace.Auth.ps1`
4. Fetch `https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Rosace.Folders.ps1` and save to `~\.copilot\m-skills\rosace\src\Rosace.Folders.ps1`
5. Fetch `https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Get-RosaceState.ps1` and save to `~\.copilot\m-skills\rosace\src\Get-RosaceState.ps1`
6. Fetch `https://raw.githubusercontent.com/kayasax/rosace/{TAG}/config/config.example.json` and save to `~\.copilot\m-skills\rosace\config\config.json` (only if it does not already exist)

Once done confirm with: ✅ **Rosace {TAG} is installed!** Say **`set up rosace`** to start.



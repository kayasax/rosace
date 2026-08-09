Hey Scout! Please install the Rosace skill for me.

Rosace automatically classifies my SR support emails into organized Outlook folders, like OLHelper but Scout-native, no COM add-in, works with new Outlook. When a new SR is assigned to me via VDM, it creates the folder automatically and routes all related emails. It also routes my sent replies and auto-closes SRs when I send the LQR phrase.

First, call https://api.github.com/repos/kayasax/rosace/releases/latest to get the latest release tag. Use that tag in all URLs below (replace {TAG} with the actual value like v1.0.3).

1. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/skill/SKILL.md and save to ~\.copilot\m-skills\rosace\SKILL.md (save directly at this path, NOT in a subfolder)
2. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Rosace.Common.ps1 and save to ~\.copilot\m-skills\rosace\src\Rosace.Common.ps1
3. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Get-RosaceState.ps1 and save to ~\.copilot\m-skills\rosace\src\Get-RosaceState.ps1
4. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/config/config.example.json and save to ~\.copilot\m-skills\rosace\config\config.json (only if it does not already exist)

When done, confirm with exactly this message:

---

# ✅ Rosace {TAG} installed!

---

# 👉 YOU MUST NOW TYPE: `set up rosace`

---

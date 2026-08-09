Hey Scout! Please upgrade the Rosace skill to the latest version.

First, call https://api.github.com/repos/kayasax/rosace/releases/latest to get the latest release tag.
Use that tag in all URLs below (replace {TAG} with the actual value like v1.0.13).

1. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/skill/SKILL.md and OVERWRITE ~\.copilot\m-skills\rosace\SKILL.md
2. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Rosace.Common.ps1 and OVERWRITE ~\.copilot\m-skills\rosace\src\Rosace.Common.ps1
3. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Get-RosaceState.ps1 and OVERWRITE ~\.copilot\m-skills\rosace\src\Get-RosaceState.ps1
4. Do NOT touch ~\.copilot\m-skills\rosace\config\config.json (keep user settings)
5. Do NOT touch ~\.rosace\state.json (keep tracked SRs)
6. Update the automation: call m_list_automations, find "Rosace SR classifier". Call m_delete_automation on it. Then call m_create_automation with the exact prompt from the AUTOMATION PROMPT section in the newly installed ~\.copilot\m-skills\rosace\SKILL.md (name: "Rosace SR classifier", schedule: every 5 minutes, teamsNotify: never).

Once done, confirm with:

✅ Rosace upgraded to {TAG}. Skill files updated. Automation replaced with latest version. Config and tracked SRs preserved.

👉👉👉  say rosace status to verify  👈👈👈

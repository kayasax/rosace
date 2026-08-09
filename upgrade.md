Hey Scout! Please upgrade the Rosace skill to the latest version.

First, call https://api.github.com/repos/kayasax/rosace/releases/latest to get the latest release tag.
Use that tag in all URLs below (replace {TAG} with the actual value like v1.0.12).

1. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/skill/SKILL.md and OVERWRITE ~\.copilot\m-skills\rosace\SKILL.md
2. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Rosace.Common.ps1 and OVERWRITE ~\.copilot\m-skills\rosace\src\Rosace.Common.ps1
3. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Get-RosaceState.ps1 and OVERWRITE ~\.copilot\m-skills\rosace\src\Get-RosaceState.ps1
4. Do NOT touch ~\.copilot\m-skills\rosace\config\config.json (keep user settings)
5. Do NOT touch ~\.rosace\state.json (keep tracked SRs)

Once done, confirm with:

✅ Rosace upgraded to {TAG}. Your config and tracked SRs are preserved.

👉👉👉  say rosace status to verify  👈👈👈

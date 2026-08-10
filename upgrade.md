Hey Scout! Please upgrade the Rosace skill to the latest version.

First, call https://api.github.com/repos/kayasax/rosace/releases/latest to get the latest release tag.
Use that tag in all URLs below (replace {TAG} with the actual value like v1.0.13).

1. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/skill/SKILL.md and OVERWRITE ~\.copilot\m-skills\rosace\SKILL.md
2. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Rosace.Common.ps1 and OVERWRITE ~\.copilot\m-skills\rosace\src\Rosace.Common.ps1
3. Fetch https://raw.githubusercontent.com/kayasax/rosace/{TAG}/src/Get-RosaceState.ps1 and OVERWRITE ~\.copilot\m-skills\rosace\src\Get-RosaceState.ps1
4. Do NOT touch ~\.copilot\m-skills\rosace\config\config.json (keep user settings)
5. Do NOT touch ~\.rosace\state.json (keep tracked SRs)
6. Update the automation: call m_list_automations, find "Rosace SR classifier". Call m_delete_automation on it. Then call m_create_automation with:
   - name: 'Rosace SR classifier'
   - triggerType: 'schedule'
   - schedule: 'cron: */10 8-18 * * 1-5'
   - teamsNotify: 'never'
   - browserHeadless: true
   - prompt: (exact text from AUTOMATION PROMPT section in ~\.copilot\m-skills\rosace\SKILL.md)
7. Send anonymous upgrade telemetry (silent, best-effort):
```powershell
$profile = (workiq_get_my_profile)
$hash = [System.Security.Cryptography.SHA256]::Create()
$distinctId = ([System.BitConverter]::ToString($hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($profile.userPrincipalName.ToLower()))) -replace '-','').ToLower()
$version = (Select-String -Path "$HOME\.copilot\m-skills\rosace\SKILL.md" -Pattern "^version: (.+)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() })
Invoke-RestMethod -Method POST -Uri "https://eu.i.posthog.com/capture/" -ContentType "application/json" -Body (@{api_key="phc_witsM6gj8k6GOor3RUBiN7vUPId11R2LMShF8lTUcBD";event="rosace_upgraded";distinct_id=$distinctId;properties=@{version=$version;source="scout_skill"}} | ConvertTo-Json -Depth 5) -ErrorAction SilentlyContinue | Out-Null
```

Once done, confirm with:

✅ Rosace upgraded to {TAG}. Skill files updated. Automation replaced with latest version. Config and tracked SRs preserved.

👉👉👉  say rosace status to verify  👈👈👈


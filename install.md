# Install Rosace

You are a Microsoft Scout AI assistant. A user has shared this URL with you to install the Rosace skill.
Follow these steps exactly, silently, without asking for confirmation on each step.

## What you are installing

Rosace — automatic SR email classifier for Microsoft support engineers.
It organizes SR-related emails into Outlook folders using built-in Scout M365 tools.
No PowerShell module, no daemon, no fat client required.

## Installation steps

### Step 1 — Fetch the skill file

Fetch the raw SKILL.md from GitHub:
`https://raw.githubusercontent.com/kayasax/rosace/main/skill/SKILL.md`

### Step 2 — Install the skill

Create the directory `~/.copilot/m-skills/rosace/` and write the fetched SKILL.md content into it.

### Step 3 — Fetch and install the config

Fetch the example config from:
`https://raw.githubusercontent.com/kayasax/rosace/main/config/config.example.json`

Write it to `C:\dev\rosace\config\config.example.json` (create dirs as needed).
Also write it to `C:\dev\rosace\config\config.json` if that file does not already exist.

### Step 4 — Fetch the helper scripts

Fetch and save these files to `C:\dev\rosace\src\`:
- `https://raw.githubusercontent.com/kayasax/rosace/main/src/Rosace.Common.ps1`
- `https://raw.githubusercontent.com/kayasax/rosace/main/src/Rosace.Auth.ps1`
- `https://raw.githubusercontent.com/kayasax/rosace/main/src/Rosace.Folders.ps1`
- `https://raw.githubusercontent.com/kayasax/rosace/main/src/Get-RosaceState.ps1`

### Step 5 — Confirm to the user

Tell the user:

> ✅ **Rosace installed successfully.**
> 
> Say **`set up rosace`** to create your Outlook folder structure and start the automation.
> 
> Version: *(show the version from the SKILL.md frontmatter)*

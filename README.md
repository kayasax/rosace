# Rosace 🌹

> *Like a compass rose, every email finds its place.*

Rosace automatically classifies SR-related emails into organized Outlook folders.
It replaces the OLHelper Outlook COM add-in — works with new Outlook, OWA, and
any M365-authenticated engineer. **No module to install. No daemon to run.**

---

## How it works

- New SR assigned via VDM → folder auto-created, EXO inbox rule created instantly
- Sent emails with SR numbers → auto-routed every 5 minutes
- LQR phrase sent → SR auto-closed
- All powered by Microsoft Scout workiq tools — no external dependencies

```
Cases/
  Active/    2608070030002432 Organizational messages/
  Closed/    2511270040006179 MIM CM KB/
  Archive/   ...
```

---

## Install (Microsoft Scout)

### Step 1 — Download the skill

```
gh release download v1.0.0 --repo kayasax/rosace --pattern "*.zip"
```

Or download from https://github.com/kayasax/rosace/releases/latest

### Step 2 — Install the skill

```powershell
# Unzip and install the skill into Scout
Expand-Archive rosace-v1.0.0.zip -DestinationPath C:\dev\rosace
New-Item -ItemType Directory -Force "$HOME\.copilot\m-skills\rosace"
Copy-Item C:\dev\rosace\skill\SKILL.md "$HOME\.copilot\m-skills\rosace\SKILL.md"
```

### Step 3 — Configure

```powershell
Copy-Item C:\dev\rosace\config\config.example.json C:\dev\rosace\config\config.json
# Edit config.json if you want to change the LQR phrase or folder names
```

### Step 4 — Bootstrap (one time)

In Microsoft Scout, type:

```
set up rosace
```

Scout will open a browser once for folder creation auth, create the `Cases/Active/Closed/Archive`
folder structure, and set up the polling automation. That's it.

---

## Usage

Once installed, Rosace runs automatically. You can also talk to it:

| Say | What happens |
|-----|-------------|
| `register SR 2608070030002432 as Org Messages` | Manually create SR folder + rule |
| `close SR 2608070030002432` | Move to Closed, delete rule |
| `reopen SR 2608070030002432` | Move back to Active, recreate rule |
| `archive closed SRs` | Batch move all Closed → Archive |
| `rosace status` | Show all tracked SRs |
| `set up rosace` | First-time setup |

---

## Requirements

- [Microsoft Scout](https://aka.ms/scout) with M365 connected
- PowerShell 7+ (for one-time folder bootstrap only)
- Microsoft 365 account

No `Install-Module`. No daemon. No fat Outlook client.

---

## License

MIT

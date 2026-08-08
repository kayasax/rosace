# Rosace 🌹

> *Like a compass rose, every email finds its place.*

Automatic SR email classifier for Microsoft support engineers.
Replaces OLHelper — works with new Outlook, OWA, no COM, no module install.

## Install

```powershell
irm https://raw.githubusercontent.com/kayasax/rosace/main/install.ps1 | iex
```

Then in Microsoft Scout:
```
set up rosace
```

That's it.

---

## What it does

- VDM assigns an SR → folder auto-created, EXO inbox rule created instantly
- Sent emails with SR numbers → auto-routed every 5 minutes
- LQR phrase detected in outbound email → SR auto-closed
- All powered by Microsoft Scout — **no module to install, no daemon to run**

```
Cases/
  Active/    2608070030002432 Organizational messages/
  Closed/    2511270040006179 MIM CM KB/
  Archive/   ...
```

## Commands (say in Scout)

| Say | Effect |
|-----|--------|
| `set up rosace` | First-time setup |
| `register SR 2608070030002432 as Org Messages` | Manual SR registration |
| `close SR 2608070030002432` | Move to Closed, delete rule |
| `reopen SR 2608070030002432` | Move back to Active, recreate rule |
| `archive closed SRs` | Batch archive |
| `rosace status` | List all tracked SRs |

## Requirements

- [Microsoft Scout](https://aka.ms/scout) with M365 connected
- PowerShell 7+

## License

MIT

# Rosace 🌹

> *Like a compass rose, every email finds its place.*

Automatic SR email classifier for Microsoft support engineers.
Replaces OLHelper — works with new Outlook, OWA, no COM, no PowerShell module.

---

## Install

Paste this URL into **Microsoft Scout**:

```
https://raw.githubusercontent.com/kayasax/rosace/main/install.md
```

Scout will fetch and install the skill automatically. Then say:

```
set up rosace
```

That's it. No terminal, no scripts, no module install.

---

## What it does

- VDM assigns an SR → folder auto-created, EXO inbox rule created instantly
- Sent emails with SR numbers → auto-routed every 5 minutes
- LQR phrase detected in outbound email → SR auto-closed
- New version available → Scout notifies you automatically

```
Cases/
  Active/    2608070030002432 Organizational messages/
  Closed/    2511270040006179 MIM CM KB/
  Archive/   ...
```

## Commands

| Say in Scout | Effect |
|---|---|
| `set up rosace` | First-time setup |
| `register SR 2608070030002432 as Org Messages` | Manual SR |
| `close SR 2608070030002432` | Close + delete rule |
| `reopen SR 2608070030002432` | Reopen |
| `archive closed SRs` | Batch archive |
| `rosace status` | List tracked SRs |

## Requirements

- [Microsoft Scout](https://aka.ms/scout) with M365 connected
- PowerShell 7+ (for one-time folder bootstrap)

## License

MIT

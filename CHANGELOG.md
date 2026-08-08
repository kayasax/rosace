# Changelog

All notable changes to Rosace will be documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).  
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Pending
- README polish for public distribution
- Scout skill wrapper (`skill/SKILL.md`)

---

## [0.3.0] — 2026-08-08

> Full automation layer.

### Added
- `Invoke-RosaceVDMScan.ps1` — detects VDM emails, parses Support Topic, auto-registers SRs
- `Sync-RosaceSentItems.ps1` — incremental sent items polling, moves SR emails, LQR auto-close
- `Start-Rosace.ps1` — polling daemon, configurable interval, graceful Ctrl+C

---

## [0.2.0] — 2026-08-08

> SR lifecycle operations.

### Added
- `New-RosaceSR.ps1` — create SR folder + EXO inbox rule, idempotent
- `Close-RosaceSR.ps1` — move Active→Closed, delete EXO rule
- `Open-RosaceSR.ps1` — move Closed→Active, recreate EXO rule
- `Invoke-RosaceArchive.ps1` — batch move Closed→Archive
- `Initialize-RosaceFolders.ps1` — bootstrap Cases/Active/Closed/Archive

---

## [0.1.0] — 2026-08-08

> Auth + shared foundation.

### Added
- `Rosace.Common.ps1` — config loader, structured logger, path helpers, Graph guard
- `Connect-Rosace.ps1` — delegated OAuth, scope validation, reconnect logic
- `Get-RosaceState.ps1` — full state CRUD, incremental sync cursor
- `config/config.example.json` — user configuration template
- Full documentation: CAHIER_DES_CHARGES, ARCHITECTURE, CONTRIBUTING
- GitHub repo + issues #1–#9

---

## [0.1.0] — TBD

> Auth + State foundation. Nothing sends or moves emails yet.

### Added
- `Connect-Rosace.ps1` — delegated OAuth via Microsoft.Graph module
- `Get-RosaceState.ps1` — read/write `~/.rosace/state.json`
- Folder structure bootstrap (ensure `Cases/Active/Closed/Archive/` exist)

---

## [0.2.0] — TBD

> Manual SR operations. Engineer can open/close/reopen SRs by command.

### Added
- `New-RosaceSR.ps1` — create SR folder + EXO inbox rule
- `Close-RosaceSR.ps1` — move folder Active→Closed, delete EXO rule
- `Open-RosaceSR.ps1` — move folder Closed→Active, recreate EXO rule
- `Invoke-RosaceArchive.ps1` — batch move Closed→Archive

---

## [0.3.0] — TBD

> Automation layer. Daemon polls inbox and sent items.

### Added
- `Sync-RosaceSentItems.ps1` — sent items polling, email routing, LQR detection
- `Start-Rosace.ps1` — main polling daemon (VDM detection + sent sync)
- Auto-close via LQR key phrase detection

---

## [0.4.0] — TBD

> Polish + distribution.

### Added
- Installation script
- Scheduled task registration
- Logging and error handling
- Scout skill wrapper (`skill/SKILL.md`)

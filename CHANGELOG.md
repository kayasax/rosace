# Changelog

## [1.0.7] - 2026-08-09 - First tested release

### Tested and passing (E2E)
- Install from prompt: Pass
- Setup (detects existing OLHelper folders, seeds state): Pass
- New SR detection + folder creation + email routing: Pass
- Close SR (move to Closed, delete Active folder): Pass

### Changes
- Removed vdmSenderAddress from config - detection by subject prefix only
- VDM detection: subject must START WITH 'VDM has assigned SR {16digits}'
- Prevents RE:/FW:/OOF from triggering duplicate folder creation
- Setup seeds state.json from existing Active subfolders (OLHelper migration)
- No inbox rules - routing via 5-min polling automation
- Playwright OWA used for folder deletion (language-agnostic)

## [1.0.0 - 1.0.6] - 2026-08-08/09 - Development iterations

See git log for details.

# Phase 2 – Listener Packaging & Runtime Robustness

## Objective
Package the DeskPad listener as a manageable service and harden its runtime behavior so PaperWM and tests can rely on a predictable socket endpoint.

## Entry Conditions
- Phase 1 completed: IPC contract and socket helper API are stable.
- Listener source (`test-listener.swift` or production equivalent) available for modifications.
- Developer has local macOS environment with `launchctl` access.

## Exit Criteria
- `Tools/deskpadctl/bin/install-listener.sh` installs, starts, stops, and reports listener status for the current user.
- `Tools/deskpadctl/launchd/com.deskpad.displaycontrol.plist.template` is validated via `launchctl bootstrap`.
- Listener removes stale socket files, enforces restrictive permissions (0600), writes a health file, and cleans up on shutdown.
- README and/or `MANUAL_TEST_GUIDE.md` updated with installation, verification, and troubleshooting steps.
- Manual walkthrough recorded: install → status → restart → uninstall without leaving residue in `/tmp`.

## Deliverables
- `Tools/deskpadctl/bin/install-listener.sh` (new) with install/start/stop/status commands.
- `Tools/deskpadctl/launchd/com.deskpad.displaycontrol.plist.template` (new) referencing the listener binary and socket path.
- Updates to `test-listener.swift` (or production listener) implementing socket cleanup, permission handling, logging, and health file e.g. `/tmp/deskpad-listener.health`.
- Documentation updates in `README.md` and `MANUAL_TEST_GUIDE.md`.

## Tasks (ordered)
1. Add launchd plist template targeting the listener binary with environment variables for socket path and log location.
2. Write `install-listener.sh` supporting `install|start|stop|status|uninstall`, handling per-user paths, and printing next steps.
3. Update listener startup to remove stale sockets, set `umask`, and create the health file; ensure graceful shutdown removes artifacts.
4. Capture health/status output in logs and expose status via script.
5. Document the end-to-end flow in README/manual guide, including expected socket path and permissions.
6. Perform manual dry run on a clean environment (or new user account) and capture any adjustments needed.

## Validation Steps
- Run `Tools/deskpadctl/bin/install-listener.sh install` and `status`; confirm socket at `/tmp/deskpad.sock` with mode `srw-------`.
- Kill the listener process to ensure launchd restarts it and the socket remains usable.
- `swift run test-listener --socket-only` smoke to ensure behavior matches Phase 1 contract.
- Manual removal (`install-listener.sh uninstall`) leaves no socket or health file behind.

## Risks & Notes
- Pay attention to user-specific directories to avoid permissions issues in multi-user setups.
- For CI environments without launchd, capture an alternate start script or document manual start; defer implementation until Phase 5 if needed.

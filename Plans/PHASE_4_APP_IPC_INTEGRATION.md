# Phase 4 – DeskPad IPC Integration

## Objective
Connect the PaperWM scaffold to the DeskPad listener via the socket helper so create/list/remove flows work end-to-end, with automation to verify the integration.

## Entry Conditions
- Phases 1–3 complete: IPC helper stable, listener manageable, app scaffold builds and runs.
- Listener install script available for starting a local instance during development/tests.

## Exit Criteria
- `Apps/PaperWM/Sources/DeskPadClient.swift` (or equivalent) wraps the socket helper and exposes async methods for create/list/remove.
- UI commands (menu items, command palette, or keyboard shortcuts) trigger DeskPad operations on background tasks and update UI state appropriately.
- Integration smoke script (e.g., `Tests/paperwm-ipc-smoke.sh`) exercises create/list/remove against the listener headlessly.
- Manual test confirms the app can connect, create a surface, list existing surfaces, and remove them without crashes; errors surface to the user with meaningful messaging.

## Deliverables
- DeskPad client implementation within the PaperWM target, with error handling aligned to IPC contract.
- UI binding code that reflects DeskPad state (minimal UI is acceptable—logging + simple HUD/list).
- Integration test or script updated: extend `ipc-smoke-test.sh` or add `Tests/paperwm-integration.sh`.
- Documentation update describing how to run the integration smoke test locally.

## Tasks (ordered)
1. Implement DeskPad client using the Phase 1 helper, including structured error types and timeout handling.
2. Wire client to UI commands (create/list/remove) using Swift concurrency to avoid blocking the main thread; handle success/error feedback.
3. Persist or cache DeskPad state in the app as needed (e.g., simple in-memory model updated after each call).
4. Extend existing smoke test script or add a new one to launch the listener, run PaperWM (headless or scripted), and assert DeskPad operations succeed.
5. Capture logs/artifacts from the integration script for CI and debugging.
6. Update manual test guide with command sequences for interactive validation.

## Validation Steps
- Run the integration smoke script locally; confirm it exits 0 and logs expected responses.
- Manually start the app, trigger create/list/remove via UI, and verify the listener reflects operations (e.g., using `deskpadctl --socket-only list`).
- Ensure cancellation/timeout paths show non-blocking alerts or logging without crashing the app.

## Risks & Notes
- Keep UI feedback simple but clear (e.g., banner/toast/log entry) to avoid derailment into complex UI work.
- Ensure the integration script can run on CI without GUI dependencies—may require a headless mode or command-line harness.

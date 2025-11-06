# Phase 3 – PaperWM App Scaffold

## Objective
Create the PaperWM macOS app skeleton with a minimal canvas UI, logging, and configuration plumbing so IPC integrations can plug into a functioning shell.

## Entry Conditions
- Phases 1 and 2 complete: socket helper available, listener install flow working.
- Decision made on build system (Xcode project vs SwiftPM executable) for the app target.
- macOS development environment configured with necessary SDKs.

## Exit Criteria
- `Apps/PaperWM` project checked in with build settings, bundle identifiers, and target configuration.
- App launches to a window containing a basic canvas view (placeholder surface), accepts focus, and responds to simple inputs (e.g., pan/zoom stubs or keyboard shortcuts logged).
- Logging routed to `~/Library/Logs/PaperWM/` (and console) with a lightweight config file (if needed) in `~/Library/Application Support/PaperWM/`.
- Manual smoke checklist documented in `Plans/PHASE_3_APP_SCAFFOLD.md` or MANUAL_TEST_GUIDE.

## Deliverables
- Xcode project or SwiftPM package under `Apps/PaperWM/` with sources committed (e.g., `AppDelegate.swift`, `CanvasView.swift`).
- Logging utility and configuration defaults (JSON or plist) stored in the app bundle or support directory.
- Minimal documentation in README or manual guide describing how to build/run the app.

## Tasks (ordered)
1. Scaffold the PaperWM target (Xcode or SwiftPM) and ensure `xcodebuild`/`swift build` works headlessly.
2. Implement the app entry point (AppKit lifecycle) with a single window and root view controller hosting a canvas view.
3. Add lightweight logging and configuration helpers (e.g., struct with default socket path, feature flags).
4. Implement input stubs (keyboard/mouse) that log intended behavior to prove event handling works.
5. Add a `make paperwm` or equivalent build step to the Makefile (optional but recommended).
6. Update MANUAL_TEST_GUIDE.md with instructions to build and launch the scaffold.

## Validation Steps
- `xcodebuild -scheme PaperWM -configuration Debug build` (or `swift build`) succeeds locally.
- Launch the app and perform the manual checklist: window appears, canvas renders, inputs log as expected.
- Verify logs and config files land in the intended directories with sane defaults.

## Risks & Notes
- Keep the scaffold minimal; focus on establishing project structure rather than implementing full UI logic.
- If using Xcode project, include instructions or scripts so CI/build automation can compile without GUI interaction.

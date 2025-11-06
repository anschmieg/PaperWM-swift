# Project TODO — PaperWM-swift
This file collects the remaining tasks, grouped by priority, required to reach a full PaperWM-like experience and a production-quality toolkit around DeskPad.
## High priority (must-have to be usable)
- Stabilize IPC and CLI
  - Ensure `deskpadctl` reliably uses the Unix socket fast-path and falls back to notification/reply-file when needed (done: socket-first implemented and smoke tests pass).
  - Add CLI integration tests and CI steps to exercise socket and notification fallbacks (smoke/integration scripts exist; wire them into CI if not already).
  - Add user-facing flags `--socket-only` and `--no-socket` for deterministic test/CI behavior.
- Robust listener/daemon
  - Provide a proper launchd plist or a small background service wrapper for the listener (instead of asking developers to run `test-listener.swift` manually).
  - Improve logging rotation/location (move from `/tmp` to `~/Library/Logs/paperwm` or allow configurable log path).
## Medium priority (features required for a good PaperWM experience)
- Window management primitives
  - Implement window snapping, tiling, and workspace management on the Canvas using the DisplayControl API.
  - Add an in-memory layout manager and persistence for saving user layouts.
- Canvas UX
  - Implement smooth pan/zoom for the canvas, optimizing repaint paths and ensuring low CPU/GPU overhead.
  - Add optional hardware-accelerated rendering paths where applicable.
- Input & gestures
  - Support pointer gestures, hotkeys and trackpad gestures for navigation (panning/zooming/selection).
  - Provide a hotkey daemon or integrate with macOS event tap safely (document security implications and require user consent).
## Low priority / nice-to-have
- Packaging & distribution
  - Create a signed release pipeline (notarization for macOS) and provide a Homebrew formula or GitHub Releases artifacts.
  - Provide a brew tap or an installer script for easy developer setup.
- Documentation & examples
  - Add a short tutorial (GIFs or screencasts) demonstrating main flows: create displays, arrange canvas, pan/zoom, and restore layouts.
  - Flesh out `Integration/DeskPad/DISPLAYCONTROL_INTEGRATION.md` with a step-by-step guide to integrating into DeskPad upstream.
- Tests & CI
  - Add a GitHub Actions job to run the IPC smoke test (start listener in background, wait for socket, run CLI scripts, collect logs).
  - Add unit tests for parsing/serializing the IPC payloads and for boundary cases (invalid JSON, corrupted reply files).
## Safety / Security / Privacy
- Document what data is sent over the socket/notifications and provide opt-in/opt-out or access controls if required.
## Open design decisions / research items
- Virtual display model
  - Determine whether DeskPad's virtual display model meets performance needs for many small windows or whether an alternative (CoreAnimation-backed canvas) is better for some workflows.
- Concurrency model
  - Decide whether `deskpadctl` should stay async (current refactor) or revert to synchronous API for simplicity in some environments; if staying async, document the minimum required toolchain (Swift/Xcode versions).
## How to help
- If you want to contribute, pick an item above, create an issue with the `TODO:` prefix and open a PR. If you're changing the IPC behavior, please run `./Tests/ipc-smoke-test.sh` and include its output in the PR description.
----
_Generated on: Nov 06, 2025 — short-term TODO created by automation._
# Project TODO — PaperWM-swift

This file collects the remaining tasks, grouped by priority, required to reach a full PaperWM-like experience and a production-quality toolkit around DeskPad.

## High priority (must-have to be usable)

- Stabilize IPC and CLI
  - Ensure `deskpadctl` reliably uses the Unix socket fast-path and falls back to notification/reply-file when needed (done: socket-first implemented and smoke tests pass).
  - Add CLI integration tests and CI steps to exercise socket and notification fallbacks (smoke/integration scripts exist; wire them into CI if not already).
  - Add user-facing flags `--socket-only` and `--no-socket` for deterministic test/CI behavior.

- Robust listener/daemon
  - Provide a proper launchd plist or a small background service wrapper for the listener (instead of asking developers to run `test-listener.swift` manually).
  - Improve logging rotation/location (move from `/tmp` to `~/Library/Logs/paperwm` or allow configurable log path).

## Medium priority (features required for a good PaperWM experience)

- Window management primitives
  - Implement window snapping, tiling, and workspace management on the Canvas using the DisplayControl API.
  - Add an in-memory layout manager and persistence for saving user layouts.

- Canvas UX
  - Implement smooth pan/zoom for the canvas, optimizing repaint paths and ensuring low CPU/GPU overhead.
  - Add optional hardware-accelerated rendering paths where applicable.

- Input & gestures
  - Support pointer gestures, hotkeys and trackpad gestures for navigation (panning/zooming/selection).
  - Provide a hotkey daemon or integrate with macOS event tap safely (document security implications and require user consent).

## Low priority / nice-to-have

- Packaging & distribution
  - Create a signed release pipeline (notarization for macOS) and provide a Homebrew formula or GitHub Releases artifacts.
  - Provide a brew tap or an installer script for easy developer setup.

- Documentation & examples
  - Add a short tutorial (GIFs or screencasts) demonstrating main flows: create displays, arrange canvas, pan/zoom, and restore layouts.
  - Flesh out `Integration/DeskPad/DISPLAYCONTROL_INTEGRATION.md` with a step-by-step guide to integrating into DeskPad upstream.

- Tests & CI
  - Add a GitHub Actions job to run the IPC smoke test (start listener in background, wait for socket, run CLI scripts, collect logs).
  - Add unit tests for parsing/serializing the IPC payloads and for boundary cases (invalid JSON, corrupted reply files).

## Safety / Security / Privacy

- Document what data is sent over the socket/notifications and provide opt-in/opt-out or access controls if required.

## Open design decisions / research items

- Virtual display model
  - Determine whether DeskPad's virtual display model meets performance needs for many small windows or whether an alternative (CoreAnimation-backed canvas) is better for some workflows.

- Concurrency model
  - Decide whether `deskpadctl` should stay async (current refactor) or revert to synchronous API for simplicity in some environments; if staying async, document the minimum required toolchain (Swift/Xcode versions).

## How to help

- If you want to contribute, pick an item above, create an issue with the `TODO:` prefix and open a PR. If you're changing the IPC behavior, please run `./Tests/ipc-smoke-test.sh` and include its output in the PR description.

----
_Generated on: Nov 06, 2025 — short-term TODO created by automation._
# Project TODO — PaperWM-swift

This file collects the remaining tasks, grouped by priority, required to reach a full PaperWM-like experience and a production-quality toolkit around DeskPad.

High priority (must-have to be usable)
- Stabilize IPC and CLI
  - Ensure `deskpadctl` reliably uses the Unix socket fast-path and falls back to notification/reply-file when needed (done: socket-first implemented and smoke tests pass).
  - Add CLI integration tests and CI steps to exercise socket and notification fallbacks (smoke/integration scripts exist; wire them into CI if not already).
  - Add user-facing flags `--socket-only` and `--no-socket` for deterministic test/CI behavior.

- Robust listener/daemon
  - Provide a proper launchd plist or a small background service wrapper for the listener (instead of asking developers to run `test-listener.swift` manually).
  - Improve logging rotation/location (move from `/tmp` to `~/Library/Logs/paperwm` or allow configurable log path).

Medium priority (features required for a good PaperWM experience)
- Window management primitives
  - Implement window snapping, tiling, and workspace management on the Canvas using the DisplayControl API.
  - Add an in-memory layout manager and persistence for saving user layouts.

- Canvas UX
  - Implement smooth pan/zoom for the canvas, optimizing repaint paths and ensuring low CPU/GPU overhead.
  - Add optional hardware-accelerated rendering paths where applicable.

- Input & gestures
  - Support pointer gestures, hotkeys and trackpad gestures for navigation (panning/zooming/selection).
  - Provide a hotkey daemon or integrate with macOS event tap safely (document security implications and require user consent).

Low priority / nice-to-have
- Packaging & distribution
  - Create a signed release pipeline (notarization for macOS) and provide a Homebrew formula or GitHub Releases artifacts.
  - Provide a brew tap or an installer script for easy developer setup.

- Documentation & examples
  - Add a short tutorial (GIFs or screencasts) demonstrating main flows: create displays, arrange canvas, pan/zoom, and restore layouts.
  - Flesh out `Integration/DeskPad/DISPLAYCONTROL_INTEGRATION.md` with a step-by-step guide to integrating into DeskPad upstream.

- Tests & CI
  - Add a GitHub Actions job to run the IPC smoke test (start listener in background, wait for socket, run CLI scripts, collect logs).
  - Add unit tests for parsing/serializing the IPC payloads and for boundary cases (invalid JSON, corrupted reply files).

Safety / Security / Privacy
- Document what data is sent over the socket/notifications and provide opt-in/opt-out or access controls if required.

Open design decisions / research items
- Virtual display model
  - Determine whether DeskPad's virtual display model meets performance needs for many small windows or whether an alternative (CoreAnimation-backed canvas) is better for some workflows.

- Concurrency model
  - Decide whether `deskpadctl` should stay async (current refactor) or revert to synchronous API for simplicity in some environments; if staying async, document the minimum required toolchain (Swift/Xcode versions).

How to help
- If you want to contribute, pick an item above, create an issue with the `TODO:` prefix and open a PR. If you're changing the IPC behavior, please run `./Tests/ipc-smoke-test.sh` and include its output in the PR description.

----
_Generated on: Nov 06, 2025 — short-term TODO created by automation._

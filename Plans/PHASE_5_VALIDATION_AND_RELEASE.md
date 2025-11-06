# Phase 5 – Validation, Docs, and Release Prep

## Objective
Hardening pass that finalizes testing, documentation, security guidance, and release packaging so PaperWM is review-ready and easy to install.

## Entry Conditions
- Phases 1–4 complete with end-to-end IPC functionality working.
- Listener install flow and integration scripts are already in use by developers.

## Exit Criteria
- Unit and integration test suites cover critical paths; CI (macOS runner) runs them automatically and publishes artifacts on failure.
- Documentation (README, MANUAL_TEST_GUIDE, `Integration/IPC.md`) reflects real-world setup, testing, and troubleshooting steps.
- Security considerations documented (e.g., `Integration/SECURITY.md`), including socket permissions, health file handling, and threat mitigations.
- Release tooling (Makefile targets or scripts) produces build artifacts and a draft release checklist/notes.
- Reviewer checklist prepared for the PR, listing how to run the app, listener, and tests.

## Deliverables
- Expanded tests (unit/integration) ensuring coverage of DeskPad client error paths, listener failure recovery, and UI-level smoke checks.
- CI workflow updates (e.g., `.github/workflows/ci.yml`) adding macOS job executing build + tests + smoke script.
- Documentation updates across README, MANUAL_TEST_GUIDE.md, `Integration/IPC.md`, and new `Integration/SECURITY.md`.
- Release helper scripts or Makefile additions under `release/` or root Makefile.
- Draft release notes (e.g., `release/NOTES_v0.1.0-alpha.md`) capturing install instructions and highlights.

## Tasks (ordered)
1. Audit test coverage; add targeted unit tests for DeskPadClient error handling and listener edge cases.
2. Integrate smoke/integration scripts into CI, ensuring the macOS job can install the listener (possibly via launchd) and run the tests.
3. Document troubleshooting steps (e.g., stale socket, permission errors, launchd misconfigurations) in manual guide and README quickstart.
4. Produce security guidance covering socket permissions, per-user paths, and mitigation strategies for multi-user systems.
5. Add Makefile targets or shell scripts to build PaperWM, package listener assets, and bundle logs for reviewers.
6. Draft release notes and PR checklist summarizing validation performed and remaining risks.

## Validation Steps
- CI pipeline green with new macOS workflow; verify artifacts/logs uploaded on failure.
- Manual doc walkthrough by someone other than the implementer (spot-check instructions).
- Run release packaging script to ensure artifacts generate cleanly (ZIPs, tarballs, etc.).

## Risks & Notes
- Keep CI runtime manageable; use targeted integration tests to avoid long UI automation.
- Coordinate security review early if external stakeholders need to sign off on socket permissions or service behavior.

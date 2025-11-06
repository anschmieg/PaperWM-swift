# PaperWM Implementation Roadmap

## Status Snapshot
- Completed: `deskpadctl --socket-only` fast-path (4/16) ensures IPC parity with production listener.
- In progress: Preparing Phase 1 – lock down the IPC contract and ship a reusable socket helper with tests.
- Tracking: Use this file for the high-level roadmap; detailed checklists live under `Plans/`.

## Delivery Strategy
- Ship PaperWM in five phases, each producing reviewable artifacts and verification steps before unlocking the next phase.
- Keep prompts to automation narrow: one phase (or sub-phase) per AI engagement so validation feedback lands between milestones.
- Prefer incremental PRs that align with phase boundaries to simplify review and risk management.

## Phase Overview
| Phase | Focus | Primary outputs | Validation gates |
| --- | --- | --- | --- |
| 1 | IPC contract + socket helper | `Integration/IPC.md`, `Integration/SocketHelper/SocketHelper.swift`, helper tests | Doc review, `swift test Integration/SocketHelper` |
| 2 | Listener packaging & robustness | `Tools/deskpadctl/bin/install-listener.sh`, launchd plist template, socket hardening + health file | Manual install walkthrough, listener restart exercise |
| 3 | PaperWM scaffold | `Apps/PaperWM` project, minimal canvas, logging/config plumbing | App builds/runs, manual interaction checklist |
| 4 | DeskPad IPC integration | `DeskPadClient.swift`, UI wiring for create/list/remove, integration smoke script | Automated create/list/remove run against listener |
| 5 | Hardening, docs, release prep | Expanded tests, README/manual updates, security guidance, release tooling | CI macOS job green, docs walkthrough, release checklist |

## Phase Documents
- `Plans/PHASE_1_IPC_AND_SOCKET_HELPER.md`
- `Plans/PHASE_2_LISTENER_RUNTIME.md`
- `Plans/PHASE_3_APP_SCAFFOLD.md`
- `Plans/PHASE_4_APP_IPC_INTEGRATION.md`
- `Plans/PHASE_5_VALIDATION_AND_RELEASE.md`

Each phase doc enumerates entry conditions, ordered tasks, expected deliverables, and validation steps.

## Timeline Estimate (single engineer)
- Phase 1: ~1 day
- Phase 2: ~0.5–1 day
- Phase 3: ~1–2 days
- Phase 4: ~0.5–1 day
- Phase 5: ~0.5–1 day
- Total: ~4–6 working days assuming sequential execution with review cycles between phases.

## Next Action
Complete Phase 1: author the IPC contract doc, implement the socket helper, and land accompanying unit tests so downstream work can target a stable protocol.

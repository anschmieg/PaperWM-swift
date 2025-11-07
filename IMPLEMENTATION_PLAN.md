# Implementation Plan (minimal)

This short implementation plan captures the small set of design decisions and actionable items we lock in now for Phase 1 so later phases can proceed without re-negotiation. It deliberately avoids duplicating Phase 2+ operational packaging and app scaffolding details (see `Plans/` for those phases).

Key decisions (locked now)

- Socket location: prefer `$XDG_RUNTIME_DIR/paperwm/deskpad.sock`; fallback to `/tmp/deskpad_<uid>.sock`.
- Socket directory mode: `0700`; socket file mode: `0600` (per-user only).
- Authentication: verify peer UID via `SO_PEERCRED` / `getpeereid` on accept; reject differing UIDs. No shared-secret/HMAC by default.
- Protocol envelope (JSON):
  - Request: `{ "version":"1", "id":"<uuid>", "method":"create|list|remove|ping", "params":{...} }`
  - Response: `{ "version":"1", "id":"<uuid>", "status":"ok"|"error", "result":..., "error":{...} }`
- Timeouts: connect 200 ms, read 300 ms, default overall 1 s; CI/test override 2–3 s.
- Max response size: 1 MiB; larger payloads deferred to streaming/file-transfer plans.
- I/O semantics: client writes request then `shutdown(SHUT_WR)`; server reads until EOF then replies and closes.
- Fallback transport: keep macOS DistributedNotificationCenter + per-request reply-file fallback; use only when socket path is absent or fallback is explicitly requested.

What to implement now (Phase 1 scope)

- `Integration/IPC.md` – finalized protocol doc (already created in Phase 1).
- `Integration/SocketHelper` – async client helper exposing configurable timeouts, max size, and structured errors (already implemented in Phase 1).
- Deterministic tests: unit tests that start a temporary socket server and validate happy path, timeouts, and simple failure modes (already implemented in Phase 1).

What is intentionally deferred to later phases

- Listener packaging and `launchd` install script (Phase 2).
- Production listener runtime hardening beyond peer-credential checks (Phase 2).
- PaperWM app scaffold and UI bindings (Phase 3 & 4).
- CI macOS workflow and release packaging (Phase 5).

Testing & developer guidance

- Use `swift test --filter SocketHelperTests` inside `Integration/SocketHelper` to run the socket helper tests deterministically.
- For quick manual checks, use `Tools/deskpadctl --socket-only` against a running listener and `test-listener.swift` in `--no-socket` mode to validate reply-file fallback.

Notes

- Keep the SocketHelper public surface narrow and stable. If new transport needs arise (streaming, authenticated multi-user), introduce them behind versioned protocol changes.
- See `Plans/PHASE_1_IPC_AND_SOCKET_HELPER.md` and the other `Plans/PHASE_*.md` documents for the detailed phase-by-phase roadmap.

---
Generated: phase-1 decisions locked for immediate implementation.

## PaperWM Implementation Roadmap

## Status Snapshot

- Completed: `deskpadctl --socket-only` fast-path (4/16) ensures IPC parity with production listener.
- In progress: Preparing Phase 1 – lock down the IPC contract and ship a reusable socket helper with tests.
- Tracking: Use this file for the high-level roadmap; detailed checklists live under `Plans/`.

## Delivery Strategy

- Ship PaperWM in five phases, each producing reviewable artifacts and verification steps before unlocking the next phase.
- Keep prompts to automation narrow: one phase (or sub-phase) per AI engagement so validation feedback lands between milestones.
- Prefer incremental PRs that align with phase boundaries to simplify review and risk management.

## Phase Overview

| Phase | Focus                           | Primary outputs                                                                                    | Validation gates                                        |
| ----- | ------------------------------- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| 1     | IPC contract + socket helper    | `Integration/IPC.md`, `Integration/SocketHelper/SocketHelper.swift`, helper tests                  | Doc review, `swift test Integration/SocketHelper`       |
| 2     | Listener packaging & robustness | `Tools/deskpadctl/bin/install-listener.sh`, launchd plist template, socket hardening + health file | Manual install walkthrough, listener restart exercise   |
| 3     | PaperWM scaffold                | `Apps/PaperWM` project, minimal canvas, logging/config plumbing                                    | App builds/runs, manual interaction checklist           |
| 4     | DeskPad IPC integration         | `DeskPadClient.swift`, UI wiring for create/list/remove, integration smoke script                  | Automated create/list/remove run against listener       |
| 5     | Hardening, docs, release prep   | Expanded tests, README/manual updates, security guidance, release tooling                          | CI macOS job green, docs walkthrough, release checklist |

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

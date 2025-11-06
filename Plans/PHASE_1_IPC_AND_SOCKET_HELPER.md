# Phase 1 – IPC Contract & Socket Helper

## Objective
Define the DeskPad ↔︎ PaperWM socket contract and provide a reusable, well-tested Swift helper that exercises the contract. This phase locks protocol details so the rest of the work can build on a stable IPC foundation.

## Entry Conditions
- `deskpadctl` already supports `--socket-only` (completed 4/16).
- `test-listener.swift` is present and behaves as the current reference listener.
- Swift toolchain (5.9+) available locally for building and testing.

## Exit Criteria
- `Integration/IPC.md` documents request/response schemas, error codes, timeouts, and examples that match the implemented helper.
- `Integration/SocketHelper/SocketHelper.swift` exposes an async API for sending JSON over the Unix-domain socket with configurable timeouts.
- `swift test --filter SocketHelperTests` passes locally, covering success, timeout, and error scenarios.
- Pull request (or branch checkpoint) reviewed for docs + helper with validation notes.

## Deliverables
- `Integration/IPC.md` (new) with protocol details and examples.
- `Integration/SocketHelper/SocketHelper.swift` (new) describing async API surface and inline docs.
- `Integration/SocketHelper/Tests/SocketHelperTests.swift` (new) with coverage for happy path, connection failures, stale socket handling, and timeouts.
- Optional: lightweight README section linking to the IPC doc.

## Tasks (ordered)
1. Author `Integration/IPC.md` describing socket path, message schemas for create/list/remove, error format, and timeout expectations.
2. Align listener reference behavior (read/write semantics) with the document; file TODOs in the doc for any open questions.
3. Implement `SocketHelper` with async API that handles connect/send/read, shutdown of the write side, and JSON parsing with structured errors.
4. Build targeted unit tests using a temporary Unix socket server inside the test suite to simulate listener responses and failure modes.
5. Document the helper usage briefly in code comments and ensure public surface matches upcoming PaperWM needs.

## Validation Steps
- `swift test --filter SocketHelperTests` (expected to pass deterministically).
- Manual doc review to ensure IPC examples match listener behavior.
- Optional smoke check: run `deskpadctl --socket-only list` against the helper if a CLI harness exists.

## Risks & Notes
- Keep helper API narrow; future phases can extend but Phase 1 should resist scope creep (e.g., no batching or streaming yet).
- If the listener behavior diverges from the documented contract, capture deltas in `Integration/IPC.md` immediately to avoid drift.

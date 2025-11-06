# PaperWM-swift Manual Testing Guide

This guide reflects the current implementation (socket-first IPC, async/await `deskpadctl` subcommands, notification fallback with per-request reply channels and reply-file fallback). It explains how to run the automated smoke tests and how to test manually.

## Quick automated smoke test

The repository includes a focused IPC smoke test that starts the test listener, waits for the socket, and runs a series of CLI commands:

```bash
./Tests/ipc-smoke-test.sh
```

What it does:
- Starts the listener (background) — `test-listener.swift` logs to `/tmp/deskpad-listener.log`.
- Waits for `/tmp/deskpad.sock` to appear (up to a few seconds).
- Runs `deskpadctl create`, `deskpadctl list`, `deskpadctl remove` to exercise the socket fast-path and verify fallback behavior.

The smoke test is the most reliable way to exercise the socket fast-path and the notification/file fallback in a single run.

## How to build the CLI

```bash
cd Tools/deskpadctl
swift build -c release
# binary at: Tools/deskpadctl/.build/release/deskpadctl
```

## Manual testing (recommended sequence)

1. Start the listener

In one terminal run the listener and capture logs:

```bash
cd /Users/adrian/Projects/PaperWM-swift
# start in background, record pid and log
nohup swift test-listener.swift &>/tmp/deskpad-listener.log & echo $! >/tmp/deskpad-listener.pid
tail -f /tmp/deskpad-listener.log
```

The listener opens `/tmp/deskpad.sock` (Unix domain socket) and listens for distributed notifications.

1. Build and run simple CLI commands in another terminal

```bash
Tools/deskpadctl/.build/release/deskpadctl create --width 1280 --height 720 --name "IPC Test 1"
Tools/deskpadctl/.build/release/deskpadctl list
Tools/deskpadctl/.build/release/deskpadctl remove 1000
```

Notes:

- If the socket is present and listener is running, the CLI prefers the socket (fast path) and will return almost instantly.
- If the socket is unavailable, the CLI falls back to DistributedNotificationCenter and waits briefly for a response notification. It also writes/reads a per-request reply file under `/tmp/deskpad_response_<UUID>.json` as a robust fallback for headless/CI runs.

1. Validate listener logs

The listener log (`/tmp/deskpad-listener.log`) will show received payloads and posted responses. Example snippets:

```text
🔌 Unix socket server listening at /tmp/deskpad.sock
🔌 Socket received: {"command":"create","width":1280,...}
   Posting response: created display 1000
🔌 Socket received: {"command":"list"}
   Posting response: list (1 displays)
```

1. Run the smoke test

This runs the end-to-end scenario and prints timings and outputs:

```bash
./Tests/ipc-smoke-test.sh
```

## Testing the fallback (notifications + reply-file)

To exercise the notification path (simulate socket unavailable):

```bash
# stop the listener (if running)
if [ -f /tmp/deskpad-listener.pid ]; then kill "$(cat /tmp/deskpad-listener.pid)"; fi
# ensure socket absent
rm -f /tmp/deskpad.sock

# now run the list command (it will use notifications and reply-file fallback)
Tools/deskpadctl/.build/release/deskpadctl list
```

If you have another process integrated with DeskPad/DisplayControl it should receive the notification and either post a response notification or write the reply file. The CLI will quick-poll the reply-file for up to ~1s and then wait up to ~1s for a response notification.

## What to watch for (known gaps)

- The repository implements a socket-first fast-path and a robust notification+reply-file fallback. However:
  - There is currently no packaged system service (launchd plist) for the listener; developers run `test-listener.swift` manually. Consider adding a `launchd` template for production setups.
  - `deskpadctl` currently lacks explicit `--socket-only` / `--no-socket` flags; adding them makes CI deterministic and is recommended.
  - DisplayControl integration into the upstream DeskPad app still needs to be performed to get real virtual displays (integration docs are provided under `Integration/DeskPad/`).

## Troubleshooting

- If `deskpadctl` prints usage instead of executing a subcommand, ensure you built the binary and are running the correct binary (argument parser will show help if subcommands signatures are mismatched). Use the full path to the release binary.
- If you see no listener logs, confirm you started `test-listener.swift` in the background and that `/tmp/deskpad.sock` exists.
- On CI, prefer running `./Tests/ipc-smoke-test.sh` because it starts the listener and waits for the socket before exercising the CLI.

## Summary

Use `./Tests/ipc-smoke-test.sh` for a reliable automated exercise of both socket and notification paths. For manual debugging, run `test-listener.swift` and the release CLI binary as shown above and inspect `/tmp/deskpad-listener.log` and `/tmp/deskpad_response_<UUID>.json` for reply-file fallbacks.


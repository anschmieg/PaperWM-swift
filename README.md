# PaperWM-swift

Swift language implementation of PaperWM.spoon which attempts to make the window management snappier by using lower level APIs and a virtual display.

## Overview

PaperWM-swift provides a complete PaperWM-like canvas application for macOS, leveraging DeskPad (virtual CoreGraphics display) for high-performance window management. The implementation includes:

- **DeskPad integration** - Virtual display management using CoreGraphics
- **deskpadctl** - CLI tool for controlling virtual displays
- **Canvas scripts** - Helper scripts for arranging and panning the canvas
- **DisplayControl API** - Runtime control interface for DeskPad

## Components

### 1. DeskPad Submodule

DeskPad is integrated as a git submodule under `submodules/DeskPad`. It provides virtual display functionality using CoreGraphics.

**Integration files** for adding DisplayControl to DeskPad are provided in `Integration/DeskPad/`. These files are kept separate to avoid modifying the third-party DeskPad repository.

### 2. deskpadctl CLI

A Swift command-line tool for controlling DeskPad virtual displays via distributed notifications.

**Commands:**

- `deskpadctl create` - Create a new virtual display
- `deskpadctl remove <displayID>` - Remove a virtual display
- `deskpadctl list` - List all virtual displays

**Async/Await Architecture:**

- All subcommands use Swift's modern async/await concurrency model for non-blocking operations
- The List command uses continuations to wait asynchronously for distributed notification responses
- File polling uses `Task.sleep` instead of blocking sleep for better concurrency performance
- Requires Swift 5.9+ with ArgumentParser 1.2.0+ for async command support

#### IPC behavior (socket-first)

---------------------------

- For interactive/local workflows the CLI now prefers a Unix domain socket at `/tmp/deskpad.sock` for low-latency, synchronous RPC.
- If the socket is unavailable the CLI falls back to the original macOS `DistributedNotificationCenter` path. When using notifications the CLI also supports a per-request `replyFile` fallback written under `/tmp/deskpad_response_<UUID>.json` so CI and backgrounded listeners can still respond deterministically.
- Listener logs (useful for debugging) are written to `/tmp/deskpad-listener.log` when running the provided `test-listener.swift` helper.

Quick notes:

- Use the included smoke test to exercise the socket path and fallbacks: `./Tests/ipc-smoke-test.sh`.
- For CI or scripts that must fail fast if the socket is not present, prefer adding a wrapper to check `/tmp/deskpad.sock` before invoking `deskpadctl` or run `deskpadctl` with the `--no-socket`/`--socket-only` flags if you add them.

**Example:**

```bash
# Create a 1920x1080 display
deskpadctl create --width 1920 --height 1080 --name "My Display"

# Remove a display
deskpadctl remove 1234

# List displays
deskpadctl list
```

### 3. Canvas Scripts

Helper scripts for arranging and panning the virtual canvas:

- `Scripts/arrange-canvas.sh` - Arrange windows on the canvas
- `Scripts/pan-canvas.sh` - Pan the canvas view

### 4. DisplayControl Component

A minimal integration layer added to DeskPad that listens for distributed notifications and manages virtual display lifecycle.

## Building

```bash
# Initialize submodules
make submodule-update

# Build all tools
make build

# Run tests
make test

# Install to /usr/local/bin
make install
```

## Requirements

- macOS 10.15 or later
- Swift 5.9 or later
- Xcode command-line tools

## Quick Start

1. **Clone the repository with submodules:**

   ```bash
   git clone --recursive https://github.com/anschmieg/PaperWM-swift.git
   cd PaperWM-swift
   ```

2. **Build the tools:**

   ```bash
   make build
   ```

3. **Run tests:**

   ```bash
   make test
   ./Tests/integration-test.sh
   ./Tests/e2e-smoke-test.sh
   ```

4. **Optional: Integrate DisplayControl with DeskPad:**

   ```bash
   # Copy integration files
   cp Integration/DeskPad/DisplayControl.swift submodules/DeskPad/DeskPad/
   
   # Follow instructions in Integration/DeskPad/README.md
   ```

5. **Use deskpadctl:**

   ```bash
   # Create a virtual display
   Tools/deskpadctl/.build/release/deskpadctl create --width 1920 --height 1080
   ```

## DeskPad Listener Service

The DeskPad listener runs as a background service and handles display control requests via both Unix domain sockets (for low-latency local IPC) and distributed notifications (for compatibility).

### Installing the Listener

The listener can be installed as a launchd service that runs automatically:

```bash
# Install and start the listener service
Tools/deskpadctl/bin/install-listener.sh install

# Check status
Tools/deskpadctl/bin/install-listener.sh status

# Stop the service
Tools/deskpadctl/bin/install-listener.sh stop

# Start the service
Tools/deskpadctl/bin/install-listener.sh start

# Uninstall the service
Tools/deskpadctl/bin/install-listener.sh uninstall
```

The installation script:
- Copies a launchd plist to `~/Library/LaunchAgents/`
- Configures the listener to run automatically at login
- Sets up logging and health monitoring
- Cleans up stale socket and health files

### Listener Paths

By default, the listener uses these paths:
- **Socket**: `/tmp/deskpad.sock` (0600 permissions, owner-only access)
- **Log**: `/tmp/deskpad-listener.log`
- **Health file**: `/tmp/deskpad-listener.health` (contains PID and timestamp)

These paths can be customized via environment variables:
- `DESKPAD_SOCKET_PATH`
- `DESKPAD_LOG_PATH`
- `DESKPAD_HEALTH_PATH`

### Manual Testing

For development and debugging, you can run the listener manually:

```bash
# Run listener in foreground
swift test-listener.swift

# Run in notification-only mode (disable socket)
swift test-listener.swift --no-socket
```

See [MANUAL_TEST_GUIDE.md](MANUAL_TEST_GUIDE.md) for detailed testing instructions and [Integration/IPC.md](Integration/IPC.md) for the complete IPC protocol specification.


## Development

### Repository Structure

```bash
PaperWM-swift/
├── submodules/
│   └── DeskPad/              # DeskPad submodule
├── Integration/
│   └── DeskPad/              # DisplayControl integration files
│       ├── DisplayControl.swift
│       ├── DISPLAYCONTROL_INTEGRATION.md
│       └── README.md
├── Tools/
│   └── deskpadctl/           # deskpadctl CLI tool
├── Scripts/
│   ├── arrange-canvas.sh     # Canvas arrangement script
│   └── pan-canvas.sh         # Canvas panning script
├── Tests/                    # Test suites
│   ├── integration-test.sh
│   └── e2e-smoke-test.sh
├── Makefile                  # Build configuration
└── .github/
    └── workflows/
        └── ci.yml            # CI/CD configuration
```

### Running Tests

```bash
cd Tools/deskpadctl
swift test
```

### Building deskpadctl

```bash
cd Tools/deskpadctl
swift build -c release
```

The binary will be available at `Tools/deskpadctl/.build/release/deskpadctl`.

## CI/CD

GitHub Actions automatically builds and tests the project on every push and pull request. See `.github/workflows/ci.yml` for details.

## License

This project integrates with DeskPad, which has its own license. Please see the DeskPad submodule for its licensing terms.

## Roadmap & TODO

See the phase plans under the `Plans/` directory for a phased implementation breakdown (Phase 1..5). A consolidated project TODO also lives at `TODO.md` in the repository root. For a short, developer-focused implementation plan and the key design decisions locked for the IPC work, see `IMPLEMENTATION_PLAN.md` (added as part of Phase 1).

The `Plans/` documents contain phased checklists and expectations. Avoid duplicating implementation details in this README; use `IMPLEMENTATION_PLAN.md` for the minimal decisions and quick start notes relevant to current development.

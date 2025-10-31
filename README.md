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

### 2. deskpadctl CLI
A Swift command-line tool for controlling DeskPad virtual displays via distributed notifications.

**Commands:**
- `deskpadctl create` - Create a new virtual display
- `deskpadctl remove <displayID>` - Remove a virtual display
- `deskpadctl list` - List all virtual displays

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

## Development

### Repository Structure
```
PaperWM-swift/
├── submodules/
│   └── DeskPad/              # DeskPad submodule
├── Tools/
│   └── deskpadctl/           # deskpadctl CLI tool
├── Scripts/
│   ├── arrange-canvas.sh     # Canvas arrangement script
│   └── pan-canvas.sh         # Canvas panning script
├── Tests/                    # Test suites
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

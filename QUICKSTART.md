# Quick Start Guide

This guide will help you get started with PaperWM-swift and DeskPad integration.

## Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- Git

## Installation

### 1. Clone the Repository

```bash
git clone --recursive https://github.com/anschmieg/PaperWM-swift.git
cd PaperWM-swift
```

If you already cloned without `--recursive`:

```bash
git submodule update --init --recursive
```

### 2. Add DeskPad Submodule

You'll need the URL of the DeskPad repository. Once you have it:

```bash
./scripts/add-deskpad-submodule.sh <DESKPAD_REPO_URL>
```

For example:
```bash
./scripts/add-deskpad-submodule.sh https://github.com/example/DeskPad.git
```

Or manually:
```bash
rm -rf submodules/DeskPad  # Remove placeholder
git submodule add <DESKPAD_REPO_URL> submodules/DeskPad
git submodule update --init
```

### 3. Build the Project

```bash
# Using Make
make build

# Or using Swift directly
swift build
```

### 4. Run Tests

```bash
# Using Make
make test

# Or using Swift directly
swift test
```

### 5. Install deskpadctl (Optional)

To install the CLI tool system-wide:

```bash
make install
```

This will copy `deskpadctl` to `/usr/local/bin/` (requires sudo).

## Using deskpadctl

Once installed (or using `.build/debug/deskpadctl`):

### Create a Virtual Display

```bash
deskpadctl create 1920 1080
```

This creates a 1920x1080 virtual display.

### List Virtual Displays

```bash
deskpadctl list
```

### Remove a Virtual Display

```bash
deskpadctl remove <display-id>
```

Example:
```bash
deskpadctl remove 1
```

## Integrating with DeskPad

### 1. Review the Integration Guide

Read `Sources/PaperWM/INTEGRATION.md` for detailed integration instructions.

### 2. Copy DisplayControlHook to DeskPad

Copy the hook into your DeskPad project:

```bash
cp Sources/PaperWM/DisplayControlHook.swift submodules/DeskPad/Sources/DeskPad/
```

### 3. Initialize the Hook in DeskPad

See `Sources/PaperWM/DeskPadAppExample.swift` for an example of how to initialize the hook in your DeskPad application.

### 4. Connect to DeskPad API

Replace the placeholder API calls in `DisplayControlHook.swift` with actual DeskPad virtual display API calls.

## Development

### Build for Release

```bash
make release
```

### Clean Build Artifacts

```bash
make clean
```

### Format Code (if swift-format is installed)

```bash
make format
```

## Troubleshooting

### Build Errors

- Make sure you're on macOS (the project uses macOS-specific APIs)
- Ensure Swift 5.9 or later is installed: `swift --version`
- Try cleaning and rebuilding: `make clean && make build`

### Submodule Issues

If the DeskPad submodule is empty or not initialized:

```bash
git submodule update --init --recursive
```

### CLI Tool Not Working

The `deskpadctl` tool requires DeskPad to be running with the DisplayControlHook integrated and listening for commands.

## Next Steps

1. Integrate DisplayControlHook into DeskPad
2. Build and run DeskPad
3. Test the CLI tool with DeskPad running
4. Explore the notification protocol for custom integrations

## Getting Help

- Check the main README.md for more details
- Review INTEGRATION.md for DeskPad integration specifics
- See SUBMODULE_SETUP.md for submodule management

## License

See LICENSE file for details.

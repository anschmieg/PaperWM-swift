# PaperWM-swift

Swift language implementation of PaperWM.spoon which attempts to make the window management snappier by using lower level APIs and a virtual display.

## Overview

This project provides a complete PaperWM-like canvas application for macOS, integrating with DeskPad for virtual display management. It includes:

1. **DeskPad Submodule**: Virtual display creation and management framework
2. **DisplayControl Hook**: Integration layer for controlling DeskPad via notifications
3. **deskpadctl CLI**: Command-line tool for managing virtual displays

## Architecture

```
PaperWM-swift/
├── Sources/
│   ├── PaperWM/
│   │   ├── DisplayControlHook.swift    # Notification listener for DeskPad
│   │   └── INTEGRATION.md              # Integration guide
│   └── deskpadctl/
│       └── main.swift                  # CLI tool for sending commands
├── submodules/
│   └── DeskPad/                        # DeskPad submodule (to be added)
└── Tools/                              # Built executables
```

## Features

### DisplayControl Hook

The DisplayControl hook integrates with DeskPad to provide:

- **Distributed Notification Listening**: Receives commands via macOS Distributed Notification Center
- **Command Processing**: Handles create, remove, and list operations
- **Response Notifications**: Sends success/failure responses back to callers
- **Logging**: Comprehensive logging of all operations

### deskpadctl CLI

A command-line interface for controlling DeskPad:

```bash
# Create a virtual display
deskpadctl create 1920 1080

# Remove a virtual display
deskpadctl remove <display-id>

# List all virtual displays
deskpadctl list
```

## Getting Started

### Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- Xcode 15.0 or later (for development)

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/anschmieg/PaperWM-swift.git
   cd PaperWM-swift
   ```

2. **Add DeskPad submodule**:
   
   See `SUBMODULE_SETUP.md` for detailed instructions on adding DeskPad as a submodule.

3. **Build the project**:
   ```bash
   swift build
   ```

4. **Run tests**:
   ```bash
   swift test
   ```

### Integration with DeskPad

To integrate the DisplayControl hook into DeskPad:

1. Follow the instructions in `Sources/PaperWM/INTEGRATION.md`
2. Copy `DisplayControlHook.swift` into your DeskPad project
3. Initialize the hook in DeskPad's application lifecycle
4. Replace placeholder API calls with actual DeskPad API calls

## Usage

### Using deskpadctl

After building, the `deskpadctl` executable can be found in `.build/debug/deskpadctl` or `.build/release/deskpadctl`.

```bash
# Create a 1920x1080 virtual display
.build/debug/deskpadctl create 1920 1080

# List all displays
.build/debug/deskpadctl list

# Remove display with ID 1
.build/debug/deskpadctl remove 1
```

### Notification Protocol

The system uses macOS Distributed Notifications for inter-process communication:

**Command Notification**: `com.deskpad.control`
```json
{
  "action": "create",
  "width": 1920,
  "height": 1080
}
```

**Response Notification**: `com.deskpad.control.response`
```json
{
  "success": true,
  "message": "Virtual display created successfully",
  "data": {
    "displayId": 123,
    "width": 1920,
    "height": 1080
  }
}
```

## Development

### Project Structure

- `Sources/PaperWM/`: Core library with DisplayControl hook
- `Sources/deskpadctl/`: CLI tool source code
- `Tests/PaperWMTests/`: Test suite
- `submodules/`: Git submodules (DeskPad)

### Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run tests
swift test
```

### Testing

The project includes comprehensive tests for the DisplayControl hook:

```bash
swift test
```

Tests cover:
- Starting and stopping the notification listener
- Create display commands
- Remove display commands
- List display commands
- Invalid command handling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests to ensure everything works
5. Submit a pull request

## License

See LICENSE file for details.

## Acknowledgments

- Inspired by PaperWM.spoon
- Built with DeskPad virtual display framework 

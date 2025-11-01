# DisplayControl Integration Guide

## Overview

DisplayControl is a minimal component added to DeskPad that listens for distributed notifications from external CLI tools (like `deskpadctl`) and manages virtual display lifecycle operations.

## Architecture

```
┌─────────────┐                  ┌──────────────────┐
│ deskpadctl  │  Distributed     │    DeskPad       │
│    CLI      │  Notifications   │  Application     │
│             ├─────────────────>│                  │
│             │                  │ ┌──────────────┐ │
│             │                  │ │DisplayControl│ │
│             │                  │ │   Listener   │ │
│             │<─────────────────┤ └──────────────┘ │
│             │   Response       │        │         │
└─────────────┘  Notifications   │        ▼         │
                                 │  CGVirtualDisplay│
                                 │      API         │
                                 └──────────────────┘
```

## Integration Steps

### 1. Add DisplayControl to DeskPad

The `DisplayControl.swift` file has been added to `submodules/DeskPad/DeskPad/` directory.

To integrate it into the DeskPad application:

1. Open `DeskPad.xcodeproj` in Xcode
2. Add `DisplayControl.swift` to the DeskPad target
3. In `AppDelegate.swift`, initialize DisplayControl:

```swift
func applicationDidFinishLaunching(_: Notification) {
    // ... existing code ...
    
    // Initialize DisplayControl
    _ = DisplayControl.shared
    
    // ... rest of existing code ...
}
```

### 2. Modify DisplayControl for Production Use

The current implementation uses simulated display creation. To integrate with actual DeskPad virtual display API:

1. Replace the `createVirtualDisplay` method to use DeskPad's existing virtual display creation code
2. Replace the `removeVirtualDisplay` method to properly clean up displays
3. Update the display tracking to work with DeskPad's internal state management

Example integration with existing DeskPad code:

```swift
private func createVirtualDisplay(
    name: String,
    width: Int,
    height: Int,
    refreshRate: Double
) -> UInt32 {
    let descriptor = CGVirtualDisplayDescriptor()
    descriptor.setDispatchQueue(DispatchQueue.main)
    descriptor.name = name
    descriptor.maxPixelsWide = UInt32(width)
    descriptor.maxPixelsHigh = UInt32(height)
    // ... configure other properties ...
    
    let display = CGVirtualDisplay(descriptor: descriptor)
    
    let settings = CGVirtualDisplaySettings()
    settings.hiDPI = 1
    settings.modes = [
        CGVirtualDisplayMode(width: UInt32(width), height: UInt32(height), refreshRate: refreshRate)
    ]
    display.apply(settings)
    
    return display.displayID
}
```

## Communication Protocol

### Request Format

All requests are sent via `DistributedNotificationCenter` with the notification name `com.deskpad.displaycontrol`.

The notification's `userInfo` contains:
```json
{
  "payload": "{\"command\":\"create\",\"width\":1920,\"height\":1080,\"refreshRate\":60.0,\"name\":\"Display\"}"
}
```

### Commands

#### Create Display
```json
{
  "command": "create",
  "width": 1920,
  "height": 1080,
  "refreshRate": 60.0,
  "name": "DeskPad Display"
}
```

#### Remove Display
```json
{
  "command": "remove",
  "displayID": 1234
}
```

#### List Displays
```json
{
  "command": "list"
}
```

### Response Format

Responses are posted to `com.deskpad.displaycontrol.response` notification.

Success response:
```json
{
  "status": "success",
  "data": {
    "displayID": 1234,
    "name": "DeskPad Display",
    "width": 1920,
    "height": 1080,
    "refreshRate": 60.0
  }
}
```

Error response:
```json
{
  "status": "error",
  "message": "Failed to create virtual display"
}
```

## Security Considerations

1. **Input Validation**: All incoming parameters are validated before use
2. **Resource Limits**: Consider limiting the number of virtual displays that can be created
3. **Permission Checks**: Ensure only authorized processes can send control commands
4. **Error Handling**: All errors are caught and returned as error responses

## Testing

The DisplayControl component can be tested using:

1. **Unit Tests**: Test JSON serialization/deserialization
2. **Integration Tests**: Test notification sending/receiving
3. **E2E Tests**: Test complete workflow with actual DeskPad

Example test:
```bash
# Send create command
deskpadctl create --width 1920 --height 1080

# Verify display was created (check logs or use list command)
deskpadctl list
```

## Logging

DisplayControl uses `NSLog` for logging. All operations are logged with the prefix "DisplayControl:".

Example log output:
```
DisplayControl: Simulated creation of display 'My Display' (1920x1080@60.0Hz) with ID 1234
DisplayControl Response: {
  "status" : "success",
  "data" : {
    "displayID" : 1234,
    "name" : "My Display",
    ...
  }
}
```

## Minimal Changes Philosophy

The DisplayControl component is designed to be:

- **Self-contained**: Single file that can be easily added/removed
- **Non-invasive**: Doesn't modify DeskPad's core functionality
- **Well-documented**: Clear comments explaining integration points
- **Safe**: Error handling prevents crashes or undefined behavior

This ensures that the DeskPad submodule can be updated without conflicts, and the integration can be easily maintained.

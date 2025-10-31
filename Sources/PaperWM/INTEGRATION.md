# DisplayControl Hook Integration Guide

This guide explains how to integrate the DisplayControl hook into the DeskPad application.

## Overview

The DisplayControl hook provides a mechanism for external tools to control DeskPad's virtual display functionality via macOS Distributed Notifications. This allows command-line tools and other applications to create, remove, and list virtual displays.

## Integration Steps

### 1. Add DisplayControlHook to DeskPad

Copy the `DisplayControlHook.swift` file into your DeskPad project:

```
DeskPad/
  ├── Sources/
  │   └── DeskPad/
  │       └── DisplayControlHook.swift
```

### 2. Initialize the Hook in DeskPad

In your DeskPad application's main app delegate or initialization code, start the DisplayControl hook:

```swift
import Foundation

@main
struct DeskPadApp: App {
    init() {
        // Start listening for control commands
        DisplayControlHook.shared.startListening()
    }
    
    var body: some Scene {
        // Your app UI here
    }
}
```

### 3. Connect to DeskPad API

Replace the placeholder API calls in `DisplayControlHook.swift` with actual DeskPad API calls:

```swift
// In handleCreateDisplay:
let displayId = DeskPad.createVirtualDisplay(width: width, height: height)

// In handleRemoveDisplay:
DeskPad.removeVirtualDisplay(displayId: displayId)

// In handleListDisplays:
let displays = DeskPad.listVirtualDisplays()
```

### 4. Error Handling

Ensure proper error handling for DeskPad API calls:

```swift
do {
    let displayId = try DeskPad.createVirtualDisplay(width: width, height: height)
    sendResponse(success: true, message: "Display created", data: ["displayId": displayId])
} catch {
    sendResponse(success: false, message: "Failed to create display: \(error)")
}
```

## Notification Protocol

### Command Notification

- **Name**: `com.deskpad.control`
- **UserInfo**: `{ "command": "<JSON string>" }`

### Response Notification

- **Name**: `com.deskpad.control.response`
- **UserInfo**: `{ "response": "<JSON string>" }`

### Ready Notification

- **Name**: `com.deskpad.control.ready`
- **UserInfo**: `{ "status": "ready" }`

## Command Format

### Create Display
```json
{
  "action": "create",
  "width": 1920,
  "height": 1080
}
```

### Remove Display
```json
{
  "action": "remove",
  "displayId": 123
}
```

### List Displays
```json
{
  "action": "list"
}
```

## Response Format

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

## Testing

You can test the integration using the `deskpadctl` command-line tool:

```bash
# Create a virtual display
deskpadctl create 1920 1080

# List displays
deskpadctl list

# Remove a display
deskpadctl remove 123
```

## Cleanup

Don't forget to stop listening when the app terminates:

```swift
deinit {
    DisplayControlHook.shared.stopListening()
}
```

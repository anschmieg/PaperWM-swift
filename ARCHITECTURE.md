# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         macOS System                             │
│                                                                  │
│  ┌─────────────────┐         ┌──────────────────────────────┐  │
│  │                 │         │                              │  │
│  │   deskpadctl    │         │      DeskPad Application     │  │
│  │   (CLI Tool)    │         │   (with DisplayControlHook)  │  │
│  │                 │         │                              │  │
│  └────────┬────────┘         └──────────┬───────────────────┘  │
│           │                              │                       │
│           │  Send Commands               │  Listen for Commands │
│           │  (JSON via                   │  (JSON via           │
│           │   DistributedNotification)   │   DistributedNotif.) │
│           │                              │                       │
│           ▼                              ▼                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                                                           │  │
│  │      macOS Distributed Notification Center               │  │
│  │                                                           │  │
│  │  Notifications:                                           │  │
│  │  • com.deskpad.control        (commands)                 │  │
│  │  • com.deskpad.control.response (responses)              │  │
│  │  • com.deskpad.control.ready   (ready signal)            │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│                              ▲                                   │
│                              │                                   │
│                              │ Responses                         │
│                              │                                   │
│                    ┌─────────┴─────────┐                        │
│                    │                   │                         │
│              deskpadctl         DisplayControlHook              │
│              (receives)            (sends)                       │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. deskpadctl (CLI Tool)

**Responsibilities:**
- Parse command-line arguments
- Validate input (width, height, display ID)
- Construct JSON commands
- Send commands via Distributed Notification Center
- Display user-friendly messages

**Commands:**
```bash
deskpadctl create <width> <height>
deskpadctl remove <display-id>
deskpadctl list
```

**Output:**
- Command sent confirmation
- Error messages for invalid input

### 2. DisplayControlHook

**Responsibilities:**
- Listen for commands on `com.deskpad.control` notification
- Parse and validate JSON commands
- Call DeskPad virtual display API
- Send responses on `com.deskpad.control.response` notification
- Log all operations

**Lifecycle:**
```
Application Start
    ↓
Initialize DisplayControlHook.shared
    ↓
Call startListening()
    ↓
[Hook is active and listening]
    ↓
Receive Notifications → Process Commands → Send Responses
    ↓
Application Terminate
    ↓
Call stopListening()
```

### 3. Distributed Notification Center

**Built-in macOS service** that enables inter-process communication.

**Features:**
- System-wide notifications (across different applications)
- Fire-and-forget messaging
- No direct connection required between sender and receiver

## Data Flow

### Create Display Flow

```
User                deskpadctl           NotificationCenter        DisplayControlHook      DeskPad API
 │                      │                        │                        │                    │
 │ create 1920 1080     │                        │                        │                    │
 ├─────────────────────>│                        │                        │                    │
 │                      │                        │                        │                    │
 │                      │ Build JSON Command     │                        │                    │
 │                      │ {                      │                        │                    │
 │                      │   "action": "create",  │                        │                    │
 │                      │   "width": 1920,       │                        │                    │
 │                      │   "height": 1080       │                        │                    │
 │                      │ }                      │                        │                    │
 │                      │                        │                        │                    │
 │                      │ Post Notification      │                        │                    │
 │                      │ (com.deskpad.control)  │                        │                    │
 │                      ├───────────────────────>│                        │                    │
 │                      │                        │                        │                    │
 │                      │                        │ Deliver Notification   │                    │
 │                      │                        ├───────────────────────>│                    │
 │                      │                        │                        │                    │
 │                      │                        │                        │ Parse JSON         │
 │                      │                        │                        │ Validate Command   │
 │                      │                        │                        │                    │
 │                      │                        │                        │ Create Display     │
 │                      │                        │                        ├───────────────────>│
 │                      │                        │                        │                    │
 │                      │                        │                        │   Display ID       │
 │                      │                        │                        │<───────────────────┤
 │                      │                        │                        │                    │
 │                      │                        │                        │ Build Response     │
 │                      │                        │                        │ {                  │
 │                      │                        │                        │   "success": true, │
 │                      │                        │                        │   "displayId": 123 │
 │                      │                        │                        │ }                  │
 │                      │                        │                        │                    │
 │                      │                        │   Post Response        │                    │
 │                      │                        │<───────────────────────┤                    │
 │                      │                        │                        │                    │
 │                      │    (Optional: Listen   │                        │                    │
 │                      │     for response)      │                        │                    │
 │                      │<───────────────────────┤                        │                    │
 │                      │                        │                        │                    │
 │  Display message     │                        │                        │                    │
 │<─────────────────────┤                        │                        │                    │
 │                      │                        │                        │                    │
```

## Integration Points

### 1. DeskPad Application Integration

**File to modify:** DeskPad's App delegate or main app file

**Code to add:**
```swift
import Foundation

@main
struct DeskPadApp: App {
    init() {
        // Start listening for control commands
        DisplayControlHook.shared.startListening()
    }
    
    var body: some Scene {
        // Your app UI
    }
}
```

### 2. API Integration Points

In `DisplayControlHook.swift`, replace these placeholder sections:

**Create Display:**
```swift
// Current: Simulated
let displayId = Int.random(in: 1...1000)

// Replace with:
let displayId = try DeskPad.createVirtualDisplay(width: width, height: height)
```

**Remove Display:**
```swift
// Current: Simulated
print("Display removed")

// Replace with:
try DeskPad.removeVirtualDisplay(displayId: displayId)
```

**List Displays:**
```swift
// Current: Simulated
let displays = [...]

// Replace with:
let displays = DeskPad.listVirtualDisplays()
```

## Error Handling

### Command Validation Errors
- Missing required fields (width, height, displayId)
- Invalid data types
- Unknown actions

### API Errors
- Display creation failed
- Display not found for removal
- Permission issues

### Response Format
```json
{
  "success": false,
  "message": "Error description here",
  "data": {
    // Optional error details
  }
}
```

## Security Considerations

1. **No Authentication**: Current implementation has no authentication. Consider adding:
   - API keys
   - Process ID validation
   - User permission checks

2. **Input Validation**: All inputs are validated before processing

3. **Sandboxing**: macOS sandboxing may restrict notification access - ensure proper entitlements

## Performance

- **Asynchronous**: All notifications are handled asynchronously
- **Non-blocking**: Command processing doesn't block the main thread
- **Efficient**: JSON parsing is done once per command

## Testing Strategy

1. **Unit Tests**: Test individual components (✅ Implemented)
2. **Integration Tests**: Test full command flow (requires macOS)
3. **Manual Testing**: Use deskpadctl with running DeskPad app

## Deployment

1. Build release version: `make release`
2. Install CLI tool: `make install`
3. Integrate hook into DeskPad
4. Build and distribute DeskPad with integrated hook

## Troubleshooting

### Commands not received
- Ensure DeskPad is running
- Verify DisplayControlHook is initialized
- Check macOS notification permissions

### Invalid responses
- Verify JSON format
- Check notification names match
- Review console logs

### Build errors
- Ensure macOS 13.0+
- Verify Swift 5.9+
- Check platform guards are in place

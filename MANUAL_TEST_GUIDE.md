# PaperWM-swift Manual Testing Guide

## Quick Test (Automated)

Run the comprehensive test script:

```bash
./manual-test.sh
```

This tests all functionality automatically and shows:
- ✅ CLI help and version
- ✅ Create, list, and remove commands
- ✅ Canvas scripts
- ✅ Integration components

## Detailed Manual Testing

### 1. Test CLI Help System

```bash
# Main help
./Tools/deskpadctl/.build/release/deskpadctl --help

# Subcommand help
./Tools/deskpadctl/.build/release/deskpadctl create --help
./Tools/deskpadctl/.build/release/deskpadctl remove --help
./Tools/deskpadctl/.build/release/deskpadctl list --help
```

**Expected:** Clean help output with all options documented

### 2. Test Version

```bash
./Tools/deskpadctl/.build/release/deskpadctl --version
```

**Expected:** `1.0.0`

### 3. Test Create Command

```bash
# With defaults
./Tools/deskpadctl/.build/release/deskpadctl create

# With custom parameters
./Tools/deskpadctl/.build/release/deskpadctl create \
  --width 2560 \
  --height 1440 \
  --refresh-rate 60.0 \
  --name "My Canvas"
```

**Expected:** 
```
✓ Create command sent successfully
  Display: My Canvas
  Resolution: 2560x1440@60.0Hz
```

**What happens:** Sends a distributed notification with JSON payload:
```json
{
  "command": "create",
  "width": 2560,
  "height": 1440,
  "refreshRate": 60.0,
  "name": "My Canvas"
}
```

### 4. Test List Command

```bash
./Tools/deskpadctl/.build/release/deskpadctl list
```

**Expected:**
```
✓ List command sent successfully
  Waiting for response from DeskPad...
```

**Notes about IPC:**
- The CLI prefers a Unix domain socket at `/tmp/deskpad.sock` for fast, synchronous responses. If the socket is present and a listener opened it, the `list` command will return immediately with the displays. If the socket is not present the CLI falls back to distributed notifications and will wait briefly for a response — this is normal when starting the listener concurrently.
- You can check the socket and listener logs in another terminal:

```bash
ls -l /tmp/deskpad.sock
tail -f /tmp/deskpad-listener.log
```

Use the helper smoke test to exercise socket and fallback behavior:

```bash
./Tests/ipc-smoke-test.sh
```

### 5. Test Remove Command

```bash
./Tools/deskpadctl/.build/release/deskpadctl remove 1234
```

**Expected:**
```
✓ Remove command sent successfully
  Display ID: 1234
```

### 6. Test Canvas Scripts

```bash
# Arrange canvas help
./Scripts/arrange-canvas.sh --help

# Pan canvas help
./Scripts/pan-canvas.sh --help

# Example usage (won't work without yabai/windows)
./Scripts/arrange-canvas.sh --canvas-width 3840 --window-width 1920
./Scripts/pan-canvas.sh --step 500 right
```

**Expected:** Help output showing all options and examples

### 7. Verify Integration Files

```bash
ls -lh Integration/DeskPad/
```

**Expected:**
```
DISPLAYCONTROL_INTEGRATION.md  (5.6K) - Integration guide
DisplayControl.swift           (6.8K) - Swift component
README.md                      (1.8K) - Quick reference
```

### 8. Test Notification Flow (Advanced)

To see the full notification flow, you need two terminals:

**Terminal 1 - Start Listener:**
```bash
swift test-listener.swift
```

**Terminal 2 - Send Commands:**
```bash
./Tools/deskpadctl/.build/release/deskpadctl create --width 1920 --height 1080
./Tools/deskpadctl/.build/release/deskpadctl list
./Tools/deskpadctl/.build/release/deskpadctl remove 1234
```

**Expected in Terminal 1:**
```
🎧 Starting notification listener...
Listening for: com.deskpad.displaycontrol
Press Ctrl+C to stop

✅ Listener ready. Run deskpadctl commands in another terminal.

📨 Received notification!
   Payload: {"command":"create","width":1920,"height":1080,...}
   Parsed:
     - command: create
     - width: 1920
     - height: 1080
     ...
```

## Integration with DeskPad

To integrate DisplayControl with the actual DeskPad app:

1. Copy `Integration/DeskPad/DisplayControl.swift` to DeskPad project
2. Follow instructions in `Integration/DeskPad/README.md`
3. Initialize in DeskPad's AppDelegate:
   ```swift
   func applicationDidFinishLaunching(_: Notification) {
       _ = DisplayControl.shared  // Start listening
   }
   ```

## Test Results Summary

All tests should show:
- ✅ CLI commands execute without errors
- ✅ Help text is clear and complete
- ✅ Notifications are sent (visible with listener)
- ✅ Scripts are executable and show help
- ✅ Integration files are present

## Notes

- **Notifications:** Commands send macOS distributed notifications. Without DeskPad running with DisplayControl integrated, notifications are sent but not received.
- **Canvas Scripts:** Require `yabai` window manager to actually move windows. Scripts will show help without yabai.
- **Virtual Displays:** Actual display creation requires DeskPad app with DisplayControl integrated.

## Troubleshooting

**Command not found:**
```bash
# Use full path or add to PATH
export PATH="$PATH:$(pwd)/Tools/deskpadctl/.build/release"
```

**Permission denied:**
```bash
chmod +x Scripts/*.sh
chmod +x test-listener.swift
```

**Build not found:**
```bash
make build
```

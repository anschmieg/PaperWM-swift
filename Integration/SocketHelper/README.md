# SocketHelper

A Swift library for communicating with Unix domain socket servers using an async JSON-based protocol.

## Overview

SocketHelper provides a simple, robust async API for sending JSON requests to a Unix domain socket server and receiving JSON responses. It was designed for the DeskPad ↔ PaperWM IPC protocol but can be used with any JSON-based socket communication.

## Features

- **Async/Await API**: Non-blocking operations using Swift concurrency
- **Configurable Timeouts**: Separate connect and read timeouts
- **Structured Errors**: Clear error types for connection, timeout, and data issues
- **Half-Close Protocol**: Properly implements shutdown(SHUT_WR) for request boundaries
- **Cross-Platform**: Works on macOS and Linux
- **Well-Tested**: Comprehensive test suite with 13 test cases

## Installation

This package is designed to be used as a local Swift package. Add it to your `Package.swift`:

```swift
dependencies: [
    .package(path: "Integration/SocketHelper")
]
```

## Usage

### Basic Example

```swift
import SocketHelper

let helper = SocketHelper()
let request = ["command": "list"]

do {
    let response = try await helper.sendRequest(request)
    print("Response: \(response)")
} catch SocketError.connectTimeout {
    print("Connection timed out - is the server running?")
} catch SocketError.connectionRefused {
    print("Connection refused - server not accepting connections")
} catch {
    print("Error: \(error)")
}
```

### Custom Configuration

```swift
let config = SocketHelper.Configuration(
    socketPath: "/tmp/my-custom.sock",
    connectTimeout: 1.0,  // 1 second
    readTimeout: 2.0      // 2 seconds
)
let helper = SocketHelper(configuration: config)
```

### DeskPad Integration Example

```swift
import SocketHelper

let helper = SocketHelper()

// Create a virtual display
let createRequest: [String: Any] = [
    "command": "create",
    "width": 1920,
    "height": 1080,
    "name": "My Display"
]

let response = try await helper.sendRequest(createRequest)
if let display = response["display"] as? [String: Any],
   let displayID = display["id"] as? Int {
    print("Created display with ID: \(displayID)")
}

// List displays
let listResponse = try await helper.sendRequest(["command": "list"])
if let displays = listResponse["displays"] as? [[String: Any]] {
    print("Found \(displays.count) displays")
}
```

## Error Handling

SocketHelper throws structured errors of type `SocketError`:

| Error | Description |
|-------|-------------|
| `connectTimeout` | Connection attempt exceeded timeout |
| `connectionRefused` | Server refused connection or socket doesn't exist |
| `connectionFailed` | Other connection error |
| `sendFailed` | Error writing request to socket |
| `readTimeout` | Reading response exceeded timeout |
| `readFailed` | Error reading from socket |
| `invalidJSON` | Response is not valid JSON |
| `serializationFailed` | Request cannot be serialized to JSON |

All errors conform to `CustomStringConvertible` for helpful error messages.

## Protocol Details

The helper implements the following communication pattern:

1. Connect to Unix socket
2. Serialize request as JSON
3. Write JSON data to socket
4. Call `shutdown(SHUT_WR)` to signal end of request
5. Read response until EOF
6. Parse response as JSON
7. Close connection

This matches the protocol documented in `Integration/IPC.md`.

## Testing

Run the test suite:

```bash
cd Integration/SocketHelper
swift test --filter SocketHelperTests
```

All 13 tests should pass:
- Happy path round-trip
- Create and list command handling
- Connection timeout scenarios
- Connection refused handling
- Read timeout testing
- Invalid JSON response handling
- Truncated response handling
- Server error responses
- Large response handling
- Sequential and concurrent requests

## Design Decisions

### Why async/await?

Using Swift's modern concurrency ensures non-blocking operations without callback hell. The implementation uses `DispatchQueue.global()` internally to perform blocking socket operations off the main thread, then returns results via continuations.

### Why a new connection per request?

The current implementation creates a fresh socket connection for each request. This approach:
- Simplifies error handling and recovery
- Avoids connection state management
- Works well for low-frequency operations
- Is safe for concurrent requests

For high-frequency operations, connection pooling could be added in future versions.

### Why structured errors?

Rather than using generic `Error` types, SocketHelper provides specific `SocketError` cases. This allows callers to handle different failure modes appropriately (e.g., retry on timeout, fail fast on connection refused).

### Why configurable timeouts?

Different environments and use cases need different timeout values:
- Development: shorter timeouts for fast feedback
- Production: longer timeouts for reliability
- Testing: very short timeouts for deterministic behavior

The defaults (0.5s connect, 1.0s read) work well for local Unix sockets.

## Requirements

- Swift 5.9 or later
- macOS 10.15+ or Linux

## Related Documentation

- [Integration/IPC.md](../IPC.md) - Full protocol specification
- [Plans/PHASE_1_IPC_AND_SOCKET_HELPER.md](../../Plans/PHASE_1_IPC_AND_SOCKET_HELPER.md) - Phase 1 implementation plan

## License

This code is part of the PaperWM-swift project. See the repository root for license information.

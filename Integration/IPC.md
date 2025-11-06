# DeskPad ↔ PaperWM IPC Protocol

## Overview

This document describes the Unix domain socket protocol used for communication between PaperWM clients (e.g., `deskpadctl`) and the DeskPad listener service. The protocol uses JSON messages over an AF_UNIX stream socket for low-latency, synchronous RPC operations.

## Socket Configuration

- **Socket Path**: `/tmp/deskpad.sock`
- **Socket Type**: `AF_UNIX` (Unix domain socket), `SOCK_STREAM`
- **Protocol**: JSON request/response over TCP-like stream semantics

## Communication Flow

1. Client connects to the Unix socket at the configured path
2. Client serializes request as JSON and writes to socket
3. Client performs half-close (`shutdown(SHUT_WR)`) to signal end of request
4. Server reads request until EOF, processes it, and writes JSON response
5. Server closes connection after sending response
6. Client reads response until EOF and deserializes JSON

## Timeouts

### Client-Side Timeouts

- **Connect Timeout**: Default 0.5 seconds
  - Time allowed for `connect()` to complete
  - Prevents indefinite blocking if listener is not running
- **Read Timeout**: Default 1.0 seconds
  - Maximum time to wait for complete response after sending request
  - Covers both initial data arrival and full response transfer

### Server-Side Behavior

- No explicit timeout enforced by reference listener
- Connection handling is asynchronous (non-blocking)
- Each connection is processed in a separate background queue

## Request Format

All requests are JSON objects with a `command` field specifying the operation.

### Common Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `command` | string | Yes | The command to execute: `create`, `list`, or `remove` |

### Create Display Request

Creates a new virtual display.

**Request Schema:**

```json
{
  "command": "create",
  "width": 1920,
  "height": 1080,
  "refreshRate": 60.0,
  "name": "DeskPad Display"
}
```

**Fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `width` | integer | No | 1920 | Display width in pixels |
| `height` | integer | No | 1080 | Display height in pixels |
| `refreshRate` | number | No | 60.0 | Refresh rate in Hz (currently informational) |
| `name` | string | No | "DeskPad Display" | Human-readable display name |

**Example:**

```json
{
  "command": "create",
  "width": 2560,
  "height": 1440,
  "name": "My Virtual Display"
}
```

### List Displays Request

Retrieves all active virtual displays.

**Request Schema:**

```json
{
  "command": "list"
}
```

**Example:**

```json
{
  "command": "list"
}
```

### Remove Display Request

Removes a virtual display by ID.

**Request Schema:**

```json
{
  "command": "remove",
  "displayID": 1000
}
```

**Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `displayID` | integer (UInt32) | Yes | The ID of the display to remove |

**Example:**

```json
{
  "command": "remove",
  "displayID": 1001
}
```

## Response Format

All responses are JSON objects. Successful responses contain operation-specific fields, while errors contain an `error` field.

### Create Display Response

**Success Schema:**

```json
{
  "result": "created",
  "display": {
    "id": 1000,
    "width": 1920,
    "height": 1080,
    "name": "DeskPad Display"
  }
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `result` | string | Always `"created"` for successful create |
| `display` | object | The created display information |
| `display.id` | integer | Unique display ID (UInt32) |
| `display.width` | integer | Display width in pixels |
| `display.height` | integer | Display height in pixels |
| `display.name` | string | Display name |

### List Displays Response

**Success Schema:**

```json
{
  "displays": [
    {
      "id": 1000,
      "width": 1920,
      "height": 1080,
      "name": "DeskPad Display"
    },
    {
      "id": 1001,
      "width": 2560,
      "height": 1440,
      "name": "My Virtual Display"
    }
  ]
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `displays` | array | Array of display objects (may be empty) |

### Remove Display Response

**Success Schema:**

```json
{
  "result": "removed",
  "displayID": 1000
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `result` | string | Always `"removed"` for successful removal |
| `displayID` | integer | The ID of the removed display |

## Error Format

Errors are indicated by an `error` field in the response JSON. The connection is still closed normally after sending an error response.

**Error Schema:**

```json
{
  "error": "error description"
}
```

**Common Error Messages:**

| Error | Description |
|-------|-------------|
| `"missing command"` | Request JSON lacks a `command` field |
| `"unknown command"` | The `command` value is not recognized |
| `"missing displayID"` | Remove request lacks required `displayID` field |

**Example Error Response:**

```json
{
  "error": "missing displayID"
}
```

## Client-Side Error Conditions

Clients should handle the following error conditions separately from server-returned errors:

### Connection Errors

- **Connect Timeout**: Socket connection attempt exceeds timeout
  - Suggests listener is not running or socket path is incorrect
- **Connection Refused**: Socket exists but connection is rejected
  - Suggests listener crashed or is not accepting connections
  - On Unix systems, typically `ECONNREFUSED` (61)
- **Socket Not Found**: Socket path does not exist
  - Suggests listener has never been started
  - On Unix systems, typically `ENOENT` (2)

### Communication Errors

- **Send Failure**: Error writing request to socket
  - Network/socket error during write operation
- **Read Timeout**: No complete response received within read timeout
  - Suggests listener hung or response is malformed
- **Truncated Response**: Connection closed before complete JSON received
  - May occur if listener crashes during processing

### Data Errors

- **Invalid JSON**: Response is not valid JSON
  - Suggests protocol mismatch or corrupted data
- **Malformed Response**: JSON parses but doesn't match expected schema
  - Missing required fields or unexpected structure

## Implementation Notes

### Half-Close Semantics

The protocol relies on half-close (`shutdown(SHUT_WR)`) to signal end of request:

1. Client writes complete JSON request
2. Client calls `shutdown(fd, SHUT_WR)` to close write side
3. Server sees EOF on read, knows request is complete
4. Server writes response and closes connection
5. Client reads response until EOF

This avoids the need for length prefixes or delimiters while maintaining clear message boundaries.

### JSON Serialization

- Use compact JSON (no pretty-printing) to minimize transfer size
- UTF-8 encoding required
- No trailing newline expected or required
- Whitespace is allowed but not required

### Concurrency

The reference listener (`test-listener.swift`) processes each connection asynchronously on a background queue. Clients should:

- Not assume responses arrive in request order if using multiple concurrent connections
- Use separate socket connections for concurrent requests
- Implement proper timeout handling to avoid indefinite blocking

## Examples

### Successful Create Operation

**Client sends:**
```json
{"command":"create","width":1920,"height":1080,"name":"Test Display"}
```

**Server responds:**
```json
{"result":"created","display":{"id":1000,"width":1920,"height":1080,"name":"Test Display"}}
```

### Successful List Operation

**Client sends:**
```json
{"command":"list"}
```

**Server responds:**
```json
{"displays":[{"id":1000,"width":1920,"height":1080,"name":"Test Display"}]}
```

### Error: Missing DisplayID

**Client sends:**
```json
{"command":"remove"}
```

**Server responds:**
```json
{"error":"missing displayID"}
```

### Error: Unknown Command

**Client sends:**
```json
{"command":"delete","displayID":1000}
```

**Server responds:**
```json
{"error":"unknown command"}
```

## Open Questions and TODOs

### Behavior Clarifications Needed

- **Duplicate Display Names**: Does the listener enforce unique display names? Current reference allows duplicates.
- **Display ID Allocation**: ID counter starts at 1000 in reference listener. Is this guaranteed? Should clients rely on this?
- **ID Type Consistency**: Request uses `UInt32` for `displayID` but JSON may represent as `Int`. Needs type consistency validation.
- **Concurrent Request Handling**: Are create/remove operations atomic? Can concurrent creates interfere?
- **Error Code Standardization**: Consider numeric error codes in addition to string messages for programmatic handling.

### Future Enhancements

- **Authentication**: No authentication currently. Consider adding for production deployments.
- **Versioning**: No protocol version field. May be needed for backward compatibility.
- **Batch Operations**: Support for multiple commands in single request/response.
- **Server-Initiated Events**: Current protocol is request/response only. Consider streaming/push for display state changes.
- **Socket Permissions**: Currently world-accessible. Consider restricting to user/group.

### Reference Implementation Gaps

- **refreshRate Field**: Sent by client in create request but not stored or returned by reference listener. Needs clarification on intended use.
- **Display State Persistence**: Reference listener maintains in-memory state only. Lost on restart.
- **Maximum Display Count**: No documented limit. Consider adding resource limits.
- **Request Size Limits**: No documented maximum request size. Consider adding limits to prevent DoS.

## Compatibility Notes

This protocol definition is based on the reference implementation in `test-listener.swift` and `deskpadctl` as of the Phase 1 IPC specification. Future phases may extend or modify the protocol while maintaining backward compatibility where possible.

### Fallback Behavior

Clients (like `deskpadctl`) may implement fallback to DistributedNotificationCenter-based IPC when socket is unavailable. This provides compatibility with older listener versions and degraded operation when socket path is inaccessible.

## Testing Recommendations

When implementing or testing IPC clients:

1. **Test with Socket Running**: Verify successful request/response cycle
2. **Test with Socket Stopped**: Verify proper timeout and error handling
3. **Test with Invalid Responses**: Send malformed JSON to test error handling
4. **Test Concurrent Requests**: Verify handling of multiple simultaneous connections
5. **Test Timeout Edge Cases**: Use artificial delays to trigger read timeouts
6. **Test Half-Close Handling**: Verify shutdown() semantics work correctly
7. **Test Large Responses**: Create many displays and ensure large list responses work

## Version History

- **Phase 1 (Initial)**: Protocol definition based on reference listener implementation

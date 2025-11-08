#!/usr/bin/env swift
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#endif
import Foundation

print("🎧 Starting notification listener...")
print("Listening for: com.deskpad.displaycontrol")
print("Press Ctrl+C to stop\n")

let center = DistributedNotificationCenter.default()

// Simple CLI flag support: pass --no-socket to skip creating the unix domain socket
let args = CommandLine.arguments
let noSocketMode = args.contains("--no-socket")

// Get paths from environment or use defaults
let socketPath = ProcessInfo.processInfo.environment["DESKPAD_SOCKET_PATH"] ?? "/tmp/deskpad.sock"
let logPath = ProcessInfo.processInfo.environment["DESKPAD_LOG_PATH"] ?? "/tmp/deskpad-listener.log"
let healthPath = ProcessInfo.processInfo.environment["DESKPAD_HEALTH_PATH"] ?? "/tmp/deskpad-listener.health"

// Log helper: write to log file so background runs can be inspected
let logURL = URL(fileURLWithPath: logPath)
func appendLog(_ s: String) {
    // print to stdout as well
    print(s)
    let line = s + "\n"
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logURL.path) {
            if let fh = try? FileHandle(forWritingTo: logURL) {
                fh.seekToEndOfFile()
                fh.write(data)
                try? fh.close()
            }
        } else {
            try? data.write(to: logURL)
        }
    }
}

appendLog("🎧 Starting notification listener...")
appendLog("Listening for: com.deskpad.displaycontrol")
appendLog("Press Ctrl+C to stop\n")

// Health file management
func writeHealthFile() {
    let pid = getpid()
    let timestamp = Date().timeIntervalSince1970
    let healthData: [String: Any] = [
        "pid": pid,
        "timestamp": timestamp,
        "socket_path": socketPath,
        "log_path": logPath
    ]
    
    if let jsonData = try? JSONSerialization.data(withJSONObject: healthData, options: [.prettyPrinted]) {
        do {
            try jsonData.write(to: URL(fileURLWithPath: healthPath), options: .atomic)
            // Set owner-only permissions on health file
            chmod(healthPath, S_IRUSR | S_IWUSR)
            appendLog("✓ Health file written to \(healthPath)")
        } catch {
            appendLog("⚠️ Failed to write health file: \(error)")
        }
    }
}

func cleanupHealthFile() {
    try? FileManager.default.removeItem(atPath: healthPath)
    appendLog("✓ Health file removed")
}

// Cleanup handler for graceful shutdown
var cleanupHandlerInstalled = false
func installCleanupHandler() {
    guard !cleanupHandlerInstalled else { return }
    cleanupHandlerInstalled = true
    
    let cleanup = {
        appendLog("\n🛑 Shutting down listener...")
        
        // Remove socket file
        if FileManager.default.fileExists(atPath: socketPath) {
            try? FileManager.default.removeItem(atPath: socketPath)
            appendLog("✓ Socket file removed")
        }
        
        // Remove health file
        cleanupHealthFile()
        
        exit(0)
    }
    
    // Install signal handlers for graceful shutdown
    signal(SIGINT) { _ in cleanup() }
    signal(SIGTERM) { _ in cleanup() }
}

// Write initial health file
writeHealthFile()
installCleanupHandler()


// Helper to get peer UID from a unix domain socket fd
func peerUID(of fd: Int32) -> uid_t? {
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        var euid: uid_t = 0
        var egid: gid_t = 0
        if getpeereid(fd, &euid, &egid) == 0 {
            return euid
        }
        return nil
    #else
        var cred = ucred()
        var len = socklen_t(MemoryLayout<ucred>.size)
        let res = withUnsafeMutablePointer(to: &cred) { ptr -> Int32 in
            return ptr.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<ucred>.size) { bytes in
                var optlen = len
                return getsockopt(fd, SOL_SOCKET, SO_PEERCRED, bytes, &optlen)
            }
        }
        if res == 0 {
            return cred.uid
        }
        return nil
    #endif
}

// Simple in-memory display store for the test listener
var displays: [[String: Any]] = []
var nextID: UInt32 = 1000

func postResponse(_ payload: [String: Any]) {
    if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
       let jsonString = String(data: data, encoding: .utf8)
    {
        center.post(name: Notification.Name("com.deskpad.displaycontrol.response"), object: nil, userInfo: ["payload": jsonString])
    }
}

// Process a parsed JSON request and return the response dictionary.
func processRequest(_ json: [String: Any]) -> [String: Any] {
    var response: [String: Any] = [:]

    if let command = json["command"] as? String {
        // ping is a lightweight readiness check
        if command == "ping" {
            response = ["result": ["version": "1", "pid": getpid(), "uid": getuid()]]
            appendLog("   Posting response: ping")
            return response
        }
        switch command {
        case "create":
            let id = nextID
            nextID += 1
            var display: [String: Any] = ["id": id]
            display["width"] = json["width"] ?? 1920
            display["height"] = json["height"] ?? 1080
            display["name"] = json["name"] ?? "DeskPad Display"
            displays.append(display)
            response = ["result": "created", "display": display]
            appendLog("   Posting response: created display \(id)")

        case "list":
            response = ["displays": displays]
            appendLog("   Posting response: list (\(displays.count) displays)")

        case "remove":
            if let displayID = json["displayID"] as? UInt32 {
                displays.removeAll { d in
                    if let id = d["id"] as? UInt32 { return id == displayID }
                    if let idNum = d["id"] as? Int { return UInt32(idNum) == displayID }
                    return false
                }
                response = ["result": "removed", "displayID": displayID]
                appendLog("   Posting response: removed display \(displayID)")
            } else {
                response = ["error": "missing displayID"]
                appendLog("   Posting response: missing displayID")
            }

        default:
            response = ["error": "unknown command"]
            appendLog("   Posting response: unknown command")
        }
    } else {
        response = ["error": "missing command"]
    }

    // Send response via replyTo or generic channel and optionally write replyFile
    if let replyTo = json["replyTo"] as? String {
        if let data = try? JSONSerialization.data(withJSONObject: response, options: []),
           let jsonString = String(data: data, encoding: .utf8)
        {
            center.post(name: Notification.Name(replyTo), object: nil, userInfo: ["payload": jsonString])
        }
    } else {
        postResponse(response)
    }

    if let replyFile = json["replyFile"] as? String {
        if let data = try? JSONSerialization.data(withJSONObject: response, options: []) {
            // Write atomically: write to temp file in same dir then rename
            let replyURL = URL(fileURLWithPath: replyFile)
            let dir = replyURL.deletingLastPathComponent()
            let tmpName = ".tmp_reply_\(UUID().uuidString)"
            let tmpURL = dir.appendingPathComponent(tmpName)
            do {
                try data.write(to: tmpURL, options: .atomic)
                // ensure owner-only perms
                chmod(tmpURL.path, S_IRUSR | S_IWUSR)
                try FileManager.default.moveItem(at: tmpURL, to: replyURL)
            } catch {
                appendLog("   ⚠️ Failed to write reply file: \(error)")
                try? FileManager.default.removeItem(at: tmpURL)
            }
        }
    }

    return response
}

center.addObserver(
    forName: NSNotification.Name("com.deskpad.displaycontrol"),
    object: nil,
    queue: nil
) { notification in
    appendLog("📨 Received notification!")

    if let userInfo = notification.userInfo,
       let payloadString = userInfo["payload"] as? String
    {
        appendLog("   Payload: \(payloadString)")

        if let data = payloadString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            appendLog("   Parsed:")
            for (key, value) in json {
                appendLog("     - \(key): \(value)")
            }
            // Process using shared handler
            _ = processRequest(json)
        }
    }
    appendLog("")
}

print("✅ Listener ready. Run deskpadctl commands in another terminal.\n")

if noSocketMode {
    appendLog("⚙️ Running in notification-only mode (socket disabled)")
} else {
    appendLog("⚙️ Running with socket server enabled at \(socketPath)")
}

// Start a simple Unix domain socket server for fast local IPC
func startSocketServer() {
    DispatchQueue.global(qos: .background).async {
        // Remove existing socket file (cleanup stale socket)
        if FileManager.default.fileExists(atPath: socketPath) {
            appendLog("⚠️ Removing stale socket file at \(socketPath)")
            try? FileManager.default.removeItem(atPath: socketPath)
        }

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        if fd < 0 {
            let err = String(cString: strerror(errno))
            appendLog("⚠️ Failed to create socket: \(err) (errno: \(errno))")
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let maxlen = MemoryLayout.size(ofValue: addr.sun_path)
        let cstr = socketPath.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            let buff = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: CChar.self)
            cstr.withUnsafeBufferPointer { buf in
                let copyLen = min(buf.count, maxlen)
                memcpy(buff, buf.baseAddress, copyLen)
                if copyLen < maxlen { buff[copyLen] = 0 } else { buff[maxlen - 1] = 0 }
            }
        }

        // Bind
        let addrlen = socklen_t(MemoryLayout.size(ofValue: addr))
        let bindRes = withUnsafePointer(to: &addr) { ptr -> Int32 in
            let raw = UnsafeRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
            return bind(fd, raw, addrlen)
        }
        if bindRes != 0 {
            let err = String(cString: strerror(errno))
            appendLog("⚠️ Failed to bind socket at \(socketPath): \(err) (errno: \(errno))")
            close(fd)
            return
        }

        if listen(fd, 10) != 0 {
            let err = String(cString: strerror(errno))
            appendLog("⚠️ Failed to listen on socket: \(err) (errno: \(errno))")
            close(fd)
            return
        }

        // Restrict socket file permissions to owner only (0600)
        socketPath.withCString { cstr in
            chmod(cstr, S_IRUSR | S_IWUSR)
        }

        appendLog("🔌 Unix socket server listening at \(socketPath)")

        while true {
            var clientAddr = sockaddr_un()
            var clientAddrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
            let clientFd = withUnsafeMutablePointer(to: &clientAddr) { ptr -> Int32 in
                let raw = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
                return accept(fd, raw, &clientAddrLen)
            }
            if clientFd < 0 {
                let err = String(cString: strerror(errno))
                appendLog("⚠️ Accept failed: \(err) (errno: \(errno))")
                continue
            }
            // Check peer credentials and reject if UID mismatches (simple per-user auth)
            if let peer = peerUID(of: clientFd) {
                let local = getuid()
                if peer != local {
                    appendLog("⚠️ Rejected connection from uid \(peer) (expected \(local))")
                    close(clientFd)
                    continue
                }
            } else {
                appendLog("⚠️ Could not determine peer credentials; rejecting connection")
                close(clientFd)
                continue
            }

            // Handle client in background
            DispatchQueue.global().async {
                var data = Data()
                var buf = [UInt8](repeating: 0, count: 4096)
                while true {
                    let r = read(clientFd, &buf, buf.count)
                    if r > 0 { data.append(buf, count: r); continue }
                    break
                }
                if let s = String(data: data, encoding: .utf8) {
                    appendLog("🔌 Socket received: \(s)")
                    if let d = s.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
                        // process and return response
                        let response = processRequest(json)
                        if let respData = try? JSONSerialization.data(withJSONObject: response, options: []) {
                            respData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                                var sent = 0
                                while sent < respData.count {
                                    let w = write(clientFd, ptr.baseAddress!.advanced(by: sent), respData.count - sent)
                                    if w <= 0 { break }
                                    sent += w
                                }
                            }
                        }
                    }
                }
                close(clientFd)
            }
        }
    }
}

// Start socket server for fast local testing (unless disabled via --no-socket)
if !noSocketMode {
    startSocketServer()
} else {
    appendLog("(socket server skipped due to --no-socket flag)")
}

RunLoop.main.run()

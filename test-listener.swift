#!/usr/bin/env swift
import Foundation

print("🎧 Starting notification listener...")
print("Listening for: com.deskpad.displaycontrol")
print("Press Ctrl+C to stop\n")

let center = DistributedNotificationCenter.default()

// Log helper: write to /tmp/deskpad-listener.log so background runs can be inspected
let logURL = URL(fileURLWithPath: "/tmp/deskpad-listener.log")
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

// Simple in-memory display store for the test listener
var displays: [[String: Any]] = []
var nextID: UInt32 = 1000

func postResponse(_ payload: [String: Any]) {
    if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
       let jsonString = String(data: data, encoding: .utf8) {
        center.post(name: Notification.Name("com.deskpad.displaycontrol.response"), object: nil, userInfo: ["payload": jsonString])
    }
}

// Process a parsed JSON request and return the response dictionary.
func processRequest(_ json: [String: Any]) -> [String: Any] {
    var response: [String: Any] = [:]

    if let command = json["command"] as? String {
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
           let jsonString = String(data: data, encoding: .utf8) {
            center.post(name: Notification.Name(replyTo), object: nil, userInfo: ["payload": jsonString])
        }
    } else {
        postResponse(response)
    }

    if let replyFile = json["replyFile"] as? String {
        if let data = try? JSONSerialization.data(withJSONObject: response, options: []) {
            try? data.write(to: URL(fileURLWithPath: replyFile))
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
       let payloadString = userInfo["payload"] as? String {
        appendLog("   Payload: \(payloadString)")

        if let data = payloadString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
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

// Start a simple Unix domain socket server for fast local IPC
let socketPath = "/tmp/deskpad.sock"
func startSocketServer() {
    DispatchQueue.global(qos: .background).async {
        // remove existing socket file
        try? FileManager.default.removeItem(atPath: socketPath)

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        if fd < 0 {
            appendLog("⚠️ Failed to create socket")
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
                if copyLen < maxlen { buff[copyLen] = 0 } else { buff[maxlen-1] = 0 }
            }
        }

        // Bind
        let addrlen = socklen_t(MemoryLayout.size(ofValue: addr))
        let bindRes = withUnsafePointer(to: &addr) { ptr -> Int32 in
            let raw = UnsafeRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
            return bind(fd, raw, addrlen)
        }
        if bindRes != 0 {
            appendLog("⚠️ Failed to bind socket at \(socketPath)")
            close(fd)
            return
        }

        if listen(fd, 10) != 0 {
            appendLog("⚠️ Failed to listen on socket")
            close(fd)
            return
        }

        appendLog("🔌 Unix socket server listening at \(socketPath)")

        while true {
            var clientAddr = sockaddr_un()
            var clientAddrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
            let clientFd = withUnsafeMutablePointer(to: &clientAddr) { ptr -> Int32 in
                let raw = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
                return accept(fd, raw, &clientAddrLen)
            }
            if clientFd < 0 { continue }

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
                    if let d = s.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: d) as? [String:Any] {
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

// Start socket server for fast local testing
startSocketServer()

RunLoop.main.run()

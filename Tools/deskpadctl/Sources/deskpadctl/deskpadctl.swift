import ArgumentParser
import Foundation
#if os(macOS)
import AppKit
#endif

// Small reference wrapper used to hold the response payload across a potentially
// concurrently-executing notification handler. Marked @unchecked Sendable to
// satisfy the compiler's Sendable-checking for captured references in closures.
final class ResponseBox: @unchecked Sendable {
    var value: String?
    init(_ v: String? = nil) { self.value = v }
}
#if os(macOS)
import Darwin
#endif

@main
struct DeskPadCTL: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "deskpadctl",
        abstract: "Control DeskPad virtual displays via distributed notifications",
        version: "1.0.0",
        subcommands: [Create.self, Remove.self, List.self]
    )
}

// MARK: - Create Command

extension DeskPadCTL {
    struct Create: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Create a new virtual display"
        )
        
        @Option(name: .shortAndLong, help: "Display width in pixels")
        var width: Int = 1920
        
        @Option(name: .shortAndLong, help: "Display height in pixels")
        var height: Int = 1080
        
        @Option(name: .shortAndLong, help: "Display refresh rate in Hz")
        var refreshRate: Double = 60.0
        
        @Option(name: .shortAndLong, help: "Display name")
        var name: String = "DeskPad Display"
        
    func run() throws {
            let payload: [String: Any] = [
                "command": "create",
                "width": width,
                "height": height,
                "refreshRate": refreshRate,
                "name": name
            ]
            
            do {
                #if os(macOS)
                // Prefer Unix socket RPC for low-latency local operations. Fall back to notifications if socket unavailable.
                if let _ = sendViaUnixSocket(socketPath: "/tmp/deskpad.sock", payload: payload, timeoutSeconds: 0.5) {
                    print("✓ Create command sent successfully (socket)")
                    print("  Display: \(name)")
                    print("  Resolution: \(width)x\(height)@\(refreshRate)Hz")
                    return
                }
                #endif
                // Fallback to notification-based delivery for wider compatibility
                try sendNotification(name: "com.deskpad.displaycontrol", payload: payload)
                print("✓ Create command sent successfully")
                print("  Display: \(name)")
                print("  Resolution: \(width)x\(height)@\(refreshRate)Hz")
            } catch {
                throw DeskPadCTLError.communicationFailed(error.localizedDescription)
            }
        }
    }
}

// MARK: - Remove Command

extension DeskPadCTL {
    struct Remove: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Remove a virtual display by ID"
        )
        
        @Argument(help: "Display ID to remove")
        var displayID: UInt32
        
    func run() throws {
            let payload: [String: Any] = [
                "command": "remove",
                "displayID": displayID
            ]
            
            do {
                #if os(macOS)
                if sendViaUnixSocket(socketPath: "/tmp/deskpad.sock", payload: payload, timeoutSeconds: 0.5) != nil {
                    print("✓ Remove command sent successfully (socket)")
                    print("  Display ID: \(displayID)")
                    return
                }
                #endif
                try sendNotification(name: "com.deskpad.displaycontrol", payload: payload)
                print("✓ Remove command sent successfully")
                print("  Display ID: \(displayID)")
                
            } catch {
                throw DeskPadCTLError.communicationFailed(error.localizedDescription)
            }
        }
    }
}

// MARK: - List Command

extension DeskPadCTL {
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List all virtual displays"
        )
        
    func run() throws {
            let payload: [String: Any] = [
                "command": "list"
            ]

            do {
                // First try Unix socket RPC for fast local response
                #if os(macOS)
                if let socketResp = sendViaUnixSocket(socketPath: "/tmp/deskpad.sock", payload: payload, timeoutSeconds: 0.5) {
                    if let data = socketResp.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let displays = json["displays"] as? [[String: Any]] {
                            print("✓ List command sent successfully (socket)")
                            print("  Displays:")
                            for d in displays {
                                let id = d["id"] ?? "?"
                                let name = d["name"] ?? "Unnamed"
                                let width = d["width"] ?? "?"
                                let height = d["height"] ?? "?"
                                print("    - ID: \(id) | \(name) | \(width)x\(height)")
                            }
                            return
                        } else {
                            print("✓ List command sent successfully (socket)")
                            print("  Response:")
                            print("    \(json)")
                            return
                        }
                    }
                }
                #endif

                #if os(macOS)
                // Prepare to receive a response from DeskPad using a per-request reply channel
                let uuid = UUID().uuidString
                let replyNameString = "com.deskpad.displaycontrol.response.\(uuid)"
                let responseName = Notification.Name(replyNameString)
                let semaphore = DispatchSemaphore(value: 0)
                let received = ResponseBox()

                let center = DistributedNotificationCenter.default()
                // Use a nil queue so the block runs on the receiving thread
                let observer = center.addObserver(forName: responseName, object: nil, queue: nil) { notification in
                    if let userInfo = notification.userInfo,
                       let payloadString = userInfo["payload"] as? String {
                        received.value = payloadString
                    }
                    semaphore.signal()
                }

                // Debug: show which reply channel we are listening on
                print("  (debug) listening for replies on: \(replyNameString)")

                // attach reply channel and an optional reply file to payload so listener knows where to post
                var payloadWithReply = payload
                payloadWithReply["replyTo"] = replyNameString
                let replyFilePath = "/tmp/deskpad_response_\(uuid).json"
                payloadWithReply["replyFile"] = replyFilePath

                try sendNotification(name: "com.deskpad.displaycontrol", payload: payloadWithReply)
                print("✓ List command sent successfully")
                print("  Waiting for response from DeskPad...")

                // Quick-poll the reply file for up to 1s — this is fast and avoids
                // waiting on the notification delivery path if the responder writes files.
                if let replyFile = payloadWithReply["replyFile"] as? String {
                    let fm = FileManager.default
                    var foundFilePayload: String? = nil
                    for _ in 0..<20 { // 20 * 50ms = 1s
                        if fm.fileExists(atPath: replyFile), let data = fm.contents(atPath: replyFile), let s = String(data: data, encoding: .utf8) {
                            foundFilePayload = s
                            // cleanup
                            try? fm.removeItem(atPath: replyFile)
                            break
                        }
                        usleep(50_000) // 50ms
                    }

                    if let filePayload = foundFilePayload {
                        // Parse file payload and print
                        if let data = filePayload.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let displays = json["displays"] as? [[String: Any]] {
                                print("  Displays:")
                                for d in displays {
                                    let id = d["id"] ?? "?"
                                    let name = d["name"] ?? "Unnamed"
                                    let width = d["width"] ?? "?"
                                    let height = d["height"] ?? "?"
                                    print("    - ID: \(id) | \(name) | \(width)x\(height)")
                                }
                            } else {
                                print("  Response (from file):")
                                print("    \(json)")
                            }
                        } else {
                            print("  Received an invalid response from DeskPad (file)")
                        }
                        center.removeObserver(observer)
                        return
                    }
                }

                // If no file response, wait up to 1s for a notification response
                let timeout = DispatchTime.now() + .seconds(1)
                if semaphore.wait(timeout: timeout) == .success {
                    if let payloadString = received.value,
                       let data = payloadString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // Pretty-print response
                        if let displays = json["displays"] as? [[String: Any]] {
                            print("  Displays:")
                            for d in displays {
                                let id = d["id"] ?? "?"
                                let name = d["name"] ?? "Unnamed"
                                let width = d["width"] ?? "?"
                                let height = d["height"] ?? "?"
                                print("    - ID: \(id) | \(name) | \(width)x\(height)")
                            }
                        } else {
                            // Fallback: print raw JSON
                            print("  Response:")
                            print("    \(json)")
                        }
                    } else {
                        print("  Received an empty or invalid response from DeskPad")
                    }
                } else {
                    // If we timed out, check if a reply file was written by the responder as a fallback
                    if FileManager.default.fileExists(atPath: replyFilePath),
                       let data = FileManager.default.contents(atPath: replyFilePath),
                       let payloadString = String(data: data, encoding: .utf8),
                       let pdata = payloadString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: pdata) as? [String: Any] {
                        // Pretty-print response from file
                        if let displays = json["displays"] as? [[String: Any]] {
                            print("  Displays:")
                            for d in displays {
                                let id = d["id"] ?? "?"
                                let name = d["name"] ?? "Unnamed"
                                let width = d["width"] ?? "?"
                                let height = d["height"] ?? "?"
                                print("    - ID: \(id) | \(name) | \(width)x\(height)")
                            }
                        } else {
                            print("  Response (from file):")
                            print("    \(json)")
                        }
                        // Cleanup reply file
                        try? FileManager.default.removeItem(atPath: replyFilePath)
                    } else {
                        print("  No response from DeskPad (timed out)")
                    }
                }

                // Remove observer
                center.removeObserver(observer)
                #else
                try sendNotification(name: "com.deskpad.displaycontrol", payload: payload)
                print("✓ List command sent successfully")
                print("  Waiting for response from DeskPad...")
                #endif
            } catch {
                throw DeskPadCTLError.communicationFailed(error.localizedDescription)
            }
        }
    }
}

// MARK: - Helper Functions

#if os(macOS)
func sendNotification(name: String, payload: [String: Any]) throws {
    let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
    
    let center = DistributedNotificationCenter.default()
    let notification = Notification.Name(name)
    
    // Send the notification with the JSON payload as userInfo
    center.post(name: notification, object: nil, userInfo: ["payload": String(data: jsonData, encoding: .utf8) ?? "{}"] )
}

#if os(macOS)
// Try sending the payload over a Unix domain socket. Returns the raw response string if any.
func sendViaUnixSocket(socketPath: String, payload: [String: Any], timeoutSeconds: TimeInterval = 1.0) -> String? {
    // Serialize payload
    guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else { return nil }
    let bytes = [UInt8](data)

    // Create socket
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    if fd < 0 { return nil }

    // Ensure socket closed on exit
    defer { close(fd) }

    // Build sockaddr_un
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)
    // copy path (null-terminated C string)
    let maxlen = MemoryLayout.size(ofValue: addr.sun_path)
    let cstr = socketPath.utf8CString // includes null terminator
    withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
        let buff = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: CChar.self)
        cstr.withUnsafeBufferPointer { buf in
            let copyLen = min(buf.count, maxlen)
            memcpy(buff, buf.baseAddress, copyLen)
            if copyLen < maxlen {
                buff[copyLen] = 0
            } else {
                buff[maxlen-1] = 0
            }
        }
    }

    let addrlen = socklen_t(MemoryLayout.size(ofValue: addr))
    // Connect
    let result = withUnsafePointer(to: &addr) { ptr -> Int32 in
        let raw = UnsafeRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
        return connect(fd, raw, addrlen)
    }
    if result != 0 {
        return nil
    }

    // Send all bytes
    var sent = 0
    while sent < bytes.count {
        let s = bytes.withUnsafeBufferPointer { buf -> Int in
            let start = buf.baseAddress!.advanced(by: sent)
            return write(fd, start, bytes.count - sent)
        }
        if s <= 0 { return nil }
        sent += s
    }

    // Shutdown write to indicate EOF
    shutdown(fd, SHUT_WR)

    // Read response with timeout
    var resp = Data()
    let start = Date()
    var buffer = [UInt8](repeating: 0, count: 4096)
    while true {
        // Check timeout
        if Date().timeIntervalSince(start) > timeoutSeconds { break }
        let r = read(fd, &buffer, buffer.count)
        if r > 0 {
            resp.append(buffer, count: r)
            // continue reading until EOF
            continue
        } else if r == 0 {
            // EOF
            break
        } else {
            // error
            break
        }
    }

    if resp.count == 0 { return nil }
    return String(data: resp, encoding: .utf8)
}
#endif
#else
// Placeholder for non-macOS platforms
func sendNotification(name: String, payload: [String: Any]) throws {
    let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
    print("Warning: DistributedNotificationCenter not available on this platform")
    print("Would send notification '\(name)' with payload: \(String(data: jsonData, encoding: .utf8) ?? "{}")")
}
#endif

// MARK: - Errors

enum DeskPadCTLError: Error, CustomStringConvertible {
    case communicationFailed(String)
    case invalidResponse
    
    var description: String {
        switch self {
        case .communicationFailed(let message):
            return "Communication failed: \(message)"
        case .invalidResponse:
            return "Invalid response from DeskPad"
        }
    }
}

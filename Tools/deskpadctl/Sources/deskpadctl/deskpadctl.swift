import ArgumentParser
import Foundation
#if os(macOS)
import AppKit
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
                try sendNotification(name: "com.deskpad.displaycontrol", payload: payload)
                print("✓ List command sent successfully")
                print("  Waiting for response from DeskPad...")
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
    center.post(
        name: notification,
        object: nil as String?,
        userInfo: ["payload": String(data: jsonData, encoding: .utf8) ?? "{}"]
    )
}
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

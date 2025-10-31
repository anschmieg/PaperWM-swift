import Foundation
#if canImport(AppKit)
import AppKit
#endif
import PaperWM

/// CLI tool to send commands to DeskPad via Distributed Notification Center
@main
struct DeskPadCtl {
    static func main() {
        let arguments = CommandLine.arguments
        
        guard arguments.count > 1 else {
            printUsage()
            exit(1)
        }
        
        let command = arguments[1]
        
        switch command {
        case "create":
            handleCreate(arguments: Array(arguments.dropFirst(2)))
        case "remove":
            handleRemove(arguments: Array(arguments.dropFirst(2)))
        case "list":
            handleList()
        case "help", "--help", "-h":
            printUsage()
        default:
            print("Error: Unknown command '\(command)'")
            printUsage()
            exit(1)
        }
    }
    
    static func printUsage() {
        print("""
        DeskPad Control - CLI tool for managing virtual displays via DeskPad
        
        Usage:
            deskpadctl <command> [options]
        
        Commands:
            create <width> <height>  Create a virtual display with specified dimensions
            remove <display-id>      Remove a virtual display by ID
            list                     List all virtual displays
            help                     Show this help message
        
        Examples:
            deskpadctl create 1920 1080
            deskpadctl remove 1
            deskpadctl list
        """)
    }
    
    static func handleCreate(arguments: [String]) {
        guard arguments.count >= 2 else {
            print("Error: create command requires width and height")
            print("Usage: deskpadctl create <width> <height>")
            exit(1)
        }
        
        guard let width = Int(arguments[0]), let height = Int(arguments[1]) else {
            print("Error: width and height must be integers")
            exit(1)
        }
        
        let command: [String: Any] = [
            "action": "create",
            "width": width,
            "height": height
        ]
        
        sendCommand(command)
        print("Create command sent: \(width)x\(height)")
    }
    
    static func handleRemove(arguments: [String]) {
        guard arguments.count >= 1 else {
            print("Error: remove command requires display ID")
            print("Usage: deskpadctl remove <display-id>")
            exit(1)
        }
        
        guard let displayId = Int(arguments[0]) else {
            print("Error: display ID must be an integer")
            exit(1)
        }
        
        let command: [String: Any] = [
            "action": "remove",
            "displayId": displayId
        ]
        
        sendCommand(command)
        print("Remove command sent for display ID: \(displayId)")
    }
    
    static func handleList() {
        let command: [String: Any] = [
            "action": "list"
        ]
        
        sendCommand(command)
        print("List command sent")
    }
    
    static func sendCommand(_ command: [String: Any]) {
        #if os(macOS)
        do {
            try NotificationUtility.sendJSONNotification(
                payload: command,
                notificationName: .control,
                key: "command"
            )
        } catch {
            print("Error: Failed to send command: \(error.localizedDescription)")
            exit(1)
        }
        #else
        print("Error: This tool is only available on macOS")
        exit(1)
        #endif
    }
}

import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// DisplayControl hook to be integrated into DeskPad app
/// Listens for Distributed Notification commands and manages virtual displays
public class DisplayControlHook {
    
    public static let shared = DisplayControlHook()
    
    private var observers: [NSObjectProtocol] = []
    private var nextDisplayId: Int = 1
    
    private init() {}
    
    /// Start listening for distributed notifications
    public func startListening() {
        #if os(macOS)
        let center = DistributedNotificationCenter.default()
        
        let observer = center.addObserver(
            forName: NSNotification.Name("com.deskpad.control"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleNotification(notification)
        }
        
        observers.append(observer)
        
        print("DisplayControlHook: Started listening for commands")
        
        // Send a notification that we're ready
        let readyInfo: [AnyHashable: Any] = ["status": "ready"]
        center.postNotificationName(
            NSNotification.Name("com.deskpad.control.ready"),
            object: nil,
            userInfo: readyInfo,
            deliverImmediately: true
        )
        #else
        print("DisplayControlHook: DistributedNotificationCenter is only available on macOS")
        #endif
    }
    
    /// Stop listening for distributed notifications
    public func stopListening() {
        #if os(macOS)
        let center = DistributedNotificationCenter.default()
        for observer in observers {
            center.removeObserver(observer)
        }
        observers.removeAll()
        
        print("DisplayControlHook: Stopped listening for commands")
        #else
        print("DisplayControlHook: DistributedNotificationCenter is only available on macOS")
        #endif
    }
    
    private func handleNotification(_ notification: Notification) {
        do {
            let command = try NotificationUtility.parseJSONFromNotification(
                userInfo: notification.userInfo,
                key: "command"
            )
            
            guard let action = command["action"] as? String else {
                print("DisplayControlHook: No action specified in command")
                sendResponse(success: false, message: "No action specified")
                return
            }
            
            print("DisplayControlHook: Received command - action: \(action)")
            
            switch action {
            case "create":
                handleCreateDisplay(command: command)
            case "remove":
                handleRemoveDisplay(command: command)
            case "list":
                handleListDisplays()
            default:
                print("DisplayControlHook: Unknown action: \(action)")
                sendResponse(success: false, message: "Unknown action: \(action)")
            }
        } catch {
            print("DisplayControlHook: Failed to parse notification: \(error)")
            sendResponse(success: false, message: "Failed to parse command: \(error.localizedDescription)")
        }
    }
    
    private func handleCreateDisplay(command: [String: Any]) {
        guard let width = command["width"] as? Int,
              let height = command["height"] as? Int else {
            print("DisplayControlHook: Invalid create command - missing width or height")
            sendResponse(success: false, message: "Invalid create command - missing width or height")
            return
        }
        
        print("DisplayControlHook: Creating virtual display - \(width)x\(height)")
        
        // This is where we would call DeskPad's virtual display creation API
        // For now, we'll simulate the call and log the action
        
        // Example call (to be replaced with actual DeskPad API):
        // let displayId = DeskPad.createVirtualDisplay(width: width, height: height)
        
        // Simulated success with sequential ID
        let displayId = nextDisplayId
        nextDisplayId += 1
        print("DisplayControlHook: Virtual display created successfully - ID: \(displayId)")
        
        sendResponse(
            success: true,
            message: "Virtual display created successfully",
            data: ["displayId": displayId, "width": width, "height": height]
        )
    }
    
    private func handleRemoveDisplay(command: [String: Any]) {
        guard let displayId = command["displayId"] as? Int else {
            print("DisplayControlHook: Invalid remove command - missing displayId")
            sendResponse(success: false, message: "Invalid remove command - missing displayId")
            return
        }
        
        print("DisplayControlHook: Removing virtual display - ID: \(displayId)")
        
        // This is where we would call DeskPad's virtual display removal API
        // For now, we'll simulate the call and log the action
        
        // Example call (to be replaced with actual DeskPad API):
        // DeskPad.removeVirtualDisplay(displayId: displayId)
        
        // Simulated success
        print("DisplayControlHook: Virtual display removed successfully - ID: \(displayId)")
        
        sendResponse(
            success: true,
            message: "Virtual display removed successfully",
            data: ["displayId": displayId]
        )
    }
    
    private func handleListDisplays() {
        print("DisplayControlHook: Listing virtual displays")
        
        // This is where we would call DeskPad's virtual display listing API
        // For now, we'll simulate the call and log the action
        
        // Example call (to be replaced with actual DeskPad API):
        // let displays = DeskPad.listVirtualDisplays()
        
        // Simulated response
        let displays: [[String: Any]] = [
            ["id": 1, "width": 1920, "height": 1080, "active": true],
            ["id": 2, "width": 2560, "height": 1440, "active": true]
        ]
        
        print("DisplayControlHook: Found \(displays.count) virtual displays")
        
        sendResponse(
            success: true,
            message: "Virtual displays listed successfully",
            data: ["displays": displays]
        )
    }
    
    private func sendResponse(success: Bool, message: String, data: [String: Any]? = nil) {
        #if os(macOS)
        var response: [String: Any] = [
            "success": success,
            "message": message
        ]
        
        if let data = data {
            response["data"] = data
        }
        
        do {
            try NotificationUtility.sendJSONNotification(
                payload: response,
                notificationName: .response,
                key: "response"
            )
            print("DisplayControlHook: Response sent - \(message)")
        } catch {
            print("DisplayControlHook: Failed to send response: \(error)")
        }
        #else
        print("DisplayControlHook: Response - \(message)")
        #endif
    }
}

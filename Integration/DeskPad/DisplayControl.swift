import Cocoa
import Foundation

/// DisplayControl listens for distributed notifications from deskpadctl
/// and manages virtual display lifecycle (create, remove, list).
///
/// This component is designed to be integrated into DeskPad with minimal
/// changes to the core application. It uses DistributedNotificationCenter
/// to receive commands from external CLI tools.
class DisplayControl {
    static let shared = DisplayControl()
    
    private var displays: [UInt32: DisplayInfo] = [:]
    private let notificationCenter = DistributedNotificationCenter.default()
    
    struct DisplayInfo {
        let displayID: UInt32
        let name: String
        let width: Int
        let height: Int
        let refreshRate: Double
    }
    
    private init() {
        setupNotificationListener()
    }
    
    private func setupNotificationListener() {
        notificationCenter.addObserver(
            self,
            selector: #selector(handleDisplayControlNotification(_:)),
            name: Notification.Name("com.deskpad.displaycontrol"),
            object: nil
        )
    }
    
    @objc private func handleDisplayControlNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let payloadString = userInfo["payload"] as? String,
              let payloadData = payloadString.data(using: .utf8),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let command = payload["command"] as? String else {
            sendErrorResponse("Invalid notification payload")
            return
        }
        
        switch command {
        case "create":
            handleCreateCommand(payload: payload)
        case "remove":
            handleRemoveCommand(payload: payload)
        case "list":
            handleListCommand()
        default:
            sendErrorResponse("Unknown command: \(command)")
        }
    }
    
    private func handleCreateCommand(payload: [String: Any]) {
        let width = payload["width"] as? Int ?? 1920
        let height = payload["height"] as? Int ?? 1080
        let refreshRate = payload["refreshRate"] as? Double ?? 60.0
        let name = payload["name"] as? String ?? "DeskPad Display"
        
        // Note: In the actual implementation, this would call DeskPad's
        // CGVirtualDisplay API. For now, we'll simulate the creation.
        // The actual implementation should be integrated with ScreenViewController
        
        let displayID = createVirtualDisplay(
            name: name,
            width: width,
            height: height,
            refreshRate: refreshRate
        )
        
        if displayID != 0 {
            let info = DisplayInfo(
                displayID: displayID,
                name: name,
                width: width,
                height: height,
                refreshRate: refreshRate
            )
            displays[displayID] = info
            
            sendSuccessResponse([
                "displayID": displayID,
                "name": name,
                "width": width,
                "height": height,
                "refreshRate": refreshRate
            ])
        } else {
            sendErrorResponse("Failed to create virtual display")
        }
    }
    
    private func handleRemoveCommand(payload: [String: Any]) {
        guard let displayID = payload["displayID"] as? UInt32 else {
            sendErrorResponse("Missing or invalid displayID")
            return
        }
        
        if displays[displayID] != nil {
            // Note: In the actual implementation, this would call DeskPad's
            // API to remove the virtual display
            removeVirtualDisplay(displayID: displayID)
            displays.removeValue(forKey: displayID)
            
            sendSuccessResponse([
                "displayID": displayID,
                "status": "removed"
            ])
        } else {
            sendErrorResponse("Display ID \(displayID) not found")
        }
    }
    
    private func handleListCommand() {
        let displayList = displays.values.map { info -> [String: Any] in
            return [
                "displayID": info.displayID,
                "name": info.name,
                "width": info.width,
                "height": info.height,
                "refreshRate": info.refreshRate
            ]
        }
        
        sendSuccessResponse([
            "displays": displayList,
            "count": displayList.count
        ])
    }
    
    // MARK: - Virtual Display Management (to be integrated with DeskPad's actual API)
    
    private func createVirtualDisplay(
        name: String,
        width: Int,
        height: Int,
        refreshRate: Double
    ) -> UInt32 {
        // This is a placeholder. In the actual integration, this would:
        // 1. Create a CGVirtualDisplayDescriptor
        // 2. Set up the descriptor with provided parameters
        // 3. Create the CGVirtualDisplay
        // 4. Return the displayID
        
        // For now, return a simulated display ID
        let simulatedID = UInt32.random(in: 1000...9999)
        NSLog("DisplayControl: Simulated creation of display '\(name)' (\(width)x\(height)@\(refreshRate)Hz) with ID \(simulatedID)")
        return simulatedID
    }
    
    private func removeVirtualDisplay(displayID: UInt32) {
        // This is a placeholder. In the actual integration, this would:
        // 1. Look up the CGVirtualDisplay by displayID
        // 2. Call the appropriate cleanup/removal method
        
        NSLog("DisplayControl: Simulated removal of display ID \(displayID)")
    }
    
    // MARK: - Response Handling
    
    private func sendSuccessResponse(_ data: [String: Any]) {
        let response: [String: Any] = [
            "status": "success",
            "data": data
        ]
        sendResponse(response)
    }
    
    private func sendErrorResponse(_ message: String) {
        let response: [String: Any] = [
            "status": "error",
            "message": message
        ]
        sendResponse(response)
    }
    
    private func sendResponse(_ response: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            NSLog("DisplayControl: Failed to serialize response")
            return
        }
        
        NSLog("DisplayControl Response: \(jsonString)")
        
        // Also post a response notification that CLI tools can listen for
        notificationCenter.post(
            name: Notification.Name("com.deskpad.displaycontrol.response"),
            object: nil,
            userInfo: ["response": jsonString]
        )
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
}

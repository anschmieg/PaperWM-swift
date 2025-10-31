import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Shared utility for sending commands and responses via Distributed Notification Center
public struct NotificationUtility {
    
    /// Notification names
    public enum NotificationName: String {
        case control = "com.deskpad.control"
        case response = "com.deskpad.control.response"
        case ready = "com.deskpad.control.ready"
        
        var nsNotificationName: NSNotification.Name {
            return NSNotification.Name(rawValue)
        }
    }
    
    /// Send a JSON payload via Distributed Notification Center
    /// - Parameters:
    ///   - payload: Dictionary to be serialized as JSON
    ///   - notificationName: The notification name to use
    ///   - key: The key in userInfo to store the JSON string (default: "command")
    /// - Throws: JSONSerialization errors
    public static func sendJSONNotification(
        payload: [String: Any],
        notificationName: NotificationName,
        key: String = "command"
    ) throws {
        #if os(macOS)
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw NotificationError.jsonStringConversionFailed
        }
        
        let center = DistributedNotificationCenter.default()
        let userInfo: [AnyHashable: Any] = [key: jsonString]
        
        center.postNotificationName(
            notificationName.nsNotificationName,
            object: nil,
            userInfo: userInfo,
            deliverImmediately: true
        )
        #else
        throw NotificationError.macOSOnly
        #endif
    }
    
    /// Parse JSON from notification userInfo
    /// - Parameters:
    ///   - userInfo: The notification userInfo dictionary
    ///   - key: The key containing the JSON string
    /// - Returns: Parsed dictionary
    /// - Throws: Parsing errors
    public static func parseJSONFromNotification(
        userInfo: [AnyHashable: Any]?,
        key: String = "command"
    ) throws -> [String: Any] {
        guard let userInfo = userInfo,
              let jsonString = userInfo[key] as? String else {
            throw NotificationError.missingPayload
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NotificationError.invalidUTF8
        }
        
        guard let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NotificationError.invalidJSON
        }
        
        return parsed
    }
}

/// Errors that can occur during notification handling
public enum NotificationError: Error, LocalizedError {
    case jsonStringConversionFailed
    case macOSOnly
    case missingPayload
    case invalidUTF8
    case invalidJSON
    
    public var errorDescription: String? {
        switch self {
        case .jsonStringConversionFailed:
            return "Failed to convert JSON data to string"
        case .macOSOnly:
            return "Distributed Notification Center is only available on macOS"
        case .missingPayload:
            return "Missing or invalid payload in notification"
        case .invalidUTF8:
            return "Invalid UTF-8 encoding in JSON string"
        case .invalidJSON:
            return "Failed to parse JSON from notification"
        }
    }
}

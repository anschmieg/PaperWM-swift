#!/usr/bin/env swift
import Foundation
import AppKit

print("🎧 Starting notification listener...")
print("Listening for: com.deskpad.displaycontrol")
print("Press Ctrl+C to stop\n")

let center = DistributedNotificationCenter.default()

center.addObserver(
    forName: NSNotification.Name("com.deskpad.displaycontrol"),
    object: nil,
    queue: .main
) { notification in
    print("📨 Received notification!")
    
    if let userInfo = notification.userInfo,
       let payloadString = userInfo["payload"] as? String {
        print("   Payload: \(payloadString)")
        
        if let data = payloadString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("   Parsed:")
            for (key, value) in json {
                print("     - \(key): \(value)")
            }
        }
    }
    print()
}

print("✅ Listener ready. Run deskpadctl commands in another terminal.\n")

RunLoop.main.run()

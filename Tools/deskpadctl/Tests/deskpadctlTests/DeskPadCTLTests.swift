import Foundation
@testable import deskpadctl

// Minimal test validation
// Tests run via swift test command

func testJSONSerialization() throws {
    let payload: [String: Any] = [
        "command": "list",
        "displayID": 1234
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
    assert(jsonData.count > 0, "JSON data should not be empty")
    
    let deserialized = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    assert(deserialized != nil, "Should deserialize")
    assert(deserialized?["command"] as? String == "list", "Command should be 'list'")
    assert(deserialized?["displayID"] as? Int == 1234, "DisplayID should be 1234")
}

func testErrorDescriptions() throws {
    let error1 = DeskPadCTLError.communicationFailed("Connection timeout")
    assert(error1.description == "Communication failed: Connection timeout")
    
    let error2 = DeskPadCTLError.invalidResponse
    assert(error2.description == "Invalid response from DeskPad")
}

#if os(macOS)
func testSendNotification() throws {
    let payload: [String: Any] = [
        "command": "create",
        "width": 1920,
        "height": 1080
    ]
    
    // Should not throw
    try sendNotification(name: "com.deskpad.displaycontrol.test", payload: payload)
}
#endif

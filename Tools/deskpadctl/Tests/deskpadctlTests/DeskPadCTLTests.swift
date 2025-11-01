import XCTest
@testable import deskpadctl

final class DeskPadCTLTests: XCTestCase {
    
    func testSendNotification() throws {
        // Test that sendNotification can serialize a payload
        let payload: [String: Any] = [
            "command": "create",
            "width": 1920,
            "height": 1080,
            "refreshRate": 60.0,
            "name": "Test Display"
        ]
        
        // This should not throw
        XCTAssertNoThrow(try sendNotification(name: "com.deskpad.displaycontrol.test", payload: payload))
    }
    
    func testJSONSerialization() throws {
        let payload: [String: Any] = [
            "command": "list",
            "displayID": 1234
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        XCTAssertNotNil(jsonData)
        
        // Verify we can deserialize it back
        let deserialized = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertNotNil(deserialized)
        XCTAssertEqual(deserialized?["command"] as? String, "list")
        XCTAssertEqual(deserialized?["displayID"] as? Int, 1234)
    }
    
    func testDeskPadCTLErrorDescription() {
        let error1 = DeskPadCTLError.communicationFailed("Connection timeout")
        XCTAssertEqual(error1.description, "Communication failed: Connection timeout")
        
        let error2 = DeskPadCTLError.invalidResponse
        XCTAssertEqual(error2.description, "Invalid response from DeskPad")
    }
}

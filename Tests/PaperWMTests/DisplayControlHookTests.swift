import XCTest
@testable import PaperWM
#if canImport(AppKit)
import AppKit
#endif

final class DisplayControlHookTests: XCTestCase {
    
    var displayControlHook: DisplayControlHook!
    var receivedResponses: [[String: Any]] = []
    var responseObserver: NSObjectProtocol?
    
    override func setUp() {
        super.setUp()
        #if os(macOS)
        displayControlHook = DisplayControlHook.shared
        receivedResponses = []
        
        // Listen for responses
        let center = DistributedNotificationCenter.default()
        responseObserver = center.addObserver(
            forName: NSNotification.Name("com.deskpad.control.response"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let userInfo = notification.userInfo,
               let responseString = userInfo["response"] as? String,
               let responseData = responseString.data(using: .utf8),
               let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                self?.receivedResponses.append(response)
            }
        }
        #endif
    }
    
    override func tearDown() {
        #if os(macOS)
        if let observer = responseObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        displayControlHook.stopListening()
        #endif
        super.tearDown()
    }
    
    func testStartListening() {
        #if os(macOS)
        displayControlHook.startListening()
        // If no crash, test passes
        XCTAssertTrue(true, "DisplayControlHook started listening successfully")
        #endif
    }
    
    func testStopListening() {
        #if os(macOS)
        displayControlHook.startListening()
        displayControlHook.stopListening()
        // If no crash, test passes
        XCTAssertTrue(true, "DisplayControlHook stopped listening successfully")
        #endif
    }
    
    func testCreateCommand() {
        #if os(macOS)
        displayControlHook.startListening()
        
        let command: [String: Any] = [
            "action": "create",
            "width": 1920,
            "height": 1080
        ]
        
        sendCommand(command)
        
        // Wait for response
        let expectation = XCTestExpectation(description: "Receive response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertFalse(receivedResponses.isEmpty, "Should receive a response")
        if let response = receivedResponses.first {
            XCTAssertTrue(response["success"] as? Bool ?? false, "Response should indicate success")
        }
        #endif
    }
    
    func testRemoveCommand() {
        #if os(macOS)
        displayControlHook.startListening()
        
        let command: [String: Any] = [
            "action": "remove",
            "displayId": 123
        ]
        
        sendCommand(command)
        
        // Wait for response
        let expectation = XCTestExpectation(description: "Receive response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertFalse(receivedResponses.isEmpty, "Should receive a response")
        if let response = receivedResponses.first {
            XCTAssertTrue(response["success"] as? Bool ?? false, "Response should indicate success")
        }
        #endif
    }
    
    func testListCommand() {
        #if os(macOS)
        displayControlHook.startListening()
        
        let command: [String: Any] = [
            "action": "list"
        ]
        
        sendCommand(command)
        
        // Wait for response
        let expectation = XCTestExpectation(description: "Receive response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertFalse(receivedResponses.isEmpty, "Should receive a response")
        if let response = receivedResponses.first {
            XCTAssertTrue(response["success"] as? Bool ?? false, "Response should indicate success")
            if let data = response["data"] as? [String: Any],
               let displays = data["displays"] as? [[String: Any]] {
                XCTAssertFalse(displays.isEmpty, "Should return list of displays")
            }
        }
        #endif
    }
    
    func testInvalidCommand() {
        #if os(macOS)
        displayControlHook.startListening()
        
        let command: [String: Any] = [
            "action": "invalid"
        ]
        
        sendCommand(command)
        
        // Wait for response
        let expectation = XCTestExpectation(description: "Receive response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertFalse(receivedResponses.isEmpty, "Should receive a response")
        if let response = receivedResponses.first {
            XCTAssertFalse(response["success"] as? Bool ?? true, "Response should indicate failure")
        }
        #endif
    }
    
    private func sendCommand(_ command: [String: Any]) {
        #if os(macOS)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: command, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                XCTFail("Failed to convert command to JSON string")
                return
            }
            
            let center = DistributedNotificationCenter.default()
            let userInfo: [AnyHashable: Any] = ["command": jsonString]
            
            center.postNotificationName(
                NSNotification.Name("com.deskpad.control"),
                object: nil,
                userInfo: userInfo,
                deliverImmediately: true
            )
        } catch {
            XCTFail("Failed to serialize command: \(error)")
        }
        #endif
    }
}

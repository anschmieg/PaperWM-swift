import XCTest
@testable import SocketHelper
import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

final class SocketHelperTests: XCTestCase {
    
    // MARK: - Test Socket Server
    
    /// A simple test socket server for testing SocketHelper
    class TestSocketServer {
        let socketPath: String
        private var serverFd: Int32 = -1
        private var isRunning = false
        private var serverQueue: DispatchQueue?
        
        /// Response to send when a request is received
        var responseHandler: (([String: Any]) -> [String: Any])?
        
        /// Delay before sending response (for timeout testing)
        var responseDelay: TimeInterval = 0
        
        /// Whether to send invalid JSON
        var sendInvalidJSON = false
        
        /// Whether to truncate response
        var truncateResponse = false
        
        init(socketPath: String) {
            self.socketPath = socketPath
        }
        
        func start() throws {
            // Clean up any existing socket
            try? FileManager.default.removeItem(atPath: socketPath)
            
            // Create socket
            #if os(Linux)
            serverFd = socket(AF_UNIX, Int32(SOCK_STREAM.rawValue), 0)
            #else
            serverFd = socket(AF_UNIX, SOCK_STREAM, 0)
            #endif
            guard serverFd >= 0 else {
                throw TestError.serverStartFailed("Failed to create socket")
            }
            
            // Build address
            var addr = sockaddr_un()
            addr.sun_family = sa_family_t(AF_UNIX)
            
            let maxPathLength = MemoryLayout.size(ofValue: addr.sun_path)
            let pathCString = socketPath.utf8CString
            
            guard pathCString.count <= maxPathLength else {
                throw TestError.serverStartFailed("Socket path too long")
            }
            
            withUnsafeMutablePointer(to: &addr.sun_path) { pathPtr in
                let buffer = UnsafeMutableRawPointer(pathPtr).assumingMemoryBound(to: CChar.self)
                pathCString.withUnsafeBufferPointer { cStringBuffer in
                    let copyLength = min(cStringBuffer.count, maxPathLength)
                    if let baseAddress = cStringBuffer.baseAddress {
                        memcpy(buffer, baseAddress, copyLength)
                    }
                    if copyLength < maxPathLength {
                        buffer[copyLength] = 0
                    } else {
                        buffer[maxPathLength - 1] = 0
                    }
                }
            }
            
            // Bind
            let addrLength = socklen_t(MemoryLayout.size(ofValue: addr))
            let bindResult = withUnsafePointer(to: &addr) { addrPtr -> Int32 in
                let sockaddrPtr = UnsafeRawPointer(addrPtr).assumingMemoryBound(to: sockaddr.self)
                return bind(serverFd, sockaddrPtr, addrLength)
            }
            
            guard bindResult == 0 else {
                close(serverFd)
                throw TestError.serverStartFailed("Failed to bind socket")
            }
            
            // Listen
            guard listen(serverFd, 10) == 0 else {
                close(serverFd)
                throw TestError.serverStartFailed("Failed to listen on socket")
            }
            
            isRunning = true
            
            // Start accepting connections on background queue
            serverQueue = DispatchQueue(label: "test.socket.server")
            serverQueue?.async { [weak self] in
                self?.acceptLoop()
            }
        }
        
        func stop() {
            isRunning = false
            if serverFd >= 0 {
                close(serverFd)
                serverFd = -1
            }
            try? FileManager.default.removeItem(atPath: socketPath)
        }
        
        private func acceptLoop() {
            while isRunning {
                var clientAddr = sockaddr_un()
                var clientAddrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
                
                let clientFd = withUnsafeMutablePointer(to: &clientAddr) { addrPtr -> Int32 in
                    let sockaddrPtr = UnsafeMutableRawPointer(addrPtr).assumingMemoryBound(to: sockaddr.self)
                    return accept(serverFd, sockaddrPtr, &clientAddrLen)
                }
                
                guard clientFd >= 0 else {
                    if !isRunning { break }
                    continue
                }
                
                // Handle client in background
                DispatchQueue.global().async { [weak self] in
                    self?.handleClient(clientFd: clientFd)
                }
            }
        }
        
        private func handleClient(clientFd: Int32) {
            defer { close(clientFd) }
            
            // Read request
            var requestData = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            
            while true {
                let bytesRead = read(clientFd, &buffer, buffer.count)
                if bytesRead > 0 {
                    requestData.append(buffer, count: bytesRead)
                } else if bytesRead == 0 {
                    // EOF
                    break
                } else {
                    // Error
                    return
                }
            }
            
            // Parse request
            guard let request = try? JSONSerialization.jsonObject(with: requestData) as? [String: Any] else {
                return
            }
            
            // Generate response
            let response: [String: Any]
            if let handler = responseHandler {
                response = handler(request)
            } else {
                // Default echo response
                response = ["echo": request]
            }
            
            // Apply delay if configured
            if responseDelay > 0 {
                Thread.sleep(forTimeInterval: responseDelay)
            }
            
            // Send response
            if sendInvalidJSON {
                // Send invalid JSON
                let invalidData = "not valid json".data(using: .utf8)!
                _ = invalidData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                    write(clientFd, ptr.baseAddress!, invalidData.count)
                }
            } else {
                guard let responseData = try? JSONSerialization.data(withJSONObject: response) else {
                    return
                }
                
                if truncateResponse {
                    // Send only partial response
                    let truncatedData = responseData.prefix(responseData.count / 2)
                    _ = truncatedData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                        write(clientFd, ptr.baseAddress!, truncatedData.count)
                    }
                } else {
                    // Send full response
                    responseData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                        var sent = 0
                        while sent < responseData.count {
                            let w = write(clientFd, ptr.baseAddress!.advanced(by: sent), responseData.count - sent)
                            if w <= 0 { break }
                            sent += w
                        }
                    }
                }
            }
        }
    }
    
    enum TestError: Error {
        case serverStartFailed(String)
    }
    
    // MARK: - Test Setup/Teardown
    
    var testSocketPath: String!
    var testServer: TestSocketServer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use unique socket path for each test
        testSocketPath = "/tmp/socket_helper_test_\(UUID().uuidString).sock"
        testServer = TestSocketServer(socketPath: testSocketPath)
    }
    
    override func tearDown() async throws {
        testServer?.stop()
        try? FileManager.default.removeItem(atPath: testSocketPath)
        try await super.tearDown()
    }
    
    // MARK: - Happy Path Tests
    
    func testHappyPathRoundTrip() async throws {
        // Setup server to echo requests
        testServer.responseHandler = { request in
            return ["result": "success", "request": request]
        }
        try testServer.start()
        
        // Create helper
        let config = SocketHelper.Configuration(
            socketPath: testSocketPath,
            connectTimeout: 0.5,
            readTimeout: 1.0
        )
        let helper = SocketHelper(configuration: config)
        
        // Send request
        let request: [String: Any] = ["command": "test", "value": 42]
        let response = try await helper.sendRequest(request)
        
        // Verify response
        XCTAssertEqual(response["result"] as? String, "success")
        XCTAssertNotNil(response["request"])
        
        if let requestEcho = response["request"] as? [String: Any] {
            XCTAssertEqual(requestEcho["command"] as? String, "test")
            XCTAssertEqual(requestEcho["value"] as? Int, 42)
        } else {
            XCTFail("Request echo not found in response")
        }
    }
    
    func testCreateCommand() async throws {
        // Setup server to handle create command
        testServer.responseHandler = { request in
            guard let command = request["command"] as? String, command == "create" else {
                return ["error": "unknown command"]
            }
            
            let display: [String: Any] = [
                "id": 1000,
                "width": request["width"] ?? 1920,
                "height": request["height"] ?? 1080,
                "name": request["name"] ?? "Test Display"
            ]
            
            return ["result": "created", "display": display]
        }
        try testServer.start()
        
        let config = SocketHelper.Configuration(socketPath: testSocketPath)
        let helper = SocketHelper(configuration: config)
        
        let request: [String: Any] = [
            "command": "create",
            "width": 2560,
            "height": 1440,
            "name": "My Display"
        ]
        
        let response = try await helper.sendRequest(request)
        
        XCTAssertEqual(response["result"] as? String, "created")
        
        if let display = response["display"] as? [String: Any] {
            XCTAssertEqual(display["id"] as? Int, 1000)
            XCTAssertEqual(display["width"] as? Int, 2560)
            XCTAssertEqual(display["height"] as? Int, 1440)
            XCTAssertEqual(display["name"] as? String, "My Display")
        } else {
            XCTFail("Display not found in response")
        }
    }
    
    func testListCommand() async throws {
        testServer.responseHandler = { request in
            guard let command = request["command"] as? String, command == "list" else {
                return ["error": "unknown command"]
            }
            
            let displays: [[String: Any]] = [
                ["id": 1000, "width": 1920, "height": 1080, "name": "Display 1"],
                ["id": 1001, "width": 2560, "height": 1440, "name": "Display 2"]
            ]
            
            return ["displays": displays]
        }
        try testServer.start()
        
        let config = SocketHelper.Configuration(socketPath: testSocketPath)
        let helper = SocketHelper(configuration: config)
        
        let response = try await helper.sendRequest(["command": "list"])
        
        XCTAssertNotNil(response["displays"])
        if let displays = response["displays"] as? [[String: Any]] {
            XCTAssertEqual(displays.count, 2)
            XCTAssertEqual(displays[0]["id"] as? Int, 1000)
            XCTAssertEqual(displays[1]["id"] as? Int, 1001)
        } else {
            XCTFail("Displays array not found in response")
        }
    }
    
    // MARK: - Connection Error Tests
    
    func testConnectTimeout() async throws {
        // Don't start server - socket doesn't exist
        let config = SocketHelper.Configuration(
            socketPath: testSocketPath,
            connectTimeout: 0.1,
            readTimeout: 1.0
        )
        let helper = SocketHelper(configuration: config)
        
        do {
            _ = try await helper.sendRequest(["command": "test"])
            XCTFail("Should have thrown connection error")
        } catch let error as SocketError {
            // Should get connection refused or timeout
            switch error {
            case .connectionRefused:
                // Expected - socket doesn't exist
                break
            case .connectTimeout:
                // Also acceptable
                break
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testConnectionRefused() async throws {
        // Create socket file but don't listen
        try testServer.start()
        testServer.stop()
        
        // Socket file still exists but no one is listening
        let config = SocketHelper.Configuration(
            socketPath: testSocketPath,
            connectTimeout: 0.1,
            readTimeout: 1.0
        )
        let helper = SocketHelper(configuration: config)
        
        do {
            _ = try await helper.sendRequest(["command": "test"])
            XCTFail("Should have thrown connection refused")
        } catch let error as SocketError {
            switch error {
            case .connectionRefused:
                // Expected
                break
            case .connectTimeout:
                // Also acceptable on some systems
                break
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Read Timeout Tests
    
    func testReadTimeout() async throws {
        // Server delays response longer than read timeout
        testServer.responseDelay = 2.0
        testServer.responseHandler = { _ in
            return ["result": "delayed"]
        }
        try testServer.start()
        
        let config = SocketHelper.Configuration(
            socketPath: testSocketPath,
            connectTimeout: 0.5,
            readTimeout: 0.2  // Short timeout
        )
        let helper = SocketHelper(configuration: config)
        
        do {
            _ = try await helper.sendRequest(["command": "test"])
            XCTFail("Should have thrown read timeout")
        } catch let error as SocketError {
            switch error {
            case .readTimeout:
                // Expected
                break
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Invalid Response Tests
    
    func testInvalidJSON() async throws {
        // Server sends invalid JSON
        testServer.sendInvalidJSON = true
        try testServer.start()
        
        let config = SocketHelper.Configuration(socketPath: testSocketPath)
        let helper = SocketHelper(configuration: config)
        
        do {
            _ = try await helper.sendRequest(["command": "test"])
            XCTFail("Should have thrown invalid JSON error")
        } catch let error as SocketError {
            switch error {
            case .invalidJSON:
                // Expected
                break
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testTruncatedResponse() async throws {
        // Server sends incomplete response
        testServer.truncateResponse = true
        testServer.responseHandler = { _ in
            // Return a large response that will be truncated
            return [
                "result": "success",
                "data": String(repeating: "x", count: 1000)
            ]
        }
        try testServer.start()
        
        let config = SocketHelper.Configuration(socketPath: testSocketPath)
        let helper = SocketHelper(configuration: config)
        
        do {
            _ = try await helper.sendRequest(["command": "test"])
            XCTFail("Should have thrown invalid JSON error due to truncation")
        } catch let error as SocketError {
            switch error {
            case .invalidJSON:
                // Expected - truncated JSON is invalid
                break
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Error Response Tests
    
    func testServerErrorResponse() async throws {
        // Server returns error response (valid JSON with error field)
        testServer.responseHandler = { _ in
            return ["error": "unknown command"]
        }
        try testServer.start()
        
        let config = SocketHelper.Configuration(socketPath: testSocketPath)
        let helper = SocketHelper(configuration: config)
        
        // This should succeed at the protocol level
        let response = try await helper.sendRequest(["command": "invalid"])
        
        // Response contains error
        XCTAssertEqual(response["error"] as? String, "unknown command")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyRequest() async throws {
        testServer.responseHandler = { request in
            return ["received": request.isEmpty]
        }
        try testServer.start()
        
        let config = SocketHelper.Configuration(socketPath: testSocketPath)
        let helper = SocketHelper(configuration: config)
        
        let response = try await helper.sendRequest([:])
        XCTAssertEqual(response["received"] as? Bool, true)
    }
    
    func testLargeResponse() async throws {
        // Test handling of large responses (multiple read calls)
        testServer.responseHandler = { _ in
            var largeResponse: [String: Any] = ["displays": []]
            var displays: [[String: Any]] = []
            
            // Create 100 displays to ensure response is larger than buffer
            for i in 0..<100 {
                displays.append([
                    "id": 1000 + i,
                    "width": 1920,
                    "height": 1080,
                    "name": "Display \(i)"
                ])
            }
            
            largeResponse["displays"] = displays
            return largeResponse
        }
        try testServer.start()
        
        let config = SocketHelper.Configuration(socketPath: testSocketPath)
        let helper = SocketHelper(configuration: config)
        
        let response = try await helper.sendRequest(["command": "list"])
        
        if let displays = response["displays"] as? [[String: Any]] {
            XCTAssertEqual(displays.count, 100)
        } else {
            XCTFail("Displays not found in response")
        }
    }
    
    func testMultipleSequentialRequests() async throws {
        // Test that helper can be used for multiple requests
        testServer.responseHandler = { request in
            if let value = request["counter"] as? Int {
                return ["counter": value + 1]
            }
            return ["error": "no counter"]
        }
        try testServer.start()
        
        let config = SocketHelper.Configuration(socketPath: testSocketPath)
        let helper = SocketHelper(configuration: config)
        
        // Send multiple requests sequentially
        for i in 0..<5 {
            let response = try await helper.sendRequest(["counter": i])
            XCTAssertEqual(response["counter"] as? Int, i + 1)
        }
    }
    
    func testConcurrentRequests() async throws {
        // Test multiple concurrent requests (should each get their own connection)
        testServer.responseHandler = { request in
            if let value = request["value"] as? Int {
                return ["result": value * 2]
            }
            return ["error": "no value"]
        }
        try testServer.start()
        
        let config = SocketHelper.Configuration(socketPath: testSocketPath)
        let helper = SocketHelper(configuration: config)
        
        // Send concurrent requests
        await withTaskGroup(of: (Int, Int?).self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        let response = try await helper.sendRequest(["value": i])
                        return (i, response["result"] as? Int)
                    } catch {
                        return (i, nil)
                    }
                }
            }
            
            // Verify all results
            for await (input, result) in group {
                XCTAssertEqual(result, input * 2)
            }
        }
    }
}

import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// SocketHelper provides an async API for communicating with a Unix domain socket server
/// using JSON request/response protocol.
///
/// The helper connects to an AF_UNIX socket, sends a JSON payload, performs a half-close
/// to signal end of request, reads the response until EOF, and returns parsed JSON.
///
/// Usage:
/// ```swift
/// let helper = SocketHelper()
/// let request = ["command": "list"]
/// do {
///     let response = try await helper.sendRequest(request)
///     print("Response: \(response)")
/// } catch SocketError.connectTimeout {
///     print("Connection timed out")
/// } catch {
///     print("Error: \(error)")
/// }
/// ```
public struct SocketHelper {
    /// Default socket path for DeskPad listener
    public static let defaultSocketPath = "/tmp/deskpad.sock"
    
    /// Configuration for socket communication
    public struct Configuration {
        /// Path to the Unix domain socket
        public let socketPath: String
        
        /// Timeout for connection attempt in seconds
        public let connectTimeout: TimeInterval
        
        /// Timeout for reading response in seconds
        public let readTimeout: TimeInterval
        
        /// Creates a configuration with specified parameters
        ///
        /// - Parameters:
        ///   - socketPath: Path to Unix socket (default: /tmp/deskpad.sock)
        ///   - connectTimeout: Connection timeout in seconds (default: 0.5)
        ///   - readTimeout: Read timeout in seconds (default: 1.0)
        public init(
            socketPath: String = SocketHelper.defaultSocketPath,
            connectTimeout: TimeInterval = 0.5,
            readTimeout: TimeInterval = 1.0
        ) {
            self.socketPath = socketPath
            self.connectTimeout = connectTimeout
            self.readTimeout = readTimeout
        }
    }
    
    /// Configuration for this helper instance
    public let configuration: Configuration
    
    /// Creates a new SocketHelper with the specified configuration
    ///
    /// - Parameter configuration: Socket configuration (uses defaults if not specified)
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }
    
    /// Sends a JSON request to the socket and returns the parsed JSON response
    ///
    /// This method performs the following steps:
    /// 1. Connects to the Unix socket (with timeout)
    /// 2. Serializes and sends the request JSON
    /// 3. Performs half-close (shutdown write side) to signal end of request
    /// 4. Reads response until EOF (with timeout)
    /// 5. Parses and returns response JSON
    ///
    /// - Parameter request: Dictionary representing the JSON request
    /// - Returns: Dictionary representing the JSON response
    /// - Throws: SocketError for connection, communication, or parsing errors
    public func sendRequest(_ request: [String: Any]) async throws -> [String: Any] {
        // Serialize request to JSON
        let requestData: Data
        do {
            requestData = try JSONSerialization.data(withJSONObject: request, options: [])
        } catch {
            throw SocketError.serializationFailed("Failed to serialize request: \(error.localizedDescription)")
        }
        
        // Perform socket communication on a background thread to avoid blocking
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try self.sendRequestSync(requestData)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Synchronous implementation of socket communication
    /// Called from background thread to avoid blocking the caller
    private func sendRequestSync(_ requestData: Data) throws -> [String: Any] {
        // Create socket
        #if os(Linux)
        let fd = socket(AF_UNIX, Int32(SOCK_STREAM.rawValue), 0)
        #else
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        #endif
        guard fd >= 0 else {
            throw SocketError.socketCreationFailed("Failed to create socket: errno \(errno)")
        }
        
        // Ensure socket is closed on exit
        defer { close(fd) }
        
        // Set socket to non-blocking mode for timeout support
        let flags = fcntl(fd, F_GETFL, 0)
        guard fcntl(fd, F_SETFL, flags | O_NONBLOCK) != -1 else {
            throw SocketError.socketCreationFailed("Failed to set non-blocking mode: errno \(errno)")
        }
        
        // Build sockaddr_un structure
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        
        // Copy socket path into sun_path
        let maxPathLength = MemoryLayout.size(ofValue: addr.sun_path)
        let pathCString = configuration.socketPath.utf8CString
        
        guard pathCString.count <= maxPathLength else {
            throw SocketError.invalidSocketPath("Socket path too long: \(configuration.socketPath)")
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
        
        // Attempt connection with timeout
        let addrLength = socklen_t(MemoryLayout.size(ofValue: addr))
        let connectResult = withUnsafePointer(to: &addr) { addrPtr -> Int32 in
            let sockaddrPtr = UnsafeRawPointer(addrPtr).assumingMemoryBound(to: sockaddr.self)
            return connect(fd, sockaddrPtr, addrLength)
        }
        
        // Handle connection result
        if connectResult == 0 {
            // Connected immediately
        } else if errno == EINPROGRESS {
            // Connection in progress, wait for completion
            try waitForConnect(fd: fd, timeout: configuration.connectTimeout)
        } else if errno == ENOENT {
            // Socket file doesn't exist
            throw SocketError.connectionRefused("Socket not found at \(configuration.socketPath)")
        } else if errno == ECONNREFUSED {
            throw SocketError.connectionRefused("Connection refused to \(configuration.socketPath)")
        } else {
            throw SocketError.connectionFailed("Connect failed: errno \(errno)")
        }
        
        // Send request data
        try sendData(fd: fd, data: requestData)
        
        // Shutdown write side to signal EOF to server
        shutdown(fd, Int32(SHUT_WR))
        
        // Read response with timeout
        let responseData = try readResponse(fd: fd, timeout: configuration.readTimeout)
        
        // Parse JSON response
        guard let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            let preview = String(data: responseData.prefix(100), encoding: .utf8) ?? "<binary data>"
            throw SocketError.invalidJSON("Failed to parse response as JSON. Data preview: \(preview)")
        }
        
        return response
    }
    
    /// Waits for socket connection to complete with timeout
    private func waitForConnect(fd: Int32, timeout: TimeInterval) throws {
        var readSet = fd_set()
        var writeSet = fd_set()
        
        // Initialize fd_sets
        fdZero(&readSet)
        fdZero(&writeSet)
        fdSet(fd, &writeSet)
        
        // Setup timeout
        var timeoutVal = timeval()
        timeoutVal.tv_sec = Int(timeout)
        timeoutVal.tv_usec = Int((timeout.truncatingRemainder(dividingBy: 1.0)) * 1_000_000)
        
        // Wait for socket to become writable (connection complete)
        let selectResult = select(fd + 1, &readSet, &writeSet, nil, &timeoutVal)
        
        if selectResult < 0 {
            throw SocketError.connectionFailed("Select failed: errno \(errno)")
        } else if selectResult == 0 {
            throw SocketError.connectTimeout("Connection timed out after \(timeout) seconds")
        }
        
        // Check for connection errors
        var error: Int32 = 0
        var errorLength = socklen_t(MemoryLayout<Int32>.size)
        guard getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &errorLength) == 0 else {
            throw SocketError.connectionFailed("Failed to get socket error: errno \(errno)")
        }
        
        if error != 0 {
            if error == ECONNREFUSED {
                throw SocketError.connectionRefused("Connection refused")
            } else {
                throw SocketError.connectionFailed("Connection failed with error: \(error)")
            }
        }
    }
    
    /// Sends data to the socket
    private func sendData(fd: Int32, data: Data) throws {
        var sent = 0
        let bytes = [UInt8](data)
        
        while sent < bytes.count {
            let result = bytes.withUnsafeBufferPointer { buffer -> Int in
                let ptr = buffer.baseAddress!.advanced(by: sent)
                return write(fd, ptr, bytes.count - sent)
            }
            
            if result < 0 {
                if errno == EINTR {
                    // Interrupted, retry
                    continue
                } else if errno == EAGAIN || errno == EWOULDBLOCK {
                    // Would block, wait briefly and retry
                    usleep(10_000) // 10ms
                    continue
                } else {
                    throw SocketError.sendFailed("Write failed: errno \(errno)")
                }
            } else if result == 0 {
                throw SocketError.sendFailed("Socket closed during write")
            }
            
            sent += result
        }
    }
    
    /// Reads response from socket with timeout
    private func readResponse(fd: Int32, timeout: TimeInterval) throws -> Data {
        var responseData = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        let startTime = Date()
        
        while true {
            // Check timeout
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed > timeout {
                throw SocketError.readTimeout("Read timed out after \(timeout) seconds")
            }
            
            // Calculate remaining timeout
            let remainingTimeout = timeout - elapsed
            
            // Use select to wait for data with timeout
            var readSet = fd_set()
            fdZero(&readSet)
            fdSet(fd, &readSet)
            
            var timeoutVal = timeval()
            timeoutVal.tv_sec = Int(remainingTimeout)
            timeoutVal.tv_usec = Int((remainingTimeout.truncatingRemainder(dividingBy: 1.0)) * 1_000_000)
            
            let selectResult = select(fd + 1, &readSet, nil, nil, &timeoutVal)
            
            if selectResult < 0 {
                if errno == EINTR {
                    continue
                }
                throw SocketError.readFailed("Select failed during read: errno \(errno)")
            } else if selectResult == 0 {
                throw SocketError.readTimeout("Read timed out after \(timeout) seconds")
            }
            
            // Data available, read it
            let bytesRead = read(fd, &buffer, buffer.count)
            
            if bytesRead > 0 {
                responseData.append(buffer, count: bytesRead)
            } else if bytesRead == 0 {
                // EOF - response complete
                break
            } else {
                if errno == EINTR {
                    continue
                } else if errno == EAGAIN || errno == EWOULDBLOCK {
                    // Shouldn't happen after select, but handle it
                    continue
                } else {
                    throw SocketError.readFailed("Read failed: errno \(errno)")
                }
            }
        }
        
        return responseData
    }
    
    // MARK: - fd_set helpers
    
    private func fdZero(_ set: inout fd_set) {
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        set.fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        #else
        // Linux: manually zero the fd_set
        set.__fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        #endif
    }
    
    private func fdSet(_ fd: Int32, _ set: inout fd_set) {
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        let intOffset = Int(fd / 32)
        let bitOffset = Int(fd % 32)
        let mask = Int32(1 << bitOffset)
        
        withUnsafeMutablePointer(to: &set.fds_bits) { ptr in
            let buffer = UnsafeMutableBufferPointer(start: ptr, count: 32)
            buffer[intOffset] |= mask
        }
        #else
        // Linux: set the bit in the fd_set tuple
        let bitsPerInt = MemoryLayout<Int>.size * 8
        let intOffset = Int(fd) / bitsPerInt
        let bitOffset = Int(fd) % bitsPerInt
        let mask = 1 << bitOffset
        
        withUnsafeMutablePointer(to: &set.__fds_bits) { ptr in
            let rawPtr = UnsafeMutableRawPointer(ptr)
            let intArray = rawPtr.assumingMemoryBound(to: Int.self)
            intArray[intOffset] |= mask
        }
        #endif
    }
}

/// Errors that can occur during socket communication
public enum SocketError: Error, CustomStringConvertible, Equatable {
    case socketCreationFailed(String)
    case invalidSocketPath(String)
    case connectTimeout(String)
    case connectionRefused(String)
    case connectionFailed(String)
    case sendFailed(String)
    case readTimeout(String)
    case readFailed(String)
    case invalidJSON(String)
    case serializationFailed(String)
    
    public var description: String {
        switch self {
        case .socketCreationFailed(let message):
            return "Socket creation failed: \(message)"
        case .invalidSocketPath(let message):
            return "Invalid socket path: \(message)"
        case .connectTimeout(let message):
            return "Connect timeout: \(message)"
        case .connectionRefused(let message):
            return "Connection refused: \(message)"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .sendFailed(let message):
            return "Send failed: \(message)"
        case .readTimeout(let message):
            return "Read timeout: \(message)"
        case .readFailed(let message):
            return "Read failed: \(message)"
        case .invalidJSON(let message):
            return "Invalid JSON: \(message)"
        case .serializationFailed(let message):
            return "Serialization failed: \(message)"
        }
    }
}

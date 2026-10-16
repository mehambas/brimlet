import Foundation
import Darwin
import Security
@_exported import BrimletCore

public enum DeliveryStatus: String, Codable, Sendable {
    case displayed, duplicate, busy, unavailable, unauthorized, invalid
    public var delivered: Bool { self == .displayed || self == .duplicate }
}

/// Pin the designated requirement of an application explicitly chosen by the user.
public enum ApplicationIdentity {
    public static func requirement(at url: URL) throws -> String {
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess, let code,
              SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSCheckAllArchitectures), nil) == errSecSuccess else {
            throw CocoaError(.fileReadNoPermission)
        }
        var requirement: SecRequirement?
        var text: CFString?
        guard SecCodeCopyDesignatedRequirement(code, [], &requirement) == errSecSuccess, let requirement,
              SecRequirementCopyString(requirement, [], &text) == errSecSuccess, let text else {
            throw CocoaError(.fileReadNoPermission)
        }
        return text as String
    }

    static func matches(socket: Int32, requirement: String) -> Bool {
        var token = audit_token_t()
        var size = socklen_t(MemoryLayout.size(ofValue: token))
        guard getsockopt(socket, SOL_LOCAL, LOCAL_PEERTOKEN, &token, &size) == 0,
              size == MemoryLayout.size(ofValue: token) else { return false }
        var uid: uid_t = 0
        var gid: gid_t = 0
        guard getpeereid(socket, &uid, &gid) == 0, uid == getuid() else { return false }
        let data = withUnsafeBytes(of: token) { Data($0) }
        var code: SecCode?
        var rule: SecRequirement?
        guard SecCodeCopyGuestWithAttributes(nil, [kSecGuestAttributeAudit: data] as CFDictionary, [], &code) == errSecSuccess,
              let code, SecRequirementCreateWithString(requirement as CFString, [], &rule) == errSecSuccess,
              let rule else { return false }
        return SecCodeCheckValidity(code, [], rule) == errSecSuccess
    }
}

public enum LocalNotificationChannel {
    // getpwuid resolves the real home even in the sender's App Sandbox container.
    public static var socketPath: String {
        guard let home = getpwuid(getuid())?.pointee.pw_dir else { return "" }
        return String(cString: home) + "/Library/Application Support/Brimlet/notification.sock"
    }

    public static func send(_ value: ExternalNotification, receiverRequirement: String,
                            path: String = socketPath) async -> DeliveryStatus {
        await Task.detached(priority: .utility) {
            guard value.isValid, let payload = try? value.encoded() else { return .invalid }
            let fd = socket(AF_UNIX, SOCK_STREAM, 0)
            guard fd >= 0 else { return .unavailable }
            defer { close(fd) }
            configure(fd)
            _ = fcntl(fd, F_SETFL, O_NONBLOCK)
            let connected = withAddress(path) { Darwin.connect(fd, $0, $1) }
            if connected != 0 {
                guard errno == EINPROGRESS else { return .unavailable }
                var wait = pollfd(fd: fd, events: Int16(POLLOUT), revents: 0)
                var error: Int32 = 0
                var size = socklen_t(MemoryLayout.size(ofValue: error))
                guard poll(&wait, 1, 2000) > 0,
                      getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &size) == 0, error == 0 else { return .unavailable }
            }
            _ = fcntl(fd, F_SETFL, 0)
            guard ApplicationIdentity.matches(socket: fd, requirement: receiverRequirement) else { return .unauthorized }
            guard writeFrame(payload, to: fd), let response = readFrame(from: fd),
                  let status = try? JSONDecoder().decode(DeliveryStatus.self, from: response) else { return .unavailable }
            return status
        }.value
    }

    static func configure(_ fd: Int32) {
        // accept() inherits O_NONBLOCK from the listener on Darwin.
        _ = fcntl(fd, F_SETFL, 0)
        var timeout = timeval(tv_sec: 2, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout.size(ofValue: timeout)))
        setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout.size(ofValue: timeout)))
        var enabled: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &enabled, socklen_t(MemoryLayout.size(ofValue: enabled)))
        _ = fcntl(fd, F_SETFD, FD_CLOEXEC)
    }

    static func withAddress(_ path: String, _ body: (UnsafePointer<sockaddr>, socklen_t) -> Int32) -> Int32 {
        var address = sockaddr_un()
        let bytes = Array(path.utf8) + [0]
        guard !path.isEmpty, bytes.count <= MemoryLayout.size(ofValue: address.sun_path) else { return -1 }
        address.sun_family = sa_family_t(AF_UNIX)
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        withUnsafeMutableBytes(of: &address.sun_path) { $0.copyBytes(from: bytes) }
        return withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { body($0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
        }
    }

    static func readFrame(from fd: Int32) -> Data? {
        guard let header = readExactly(4, from: fd) else { return nil }
        let size = header.reduce(0) { ($0 << 8) | Int($1) }
        guard size > 0, size <= 8192 else { return nil }
        return readExactly(size, from: fd)
    }

    private static func readExactly(_ count: Int, from fd: Int32) -> Data? {
        var data = Data(count: count)
        let success = data.withUnsafeMutableBytes { buffer -> Bool in
            var offset = 0
            let deadline = Date().addingTimeInterval(2)
            while offset < count, Date() < deadline {
                let result = recv(fd, buffer.baseAddress!.advanced(by: offset), count - offset, 0)
                guard result > 0 else { return false }
                offset += result
            }
            return offset == count
        }
        return success ? data : nil
    }

    static func writeFrame(_ data: Data, to fd: Int32) -> Bool {
        guard !data.isEmpty, data.count <= 8192 else { return false }
        var length = UInt32(data.count).bigEndian
        var frame = withUnsafeBytes(of: &length) { Data($0) }
        frame.append(data)
        return frame.withUnsafeBytes { buffer in
            var offset = 0
            while offset < frame.count {
                let sent = Darwin.send(fd, buffer.baseAddress!.advanced(by: offset), frame.count - offset, 0)
                guard sent > 0 else { return false }
                offset += sent
            }
            return true
        }
    }
}

/// Bounded, serial local transport. No network listener, app launching or notification storage.
public final class LocalNotificationServer: @unchecked Sendable {
    private var source: DispatchSourceRead?
    private let queue = DispatchQueue(label: "com.hamzabasaran.brimlet.notifications")
    private let path: String
    public init(path: String = LocalNotificationChannel.socketPath) { self.path = path }

    public func start(requirements: @escaping @Sendable () -> [String: String], receive: @escaping @Sendable (ExternalNotification, Date) -> DeliveryStatus) throws {
        guard source == nil, !path.isEmpty else { throw CocoaError(.fileWriteUnknown) }
        let directory = URL(fileURLWithPath: path).deletingLastPathComponent().path
        if mkdir(directory, 0o700) != 0 && errno != EEXIST { throw CocoaError(.fileWriteNoPermission) }
        var info = stat()
        guard lstat(directory, &info) == 0, info.st_uid == getuid(),
              info.st_mode & S_IFMT == S_IFDIR, info.st_mode & 0o077 == 0 else { throw CocoaError(.fileWriteNoPermission) }
        if lstat(path, &info) == 0 {
            guard info.st_uid == getuid(), info.st_mode & S_IFMT == S_IFSOCK else { throw CocoaError(.fileWriteNoPermission) }
            let probe = socket(AF_UNIX, SOCK_STREAM, 0)
            guard probe >= 0 else { throw CocoaError(.fileWriteUnknown) }
            let result = LocalNotificationChannel.withAddress(path) { Darwin.connect(probe, $0, $1) }
            let error = errno
            close(probe)
            guard result != 0, error == ECONNREFUSED else { throw CocoaError(.fileWriteFileExists) }
            guard unlink(path) == 0 else { throw CocoaError(.fileWriteNoPermission) }
        }
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw CocoaError(.fileWriteUnknown) }
        guard LocalNotificationChannel.withAddress(path, { Darwin.bind(fd, $0, $1) }) == 0 else {
            close(fd); throw CocoaError(.fileWriteUnknown)
        }
        guard chmod(path, 0o600) == 0, listen(fd, 4) == 0 else {
            close(fd); unlink(path); throw CocoaError(.fileWriteUnknown)
        }
        _ = fcntl(fd, F_SETFL, O_NONBLOCK)
        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        source.setEventHandler {
            let peer = accept(fd, nil, nil)
            guard peer >= 0 else { return }
            defer { close(peer) }
            LocalNotificationChannel.configure(peer)
            var status: DeliveryStatus = .invalid
            if let data = LocalNotificationChannel.readFrame(from: peer), let value = try? ExternalNotification.decode(data) {
                let deadline = Date().addingTimeInterval(1)
                if let rule = requirements()[value.sourceBundleID], ApplicationIdentity.matches(socket: peer, requirement: rule) {
                    status = Date() < deadline ? receive(value, deadline) : .unavailable
                } else { status = .unauthorized }
            }
            if let data = try? JSONEncoder().encode(status) { _ = LocalNotificationChannel.writeFrame(data, to: peer) }
        }
        // Leave the socket inode on shutdown; the next start removes only a stale owned socket.
        source.setCancelHandler { close(fd) }
        self.source = source
        source.resume()
    }

    public func stop() { source?.cancel(); source = nil }
    deinit { source?.cancel() }
}

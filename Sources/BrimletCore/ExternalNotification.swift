import Foundation

public enum ExternalNotificationPriority: Int, Codable, Sendable, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
}

public enum ExternalNotificationFallback: String, Codable, Sendable {
    case systemNotification
    case senderDefault
    case drop
}

/// Versioned payload shared by local applications that want to present a short event in Brimlet.
public struct ExternalNotification: Codable, Equatable, Identifiable, Sendable {
    public static let protocolVersion = 1
    public let id: UUID
    public let version: Int
    public let sourceBundleID: String
    public let title: String
    public let body: String
    public let symbol: String
    public let priority: ExternalNotificationPriority
    public let duration: TimeInterval
    public let fallback: ExternalNotificationFallback

    public init(id: UUID = UUID(), sourceBundleID: String, title: String, body: String,
                symbol: String = "bell.fill", priority: ExternalNotificationPriority = .normal,
                duration: TimeInterval = 5, fallback: ExternalNotificationFallback = .systemNotification) {
        self.id = id
        self.version = Self.protocolVersion
        self.sourceBundleID = sourceBundleID
        self.title = title
        self.body = body
        self.symbol = symbol
        self.priority = priority
        self.duration = duration
        self.fallback = fallback
    }

    public var isValid: Bool {
        version == Self.protocolVersion && sourceBundleID.count >= 3 && sourceBundleID.count <= 200
            && sourceBundleID.contains(".") && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && title.count <= 120 && body.count <= 500 && duration >= 1 && duration <= 30
            && !symbol.isEmpty && symbol.count <= 80
    }

    public func encoded() throws -> Data { try JSONEncoder().encode(self) }
    public static func decode(_ data: Data) throws -> ExternalNotification {
        guard data.count <= 8192 else { throw CocoaError(.fileReadTooLarge) }
        let value = try JSONDecoder().decode(Self.self, from: data)
        guard value.isValid else {
            throw NSError(domain: "Brimlet.ExternalNotification", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid external notification"])
        }
        return value
    }
}

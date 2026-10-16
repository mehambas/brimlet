import Foundation

public enum ModuleID: String, CaseIterable, Codable, Identifiable, Sendable {
    case music, timer, calendar, todos
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .music: return String(localized: "Music")
        case .timer: return String(localized: "Timer")
        case .calendar: return String(localized: "Calendar")
        case .todos: return String(localized: "Tasks")
        }
    }
    public var symbol: String {
        switch self { case .music: return "music.note"; case .timer: return "timer"; case .calendar: return "calendar"; case .todos: return "checklist" }
    }
}

/// Modules publish activities, not windows. The shell owns presentation and priority.
public struct Activity: Equatable, Identifiable, Sendable {
    public let module: ModuleID
    public var title: String
    public var subtitle: String
    public var progress: Double?
    public var isActive: Bool
    public var id: ModuleID { module }

    public init(module: ModuleID, title: String, subtitle: String, progress: Double? = nil, isActive: Bool) {
        self.module = module
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.isActive = isActive
    }
}

public struct ActivityRouter: Sendable {
    public var order: [ModuleID] = ModuleID.allCases
    public var enabled: Set<ModuleID> = Set(ModuleID.allCases)
    public var selected: ModuleID?
    public var pinned: ModuleID?
    public var transient: ModuleID?
    public var transientUntil: Date?

    public init() {}

    public func visible(activities: [Activity], at now: Date, expanded: Bool) -> ModuleID? {
        let available = order.filter { enabled.contains($0) }
        // Explicit navigation always wins in the expanded view.
        if expanded, let selected, available.contains(selected) { return selected }
        if let transient, let end = transientUntil, end > now, available.contains(transient) { return transient }
        if let pinned, available.contains(pinned) { return pinned }
        if let active = available.first(where: { id in activities.contains { $0.module == id && $0.isActive } }) {
            return active
        }
        return available.first
    }

    public mutating func showTemporarily(_ module: ModuleID, at now: Date, duration: TimeInterval) {
        transient = module
        transientUntil = now.addingTimeInterval(duration)
    }

    public static func normalizedOrder(_ raw: [String]) -> [ModuleID] {
        var result: [ModuleID] = []
        for value in raw {
            if let id = ModuleID(rawValue: value), !result.contains(id) { result.append(id) }
        }
        return result + ModuleID.allCases.filter { !result.contains($0) }
    }
}

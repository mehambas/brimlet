import Foundation

public struct CalendarEvent: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let calendarTitle: String
    public let start: Date
    public let end: Date
    public let isAllDay: Bool
    public let meetingURL: URL?
    public let calendarID: String
    public let itemIdentifier: String
    public let occurrenceDate: Date?

    public init(id: String, title: String, calendarTitle: String, start: Date, end: Date,
                isAllDay: Bool = false, meetingURL: URL? = nil, calendarID: String = "",
                itemIdentifier: String = "", occurrenceDate: Date? = nil) {
        self.id = id
        self.title = title
        self.calendarTitle = calendarTitle
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.meetingURL = meetingURL
        self.calendarID = calendarID
        self.itemIdentifier = itemIdentifier
        self.occurrenceDate = occurrenceDate
    }

    public func status(at now: Date) -> String {
        if isAllDay { return String(localized: "All day") }
        if start <= now { return end > now ? String(localized: "In progress") : String(localized: "Ended") }
        let minutes = Int(ceil(start.timeIntervalSince(now) / 60))
        if minutes < 60 { return String(localized: "in \(minutes) min") }
        let hours = minutes / 60, remainder = minutes % 60
        return remainder == 0 ? String(localized: "in \(hours) h") : String(localized: "in \(hours) h \(remainder) min")
    }

    public static func upcoming(_ events: [CalendarEvent], at now: Date) -> [CalendarEvent] {
        events.filter { $0.end > now && $0.start < now.addingTimeInterval(86400) }
            .sorted {
                if $0.isAllDay != $1.isAllDay { return !$0.isAllDay }
                if $0.start != $1.start { return $0.start < $1.start }
                return $0.id < $1.id
            }
    }

    /// Only recognizable HTTPS meeting links become join actions. Other event links remain in Calendar.
    public static func meetingLink(in fields: [String]) -> URL? {
        let hosts = ["meet.google.com", "zoom.us", "teams.microsoft.com", "teams.live.com", "teams.cloud.microsoft", "webex.com"]
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        for field in fields {
            for match in detector.matches(in: field, range: NSRange(field.startIndex..., in: field)) {
                guard let url = match.url, url.scheme?.lowercased() == "https", let host = url.host?.lowercased(),
                      url.user == nil, url.password == nil,
                      hosts.contains(where: { host == $0 || host.hasSuffix("." + $0) }) else { continue }
                return url
            }
        }
        return nil
    }
}

public enum AgendaRange: String, CaseIterable, Identifiable, Sendable {
    case today, tomorrow, week
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .today: return String(localized: "Today")
        case .tomorrow: return String(localized: "Tomorrow")
        case .week: return String(localized: "7 days")
        }
    }
    public func interval(at now: Date, calendar: Calendar = .current) -> DateInterval {
        let today = calendar.startOfDay(for: now)
        let start = self == .tomorrow ? calendar.date(byAdding: .day, value: 1, to: today)! : today
        let end = calendar.date(byAdding: .day, value: self == .week ? 7 : 1, to: start)!
        return DateInterval(start: start, end: end)
    }
}

public extension CalendarEvent {
    static func agenda(_ events: [CalendarEvent], range: AgendaRange, at now: Date,
                       calendar: Calendar = .current) -> [CalendarEvent] {
        let interval = range.interval(at: now, calendar: calendar)
        return events.filter { $0.start < interval.end && $0.end > interval.start }
            .sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }
    }

    var calendarURL: URL? {
        guard !itemIdentifier.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        var components = URLComponents()
        components.scheme = "ical"
        components.host = "ekevent"
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        guard let identifier = itemIdentifier.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        components.percentEncodedPath = "/" + formatter.string(from: occurrenceDate ?? start) + "/" + identifier
        components.queryItems = [URLQueryItem(name: "method", value: "show"), URLQueryItem(name: "options", value: "more")]
        return components.url
    }
}

/// Reminders are per occurrence, never repeated by polling, and never delivered after start.
public struct CalendarReminderTracker {
    private var delivered: [String: Date] = [:]
    public init() {}
    public mutating func due(in events: [CalendarEvent], at now: Date, minutes: Int) -> [CalendarEvent] {
        delivered = delivered.filter { $0.value > now }
        guard minutes > 0 else { return [] }
        let due = events.filter {
            !$0.isAllDay && $0.start > now && $0.start.timeIntervalSince(now) <= Double(minutes * 60)
                && delivered[$0.id] == nil
        }.sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }
        for event in due { delivered[event.id] = event.start }
        return due
    }
}

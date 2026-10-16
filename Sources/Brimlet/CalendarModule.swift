import AppKit
import Combine
import EventKit
import BrimletCore

struct CalendarSource: Identifiable, Sendable {
    let id: String
    let title: String
    let account: String
}

private actor CalendarStore {
    private var store: EKEventStore?
    private func eventStore() -> EKEventStore {
        if let store { return store }
        let value = EKEventStore()
        store = value
        return value
    }

    func requestAccess() async throws -> Bool {
        try await eventStore().requestFullAccessToEvents()
    }

    func calendars() -> [CalendarSource] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }
        return eventStore().calendars(for: .event).map {
            CalendarSource(id: $0.calendarIdentifier, title: $0.title, account: $0.source.title)
        }.sorted { ($0.account, $0.title, $0.id) < ($1.account, $1.title, $1.id) }
    }

    func events(at now: Date, selected: [String]?) -> [CalendarEvent] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }
        let store = eventStore()
        let calendars = store.calendars(for: .event).filter { selected == nil || selected!.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }
        let interval = AgendaRange.week.interval(at: now)
        let predicate = store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: calendars)
        return store.events(matching: predicate).compactMap { event in
            guard event.status != .canceled,
                  !event.attendeesContainsDeclinedCurrentUser,
                  let start = event.startDate, let end = event.endDate else { return nil }
            return CalendarEvent(id: "\(event.calendarItemIdentifier):\(start.timeIntervalSince1970)",
                                 title: event.title?.isEmpty == false ? event.title! : String(localized: "Untitled event"),
                                 calendarTitle: event.calendar.title, start: start, end: end,
                                 isAllDay: event.isAllDay,
                                 meetingURL: CalendarEvent.meetingLink(in: [event.url?.absoluteString ?? "", event.location ?? "", event.notes ?? ""]),
                                 calendarID: event.calendar.calendarIdentifier,
                                 itemIdentifier: event.calendarItemIdentifier, occurrenceDate: event.occurrenceDate)
        }
    }
}

private extension EKEvent {
    var attendeesContainsDeclinedCurrentUser: Bool {
        attendees?.contains { $0.isCurrentUser && $0.participantStatus == .declined } == true
    }
}

@MainActor final class CalendarModule: IslandModule {
    enum Access: Equatable { case notRequested, requesting, ready, denied, restricted, failed }
    let id: ModuleID = .calendar
    @Published private(set) var access: Access = .notRequested
    @Published private(set) var events: [CalendarEvent] = []
    @Published private(set) var calendars: [CalendarSource] = []
    @Published var agendaRange: AgendaRange = .today
    @Published private(set) var reminderEvents: [CalendarEvent] = []
    var onReminder: (() -> Void)?
    private var selectedCalendars: [String]?
    private var reminderMinutes = 5
    private var reminderTracker = CalendarReminderTracker()
    @Published private(set) var now = Date()
    @Published private(set) var loading = false
    @Published private(set) var actionError: String?
    private let store = CalendarStore()
    private let demo: Bool
    private var enabled = false
    private var ticker: Timer?
    private var observer: AnyCancellable?
    private var generation = 0
    private var lastFetch = Date.distantPast

    init(demo: Bool = false) { self.demo = demo }

    var agenda: [CalendarEvent] { CalendarEvent.agenda(events, range: agendaRange, at: now) }
    var reminderEvent: CalendarEvent? { reminderEvents.first }
    var upcoming: [CalendarEvent] { CalendarEvent.upcoming(events, at: now) }
    var next: CalendarEvent? { upcoming.first }
    var activity: Activity {
        let next = reminderEvent ?? next
        return Activity(module: id, title: next?.title ?? String(localized: "Calendar"), subtitle: next?.status(at: now) ?? String(localized: "No upcoming events"),
                 isActive: enabled && next.map { !$0.isAllDay && $0.start.timeIntervalSince(now) <= 900 } == true)
    }
    var compactText: String {
        guard let next = reminderEvent ?? next else { return "—" }
        if next.isAllDay { return String(localized: "Day") }
        if next.start <= now { return String(localized: "Now") }
        let minutes = Int(ceil(next.start.timeIntervalSince(now) / 60))
        return minutes < 60 ? String(localized: "\(minutes) min") : String(localized: "\(Int(ceil(Double(minutes) / 60))) h")
    }

    func configure(selected: [String]?, reminderMinutes: Int) {
        let changed = selectedCalendars != selected
        selectedCalendars = selected
        self.reminderMinutes = [0, 5, 10].contains(reminderMinutes) ? reminderMinutes : 5
        if changed {
            events = []
            reminderEvents = []
            refresh()
        }
        if self.reminderMinutes == 0 { reminderEvents = [] }
    }

    private func checkReminders() {
        reminderEvents = reminderEvents.compactMap { old in
            events.first { $0.id == old.id && $0.start > now }
        }
        guard enabled, access == .ready, reminderMinutes > 0 else { reminderEvents = []; return }
        let due = reminderTracker.due(in: events, at: now, minutes: reminderMinutes)
        if !due.isEmpty {
            reminderEvents = due
            onReminder?()
        }
    }

    func clearReminder() { reminderEvents = [] }

    func setEnabled(_ value: Bool) {
        guard enabled != value else { return }
        enabled = value
        generation += 1
        if !value {
            ticker?.invalidate()
            ticker = nil
            observer = nil
            events = []
            calendars = []
            reminderEvents = []
            loading = false
            actionError = nil
            return
        }
        guard !demo else { access = .ready; return }
        observer = NotificationCenter.default.publisher(for: .EKEventStoreChanged).sink { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.enabled else { return }
                self.now = Date()
                self.checkReminders()
                if self.now.timeIntervalSince(self.lastFetch) >= 60 { self.refresh() }
            }
        }
        timer.tolerance = 3
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
        refresh()
        if access == .notRequested { requestAccess() }
    }

    func requestAccess() {
        guard enabled, !demo, access != .requesting else { return }
        access = .requesting
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.store.requestAccess()
                guard self.enabled else { self.access = .notRequested; return }
                self.access = .notRequested
                self.refresh()
            } catch {
                self.access = .failed
            }
        }
    }

    func refreshAfterWake() { refresh() }

    func refresh() {
        guard enabled, !demo, access != .requesting else { return }
        now = Date()
        generation += 1
        let token = generation
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess: access = .ready
        case .notDetermined: access = .notRequested
        case .restricted: access = .restricted
        default: access = .denied
        }
        guard access == .ready else { events = []; calendars = []; reminderEvents = []; loading = false; return }
        loading = true
        let date = now
        let selected = selectedCalendars
        Task { [weak self] in
            guard let self else { return }
            let sources = await self.store.calendars()
            let result = await self.store.events(at: date, selected: selected)
            guard self.enabled, token == self.generation else { return }
            guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { self.refresh(); return }
            self.calendars = sources
            self.events = result
            self.lastFetch = Date()
            self.loading = false
            self.checkReminders()
        }
    }

    func openMeeting(_ event: CalendarEvent) {
        guard enabled, let url = event.meetingURL else { return }
        actionError = NSWorkspace.shared.open(url) ? nil : String(localized: "The meeting link couldn’t be opened.")
    }

    func openEvent(_ event: CalendarEvent) {
        guard enabled, !demo else { return }
        guard let url = event.calendarURL else { actionError = String(localized: "The event couldn’t be found. Open Calendar and look for it there."); return }
        actionError = NSWorkspace.shared.open(url) ? nil : String(localized: "The event couldn’t be opened. Open Calendar and look for it there.")
    }

    func openCalendar() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") else {
            actionError = String(localized: "The Calendar app couldn’t be found."); return
        }
        actionError = NSWorkspace.shared.open(url) ? nil : String(localized: "Calendar couldn’t be opened.")
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }

    func preparePreview(empty: Bool = false, reminder: Bool = false) {
        guard demo else { return }
        access = .ready
        now = Date()
        events = empty ? [] : [
            CalendarEvent(id: "preview", title: String(localized: "Weekly team sync"), calendarTitle: String(localized: "Work"), start: now.addingTimeInterval(480),
                          end: now.addingTimeInterval(2280), meetingURL: URL(string: "https://meet.google.com/abc-defg-hij")),
            CalendarEvent(id: "preview-2", title: String(localized: "Design review"), calendarTitle: String(localized: "Work"),
                          start: now.addingTimeInterval(7200), end: now.addingTimeInterval(10800))
        ]
        reminderEvents = reminder ? Array(events.prefix(1)) : []
    }
}

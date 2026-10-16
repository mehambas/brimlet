import AppKit
import Combine
import BrimletCore

@MainActor final class Preferences: ObservableObject {
    private let defaults: UserDefaults
    @Published var musicEnabled: Bool { didSet { defaults.set(musicEnabled, forKey: "musicEnabled") } }
    @Published var timerEnabled: Bool { didSet { defaults.set(timerEnabled, forKey: "timerEnabled") } }
    @Published var calendarEnabled: Bool { didSet { defaults.set(calendarEnabled, forKey: "calendarEnabled") } }
    @Published var todosEnabled: Bool { didSet { defaults.set(todosEnabled, forKey: "todosEnabled") } }
    @Published var calendarSelection: [String]? { didSet { defaults.set(calendarSelection, forKey: "calendarSelection") } }
    @Published var calendarReminderMinutes: Int { didSet { defaults.set(calendarReminderMinutes, forKey: "calendarReminderMinutes") } }
    @Published var moduleOrder: [ModuleID] { didSet { defaults.set(moduleOrder.map(\.rawValue), forKey: "moduleOrder") } }
    @Published var pinMusic: Bool { didSet { defaults.set(pinMusic, forKey: "pinMusic") } }
    @Published var expandOnHover: Bool { didSet { defaults.set(expandOnHover, forKey: "expandOnHover") } }
    @Published var trackAlerts: Bool { didSet { defaults.set(trackAlerts, forKey: "trackAlerts") } }
    @Published var timerSound: Bool { didSet { defaults.set(timerSound, forKey: "timerSound") } }
    @Published var hideInFullscreen: Bool { didSet { defaults.set(hideInFullscreen, forKey: "hideInFullscreen") } }
    @Published var displayID: String { didSet { defaults.set(displayID, forKey: "displayID") } }
    @Published var spotifyRequested: Bool { didSet { defaults.set(spotifyRequested, forKey: "spotifyRequested") } }
    @Published var externalNotificationRequirements: [String: String] {
        didSet { defaults.set(externalNotificationRequirements, forKey: "externalNotificationRequirements") }
    }
    @Published var cmuxEnabled: Bool { didSet { defaults.set(cmuxEnabled, forKey: "cmuxEnabled") } }
    @Published var quotesEnabled: Bool { didSet { defaults.set(quotesEnabled, forKey: "quotesEnabled") } }
    @Published var quoteIntervalMinutes: Int {
        didSet {
            defaults.set(quoteIntervalMinutes, forKey: "quoteIntervalMinutes")
            defaults.set(Date().addingTimeInterval(TimeInterval(quoteIntervalMinutes * 60)), forKey: "quoteNextDisplayAt")
        }
    }
    @Published var quoteDisplaySeconds: Int { didSet { defaults.set(quoteDisplaySeconds, forKey: "quoteDisplaySeconds") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["musicEnabled": true, "timerEnabled": true, "expandOnHover": true,
                                    "calendarReminderMinutes": 5, "trackAlerts": true, "timerSound": true, "hideInFullscreen": true,
                                    "todosEnabled": true])
        musicEnabled = defaults.bool(forKey: "musicEnabled")
        timerEnabled = defaults.bool(forKey: "timerEnabled")
        calendarEnabled = defaults.bool(forKey: "calendarEnabled")
        todosEnabled = defaults.bool(forKey: "todosEnabled")
        calendarSelection = defaults.stringArray(forKey: "calendarSelection")
        calendarReminderMinutes = defaults.integer(forKey: "calendarReminderMinutes")
        moduleOrder = ActivityRouter.normalizedOrder(defaults.stringArray(forKey: "moduleOrder") ?? [])
        pinMusic = defaults.bool(forKey: "pinMusic")
        expandOnHover = defaults.bool(forKey: "expandOnHover")
        trackAlerts = defaults.bool(forKey: "trackAlerts")
        timerSound = defaults.bool(forKey: "timerSound")
        hideInFullscreen = defaults.bool(forKey: "hideInFullscreen")
        displayID = defaults.string(forKey: "displayID") ?? "auto"
        spotifyRequested = defaults.bool(forKey: "spotifyRequested")
        externalNotificationRequirements = defaults.dictionary(forKey: "externalNotificationRequirements") as? [String: String] ?? [:]
        cmuxEnabled = defaults.bool(forKey: "cmuxEnabled")
        quotesEnabled = defaults.bool(forKey: "quotesEnabled")
        let legacyHours = defaults.object(forKey: "quoteIntervalHours") as? Int ?? 24
        let interval = defaults.object(forKey: "quoteIntervalMinutes") as? Int ?? legacyHours * 60
        quoteIntervalMinutes = [15, 30, 60, 120, 360, 720, 1440, 2880].contains(interval) ? interval : 1440
        let displaySeconds = defaults.object(forKey: "quoteDisplaySeconds") as? Int ?? 30
        quoteDisplaySeconds = [0, 10, 15, 30, 60, 120].contains(displaySeconds) ? displaySeconds : 30
    }

    var enabled: Set<ModuleID> {
        Set(ModuleID.allCases.filter {
            switch $0 { case .music: return musicEnabled; case .timer: return timerEnabled; case .calendar: return calendarEnabled; case .todos: return todosEnabled }
        })
    }

    func move(_ id: ModuleID, by offset: Int) {
        guard let index = moduleOrder.firstIndex(of: id), moduleOrder.indices.contains(index + offset) else { return }
        moduleOrder.swapAt(index, index + offset)
    }

    func defaultsDate(forKey key: String) -> Date? { defaults.object(forKey: key) as? Date }
    func setDefaultsDate(_ date: Date, forKey key: String) { defaults.set(date, forKey: key) }
}

@MainActor protocol IslandModule: ObservableObject {
    var id: ModuleID { get }
    var activity: Activity { get }
    func setEnabled(_ enabled: Bool)
    func refreshAfterWake()
}

import AppKit
import Combine
import BrimletCore
import BrimletIPC

@MainActor final class AppModel: ObservableObject {
    let preferences: Preferences
    let music: MusicModule
    let timer = TimerModule()
    let calendar: CalendarModule
    let todos: TodoModule
    let quotes: QuoteStore
    let cmux = CmuxSessionWatcher()
    let updater: Updater
    @Published var settingsTab = SettingsTab.general
    @Published var geometry = IslandGeometry(notchWidth: 0, topInset: 0, screenWidth: 1512)
    @Published private(set) var isExpanded = false
    @Published private(set) var isPeeking = false
    @Published private(set) var externalNotification: ExternalNotification?
    @Published var externalReceiverError: String?
    @Published var isShowingCmuxQueue = false
    private var externalReceipts: [String: Date] = [:]
    @Published var hidden = false
    @Published var isPresented = true
    @Published var availableDisplays: [(id: String, name: String)] = []
    @Published private var router = ActivityRouter()
    var onPresentationChange: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onShowQuote: ((SavedQuote) -> Void)?
    private var subscriptions = Set<AnyCancellable>()
    private var hoverTask: Task<Void, Never>?
    private var alertTask: Task<Void, Never>?
    private var externalTask: Task<Void, Never>?
    private var quoteScheduleTask: Task<Void, Never>?
    private var pointerInside = false
    let demo: Bool

    init(demo: Bool = false) {
        self.demo = demo
        let defaults = demo ? MemoryDefaults() : .standard
        preferences = Preferences(defaults: defaults)
        updater = Updater(active: !demo)
        music = MusicModule(demo: demo)
        calendar = CalendarModule(demo: demo)
        todos = TodoModule(defaults: defaults)
        quotes = QuoteStore(defaults: defaults)
        calendar.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        music.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        music.onPresentationChange = { [weak self] in self?.onPresentationChange?() }
        timer.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        todos.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        quotes.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
            DispatchQueue.main.async { self?.scheduleQuote() }
        }.store(in: &subscriptions)
        preferences.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.applyPreferences()
                self?.objectWillChange.send()
            }
        }.store(in: &subscriptions)
        cmux.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        cmux.onNewSession = { [weak self] session in self?.showCmuxAlert(for: session) }
        music.onTrackChange = { [weak self] in
            guard let self, self.preferences.trackAlerts else { return }
            self.showAlert(.music, duration: 3)
        }
        timer.onFinish = { [weak self] in
            guard let self else { return }
            self.showAlert(.timer, duration: 6)
            if self.preferences.timerSound && !self.demo { NSSound(named: "Glass")?.play() }
        }
        calendar.onReminder = { [weak self] in
            guard let self, !self.isExpanded, self.isPresented, !self.hidden else { return }
            self.showAlert(.calendar, duration: 10)
        }
        applyPreferences()
    }

    var modules: [ModuleID] { preferences.moduleOrder.filter { preferences.enabled.contains($0) } }
    var currentModule: ModuleID? {
        router.visible(activities: [music.activity, timer.activity, calendar.activity, todos.activity], at: Date(), expanded: isExpanded)
    }
    var activity: Activity? {
        switch currentModule {
        case .music: return music.activity
        case .timer: return timer.activity
        case .calendar: return calendar.activity
        case .todos: return todos.activity
        case nil: return nil
        }
    }
    var width: Double { isExpanded || isPeeking ? geometry.expandedWidth : geometry.compactWidth }
    var height: Double {
        guard isExpanded else { return geometry.headerHeight + (isPeeking ? 66 : 0) }
        guard currentModule == .music else { return geometry.expandedHeight }
        return geometry.expandedHeight + (music.lyricsVisible ? LyricsPresentation.extraHeight : 0)
    }

    func applyPreferences() {
        router.enabled = preferences.enabled
        router.order = preferences.moduleOrder
        router.pinned = preferences.pinMusic ? .music : nil
        music.configure(enabled: preferences.musicEnabled, requested: preferences.spotifyRequested)
        timer.setEnabled(preferences.timerEnabled)
        calendar.configure(selected: preferences.calendarSelection, reminderMinutes: preferences.calendarReminderMinutes)
        calendar.setEnabled(preferences.calendarEnabled)
        todos.setEnabled(preferences.todosEnabled)
        if preferences.cmuxEnabled { cmux.start() } else { cmux.stop() }
        scheduleQuote()
        onPresentationChange?()
    }

    private func scheduleQuote() {
        quoteScheduleTask?.cancel()
        guard preferences.quotesEnabled, !quotes.quotes.isEmpty else { return }
        let key = "quoteNextDisplayAt"
        let now = Date()
        let next = preferences.defaultsDate(forKey: key) ?? now.addingTimeInterval(TimeInterval(preferences.quoteIntervalMinutes * 60))
        preferences.setDefaultsDate(next, forKey: key)
        quoteScheduleTask = Task { [weak self] in
            let wait = max(1, next.timeIntervalSinceNow)
            do { try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000)) } catch { return }
            guard let self, self.preferences.quotesEnabled, let quote = self.quotes.nextQuote() else { return }
            self.onShowQuote?(quote)
            self.preferences.setDefaultsDate(Date().addingTimeInterval(TimeInterval(self.preferences.quoteIntervalMinutes * 60)), forKey: key)
            self.scheduleQuote()
        }
    }

    func connectSpotify() {
        preferences.spotifyRequested = true
        if !music.spotifyRunning { music.openSpotify() }
        else { music.retry() }
    }

    func select(_ module: ModuleID) {
        guard modules.contains(module) else { return }
        if !isExpanded { expand() }
        router.selected = module
    }

    func expand() {
        hoverTask?.cancel()
        dismissExternalNotification()
        let selected = currentModule
        isExpanded = true
        isPeeking = false
        router.selected = selected
        onPresentationChange?()
    }

    func showCmuxQueue() {
        dismissExternalNotification()
        isShowingCmuxQueue = true
        if !isExpanded { expand() }
        onPresentationChange?()
    }

    func showCmuxAlert(for session: WaitingCmuxSession) {
        guard !isExpanded, isPresented, !hidden, externalNotification == nil else { return }
        alertTask?.cancel()
        router.transient = nil
        router.transientUntil = nil
        isPeeking = true
        onPresentationChange?()
        alertTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 8_000_000_000) } catch { return }
            guard let self, !self.pointerInside else { return }
            self.isPeeking = false
            self.onPresentationChange?()
        }
    }

    func collapse() {
        guard !todos.isEditorPresented else { return }
        hoverTask?.cancel()
        dismissExternalNotification()
        alertTask?.cancel()
        calendar.clearReminder()
        router.transient = nil
        router.transientUntil = nil
        isExpanded = false
        isPeeking = false
        isShowingCmuxQueue = false
        router.selected = nil
        onPresentationChange?()
    }

    func hover(_ inside: Bool) {
        guard !todos.isEditorPresented else { return }
        hoverTask?.cancel()
        pointerInside = inside
        guard !demo else { return }
        // External alerts have a bounded lifetime; hover does not postpone them.
        if externalNotification != nil { return }
        if inside {
            if isPeeking {
                // Keep the small player available while its controls are being used.
                router.transientUntil = .distantFuture
                return
            }
            guard preferences.expandOnHover && !isExpanded else { return }
            hoverTask = Task { [weak self] in
                do { try await Task.sleep(nanoseconds: 180_000_000) } catch { return }
                self?.expand()
            }
        } else if isPeeking, let module = router.transient {
            showAlert(module, duration: 1)
        } else if isExpanded {
            hoverTask = Task { [weak self] in
                do { try await Task.sleep(nanoseconds: 600_000_000) } catch { return }
                self?.collapse()
            }
        }
    }

    func showAlert(_ module: ModuleID, duration: TimeInterval) {
        if externalNotification != nil {
            if module == .music { return }
            dismissExternalNotification()
        }
        router.showTemporarily(module, at: Date(), duration: duration)
        if !isExpanded { isPeeking = true }
        if pointerInside && isPeeking { router.transientUntil = .distantFuture }
        onPresentationChange?()
        alertTask?.cancel()
        alertTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000)) } catch { return }
            guard let self else { return }
            while self.pointerInside && self.isPeeking {
                do { try await Task.sleep(nanoseconds: 300_000_000) } catch { return }
            }
            self.calendar.clearReminder()
            self.router.transient = nil
            self.router.transientUntil = nil
            self.isPeeking = false
            self.onPresentationChange?()
        }
    }

    @discardableResult
    func showExternalNotification(_ notification: ExternalNotification) -> DeliveryStatus {
        guard notification.isValid else { return .invalid }
        let now = Date()
        externalReceipts = externalReceipts.filter { $0.value > now }
        let key = notification.sourceBundleID + ":" + notification.id.uuidString
        if externalReceipts[key] != nil { return .duplicate }
        guard isPresented, !hidden else { return .unavailable }
        guard !isExpanded, externalNotification == nil else { return .busy }
        if isPeeking && !(router.transient == .music && notification.priority == .high) { return .busy }
        if notification.priority == .low && [music.activity, timer.activity, calendar.activity, todos.activity].contains(where: \.isActive) { return .busy }
        guard externalReceipts.count < 256 else { return .busy }
        externalReceipts[key] = now.addingTimeInterval(300)
        alertTask?.cancel()
        router.transient = nil
        router.transientUntil = nil
        externalNotification = notification
        isPeeking = true
        onPresentationChange?()
        externalTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: UInt64(notification.duration * 1_000_000_000)) } catch { return }
            self?.dismissExternalNotification()
        }
        return .displayed
    }

    func dismissExternalNotification() {
        guard externalNotification != nil else { return }
        externalTask?.cancel()
        externalTask = nil
        externalNotification = nil
        isPeeking = false
        onPresentationChange?()
    }

    func authorizeExternalApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = String(localized: "Choose the app whose notifications Brimlet may show.")
        guard panel.runModal() == .OK, let url = panel.url,
              let id = Bundle(url: url)?.bundleIdentifier else { return }
        do {
            preferences.externalNotificationRequirements[id] = try ApplicationIdentity.requirement(at: url)
            externalReceiverError = nil
        } catch {
            externalReceiverError = String(localized: "The app’s signature couldn’t be verified. Choose a signed app.")
        }
    }

    func refreshAfterWake() {
        music.refreshAfterWake()
        timer.refreshAfterWake()
        calendar.refreshAfterWake()
        todos.refreshAfterWake()
        onPresentationChange?()
    }

    func preparePreview(timer showTimer: Bool = false, compact: Bool = false, empty: Bool = false) {
        geometry = IslandGeometry(notchWidth: 184, topInset: 38, screenWidth: 1512)
        if !empty {
            music.connection = .connected
            music.track = SpotifyTrack(id: "demo", title: "Slow Tide", artist: "Harbor Lights", artworkURL: "",
                                       duration: 316, position: 92, isPlaying: true, observedAt: Date())
        }
        if showTimer {
            timer.start(seconds: 25 * 60)
            router.selected = .timer
        }
        isExpanded = !compact
        if showTimer { router.selected = .timer }
    }
}

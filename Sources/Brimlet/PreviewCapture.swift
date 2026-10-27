import AppKit
import SwiftUI
import BrimletCore

/// Settings for previews, the demo, the smoke test and tests. They live in memory only: a removed defaults
/// domain still leaves an empty plist behind.
final class MemoryDefaults: UserDefaults {
    private var values: [String: Any] = [:]

    /// The suite is never written; it only gives registered defaults somewhere to live.
    convenience init() { self.init(suiteName: "com.hamzabasaran.brimlet.memory")! }

    override func object(forKey key: String) -> Any? { values[key] ?? super.object(forKey: key) }
    override func set(_ value: Any?, forKey key: String) { values[key] = value }
    override func removeObject(forKey key: String) { values[key] = nil }
}

@MainActor enum PreviewCapture {
    static let background = Color(red: 0.13, green: 0.17, blue: 0.18)

    static func directory(default name: String) -> String {
        CommandLine.arguments.last.flatMap { $0.hasPrefix("/") ? $0 : nil } ?? NSTemporaryDirectory() + name
    }

    static func runQuotes() {
        let directory = directory(default: "brimlet-quote-previews")
        let preferences = Preferences(defaults: MemoryDefaults())
        let quote = SampleData.quote
        let samples: [(String, SavedQuote?)] = [
            ("quote", quote),
            ("quote-short", SavedQuote(text: String(localized: "A sentence you want to remember."), source: String(localized: "Notes"))),
            ("quote-long", SavedQuote(text: Array(repeating: quote.text, count: 8).joined(separator: "\n\n"), source: quote.source, author: quote.author)),
            ("quote-capture", nil)
        ]
        do {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            for (name, sample) in samples {
                let height = sample.map { QuotePanelController.readingHeight(for: $0, width: 400, maximum: 480) } ?? 0
                let view = QuotePanelView(draftText: quote.text, quote: sample, width: 400, contentHeight: height,
                    preferences: preferences, onSave: { _, _, _ in }, onClose: {}, onHover: { _ in })
                for scheme in [ColorScheme.light, .dark] {
                    try save(view.padding(32).background(Color(nsColor: .windowBackgroundColor)), to: "\(directory)/\(scheme)-\(name).png", scheme: scheme)
                }
            }
            print("Quote previews: \(directory)")
        } catch { fputs("Quote preview error: \(error)\n", stderr) }
    }

    static func run() {
        let directory = directory(default: "brimlet-previews")
        do {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            for (name, timer, compact, empty) in [("music", false, false, false), ("timer", true, false, false),
                                                  ("compact", false, true, false), ("welcome", false, false, true)] {
                let model = AppModel(demo: true)
                model.preparePreview(timer: timer, compact: compact, empty: empty)
                try save(IslandView(model: model).padding(40).background(background), to: "\(directory)/\(name).png")
                model.timer.reset()
            }
            for empty in [false, true] {
                let calendarModel = AppModel(demo: true)
                calendarModel.preparePreview()
                calendarModel.preferences.calendarEnabled = true
                calendarModel.applyPreferences()
                calendarModel.calendar.preparePreview(empty: empty)
                calendarModel.select(.calendar)
                try save(IslandView(model: calendarModel).padding(40).background(background),
                         to: "\(directory)/calendar\(empty ? "-empty" : "").png")
            }
            let updateModel = AppModel(demo: true)
            updateModel.preparePreview()
            updateModel.updater.release = Release(tag: "v99.0.0",
                page: URL(string: "https://github.com/mehambas/brimlet/releases")!, assets: [:])
            try save(IslandView(model: updateModel).padding(40).background(background),
                     to: "\(directory)/update-available.png")
            updateModel.updater.release = nil
            try save(IslandView(model: updateModel).padding(40).background(background),
                     to: "\(directory)/update-cleared.png")
            let lyricsModel = AppModel(demo: true)
            lyricsModel.preparePreview()
            lyricsModel.music.showLyricsPreview(SampleData.lyrics)
            try save(IslandView(model: lyricsModel).padding(40).background(background), to: "\(directory)/lyrics.png")
            let model = AppModel(demo: true)
            model.preparePreview()
            for scheme in [ColorScheme.light, .dark] {
                for tab in SettingsTab.allCases {
                    model.settingsTab = tab
                    try captureSettings(model: model, scheme: scheme, to: "\(directory)/\(scheme)-settings-\(tab).png")
                }
                try save(TodoEditor(module: model.todos), to: "\(directory)/\(scheme)-task-editor.png", scheme: scheme)
            }
            let quoteLibrary = AppModel(demo: true)
            let sampleQuote = SampleData.quote
            for index in 1...103 {
                quoteLibrary.quotes.add(text: sampleQuote.text, source: "\(sampleQuote.source) · \(index)", author: sampleQuote.author)
            }
            quoteLibrary.settingsTab = .quotes
            for scheme in [ColorScheme.light, .dark] {
                try captureSettings(model: quoteLibrary, scheme: scheme, to: "\(directory)/\(scheme)-settings-quotes-library.png")
            }
            model.select(.todos)
            model.todos.add(title: "Read the design notes", note: "Brimlet", category: .work, dueDate: Date(), reminder: false)
            try save(IslandView(model: model).padding(40).background(background), to: "\(directory)/tasks.png")
            let enabledCalendar = AppModel(demo: true)
            enabledCalendar.preferences.calendarEnabled = true
            enabledCalendar.applyPreferences()
            enabledCalendar.calendar.preparePreview()
            enabledCalendar.settingsTab = .calendar
            for scheme in [ColorScheme.light, .dark] {
                try captureSettings(model: enabledCalendar, scheme: scheme, to: "\(directory)/\(scheme)-settings-calendar-enabled.png")
            }
            let timerModel = AppModel(demo: true)
            timerModel.preparePreview(timer: true)
            timerModel.timer.togglePause()
            try save(IslandView(model: timerModel).padding(40).background(background), to: "\(directory)/timer-paused.png")
            timerModel.timer.reset()
            try save(IslandView(model: timerModel).padding(40).background(background), to: "\(directory)/timer-idle.png")
            let externalModel = AppModel(demo: true)
            externalModel.preparePreview(compact: true)
            externalModel.showExternalNotification(SampleData.notification)
            try save(IslandView(model: externalModel).padding(40).background(background), to: "\(directory)/external-notification.png")
            for paused in [false, true] {
                let peekModel = AppModel(demo: true)
                peekModel.preparePreview(compact: true)
                if paused { peekModel.music.track?.isPlaying = false }
                peekModel.showAlert(.music, duration: 30)
                try save(IslandView(model: peekModel).padding(40).background(background),
                         to: "\(directory)/peek-\(paused ? "paused" : "playing").png")
            }
            try captureLyricsMotion(to: directory)
            try captureLyricsLines(to: directory)
            print("Previews: \(directory)")
        } catch { fputs("Preview error: \(error)\n", stderr) }
    }

    /// Capture intermediate hosting sizes, where centered content used to shift during resizing.
    static func captureLyricsMotion(to directory: String) throws {
        let model = AppModel(demo: true)
        model.preparePreview()
        model.music.showLyricsPreview(SampleData.lyrics)
        model.music.toggleLyrics()
        let controller = IslandPanelController(model: model, observeSystem: false)
        controller.updatePresentation(animated: false)
        defer { controller.panel.orderOut(nil) }
        let top = controller.panel.frame.maxY
        let width = controller.panel.frame.width
        for direction in ["opening", "closing"] {
            model.music.toggleLyrics()
            for step in 0...8 {
                RunLoop.current.run(until: Date().addingTimeInterval(0.06))
                guard abs(controller.panel.frame.maxY - top) < 1,
                      abs(controller.panel.frame.width - width) < 1,
                      let view = controller.panel.contentView,
                      let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
                    throw NSError(domain: "BrimletPreview.LyricsMotion", code: 7)
                }
                view.cacheDisplay(in: view.bounds, to: bitmap)
                if let data = bitmap.representation(using: .png, properties: [:]) {
                    try data.write(to: URL(fileURLWithPath: "\(directory)/lyrics-\(direction)-\(step).png"))
                }
            }
        }
    }

    static func captureLyricsLines(to directory: String) throws {
        let model = AppModel(demo: true)
        model.preparePreview()
        let lines = SampleData.lyrics.lines + [
            LyricsLine(id: 5, timestamp: 114, text: "The lights along the distant shore keep shining through the evening, and every winding road will lead us slowly back to where we started.")
        ]
        model.music.showLyricsPreview(SpotifyLyrics(trackID: "demo", lines: lines, isSynced: true))
        model.music.track?.isPlaying = false
        model.music.track?.position = 89
        let controller = IslandPanelController(model: model, observeSystem: false)
        controller.updatePresentation(animated: false)
        defer { controller.panel.orderOut(nil) }
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        model.music.track?.position = 97
        for step in 0...8 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.07))
            guard let view = controller.panel.contentView,
                  let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { continue }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            if let data = bitmap.representation(using: .png, properties: [:]) {
                try data.write(to: URL(fileURLWithPath: "\(directory)/lyrics-line-transition-\(step).png"))
            }
        }
        model.music.track?.position = 115
        RunLoop.current.run(until: Date().addingTimeInterval(0.7))
        if let view = controller.panel.contentView,
           let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
            view.cacheDisplay(in: view.bounds, to: bitmap)
            if let data = bitmap.representation(using: .png, properties: [:]) {
                try data.write(to: URL(fileURLWithPath: "\(directory)/lyrics-long-sentence.png"))
            }
        }
    }

    static func captureSettings(model: AppModel, scheme: ColorScheme, to path: String) throws {
        let requestedTab = model.settingsTab
        let controller = SettingsController(model: model)
        let window = NSWindow(contentRect: NSRect(x: -10000, y: -10000, width: 520, height: 620),
                              styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        window.contentViewController = controller
        controller.select(requestedTab)
        window.setFrameOrigin(NSPoint(x: -10000, y: -10000))
        window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil) }
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        guard let view = window.contentView?.superview else { throw NSError(domain: "BrimletPreview", code: 3) }
        view.layoutSubtreeIfNeeded()
        guard model.settingsTab == requestedTab, controller.selectedTabViewItemIndex == SettingsTab.allCases.firstIndex(of: requestedTab), abs(window.contentLayoutRect.width - 520) < 1 else {
            throw NSError(domain: "BrimletPreview.SettingsLayout", code: 6)
        }
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { throw NSError(domain: "BrimletPreview", code: 4) }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { throw NSError(domain: "BrimletPreview", code: 5) }
        try data.write(to: URL(fileURLWithPath: path))
    }

    static func save<V: View>(_ view: V, to path: String, scheme: ColorScheme = .dark) throws {
        let image = try render(view, scheme: scheme)
        guard let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            throw NSError(domain: "BrimletPreview", code: 2)
        }
        try data.write(to: URL(fileURLWithPath: path))
    }

    /// An offscreen window rather than ImageRenderer, which leaves AppKit-backed controls such as segmented pickers blank.
    static func render<V: View>(_ view: V, scheme: ColorScheme = .dark) throws -> CGImage {
        let hosting = NSHostingView(rootView: view.environment(\.colorScheme, scheme))
        hosting.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        let size = hosting.fittingSize
        hosting.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: NSRect(x: -10000, y: -10000, width: size.width, height: size.height),
                              styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = hosting
        window.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        window.isReleasedWhenClosed = false
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        hosting.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        guard let bitmap = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            throw NSError(domain: "BrimletPreview", code: 1)
        }
        hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
        guard let image = bitmap.cgImage else { throw NSError(domain: "BrimletPreview", code: 2) }
        return image
    }
}

/// Made-up content for previews and the README animation; nothing is read from the Mac.
@MainActor enum SampleData {
    static var quote: SavedQuote {
        SavedQuote(text: "I went to the woods because I wished to live deliberately, to front only the essential facts of life, and see if I could not learn what it had to teach, and not, when I came to die, discover that I had not lived.",
                   source: "Walden", author: "Henry David Thoreau")
    }

    static var notification: ExternalNotification {
        ExternalNotification(sourceBundleID: "com.example.reminders", title: String(localized: "Time to stretch"),
                             body: String(localized: "You’ve been at your desk for an hour."), symbol: "figure.walk", priority: .high, duration: 30)
    }

    static var lyrics: SpotifyLyrics {
        let lines = ["Low light on the water", "the harbor hums a slow refrain", "we let the evening find us",
                     "and drift back home again", "the gulls have gone to sleep now"]
        return SpotifyLyrics(trackID: "demo", lines: lines.enumerated().map {
            LyricsLine(id: $0.offset, timestamp: 84 + Double($0.offset) * 6, text: $0.element)
        }, isSynced: true)
    }
}

@MainActor enum SmokeTest {
    static func run() {
        let model = AppModel(demo: true)
        let controller = IslandPanelController(model: model, observeSystem: false)
        let compact = controller.panel.frame
        model.expand()
        controller.updatePresentation(animated: false)
        let expanded = controller.panel.frame
        model.select(.timer)
        let selectionWorks = model.currentModule == .timer
        model.timer.start(seconds: 60)
        model.timer.togglePause()
        let pauseWorks = model.timer.countdown.phase == .paused
        model.preferences.timerEnabled = false
        model.applyPreferences()
        let disablingWorks = model.timer.countdown.phase == .idle && model.currentModule == .music
        let calendarDefaultsOff = !model.preferences.calendarEnabled && model.calendar.events.isEmpty
        model.preferences.calendarEnabled = true
        model.applyPreferences()
        model.calendar.preparePreview()
        model.select(.calendar)
        let calendarWorks = model.currentModule == .calendar && model.calendar.next?.id == "preview"
        model.preferences.calendarEnabled = false
        model.applyPreferences()
        let calendarDisables = model.calendar.events.isEmpty && model.currentModule == .music
        model.collapse()
        controller.updatePresentation(animated: false)
        let restored = controller.panel.frame
        model.preferences.pinMusic = true
        model.applyPreferences()
        let external = ExternalNotification(sourceBundleID: "test.sender", title: "Test", body: "", priority: .high)
        model.hidden = true
        let hiddenRejects = model.showExternalNotification(external) == .unavailable
        model.hidden = false
        controller.updatePresentation(animated: false)
        model.expand()
        let expandedRejects = model.showExternalNotification(external) == .busy
        model.collapse()
        model.showAlert(.timer, duration: 30)
        let timerWins = model.showExternalNotification(external) == .busy
        model.collapse()
        let externalShows = model.showExternalNotification(external) == .displayed && model.isPeeking
        let duplicateHandled = model.showExternalNotification(external) == .duplicate
        let busyHandled = model.showExternalNotification(ExternalNotification(sourceBundleID: "test.sender", title: "Other", body: "")) == .busy
        model.showAlert(.music, duration: 1)
        let musicDoesNotReplace = model.externalNotification?.id == external.id
        model.dismissExternalNotification()
        let pinRestored = model.currentModule == .music && !model.isPeeking
        model.showExternalNotification(ExternalNotification(sourceBundleID: "test.sender", title: "Short", body: "", duration: 1))
        RunLoop.current.run(until: Date().addingTimeInterval(1.2))
        let expires = model.externalNotification == nil && !model.isPeeking
        let externalPass = hiddenRejects && expandedRejects && timerWins && externalShows && duplicateHandled && busyHandled && musicDoesNotReplace && pinRestored && expires
        let settings = SettingsController(model: model)
        let window = NSWindow(contentRect: NSRect(x: -10000, y: -10000, width: 520, height: 620),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentViewController = settings
        var settingsPass = true
        for tab in SettingsTab.allCases {
            settings.select(tab)
            settingsPass = settingsPass && model.settingsTab == tab
                && settings.selectedTabViewItemIndex == SettingsTab.allCases.firstIndex(of: tab)
                && abs(window.contentLayoutRect.width - 520) < 1
        }
        settings.select(.general)
        settingsPass = settingsPass && model.settingsTab == .general
        window.orderOut(nil)
        let result: [String: Any] = [
            "compactWidth": compact.width, "expandedWidth": expanded.width,
            "topEdgePreserved": abs(compact.maxY - expanded.maxY) < 1,
            "collapseRestoresFrame": compact == restored,
            "moduleNavigation": selectionWorks, "timerPause": pauseWorks,
            "disableResetsTimer": disablingWorks,
            "calendarDefaultsOff": calendarDefaultsOff,
            "calendarNavigation": calendarWorks, "calendarDisableClearsEvents": calendarDisables,
            "screenCount": NSScreen.screens.count,
            "externalNotifications": externalPass,
            "settingsNavigationAndSize": settingsPass,
            "pass": expanded.width > compact.width && compact == restored && selectionWorks && pauseWorks && disablingWorks && calendarDefaultsOff && calendarWorks && calendarDisables && externalPass && settingsPass
        ]
        if let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL(fileURLWithPath: NSTemporaryDirectory() + "brimlet-smoke-test.json"))
            print(String(decoding: data, as: UTF8.self))
        }
        controller.panel.orderOut(nil)
    }
}

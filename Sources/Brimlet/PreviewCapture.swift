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
                try save(view.padding(32).background(Color(red: 0.94, green: 0.95, blue: 0.94)), to: "\(directory)/\(name).png")
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
            let lyricsModel = AppModel(demo: true)
            lyricsModel.preparePreview()
            lyricsModel.music.showLyricsPreview(SampleData.lyrics)
            try save(IslandView(model: lyricsModel).padding(40).background(background), to: "\(directory)/lyrics.png")
            let model = AppModel(demo: true)
            model.preparePreview()
            for tab in [SettingsTab.modules, .appearance, .general, .quotes] {
                model.settingsTab = tab
                try save(SettingsView(model: model, preferences: model.preferences, updater: model.updater),
                         to: "\(directory)/settings-\(tab).png")
            }
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
            print("Previews: \(directory)")
        } catch { fputs("Preview error: \(error)\n", stderr) }
    }

    static func save<V: View>(_ view: V, to path: String) throws {
        let image = try render(view)
        guard let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            throw NSError(domain: "BrimletPreview", code: 2)
        }
        try data.write(to: URL(fileURLWithPath: path))
    }

    /// An offscreen window rather than ImageRenderer, which leaves AppKit-backed controls such as segmented pickers blank.
    static func render<V: View>(_ view: V) throws -> CGImage {
        let hosting = NSHostingView(rootView: view.environment(\.colorScheme, .dark))
        hosting.appearance = NSAppearance(named: .darkAqua)
        let size = hosting.fittingSize
        hosting.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: NSRect(x: -10000, y: -10000, width: size.width, height: size.height),
                              styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = hosting
        window.appearance = NSAppearance(named: .darkAqua)
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
            "pass": expanded.width > compact.width && compact == restored && selectionWorks && pauseWorks && disablingWorks && calendarDefaultsOff && calendarWorks && calendarDisables && externalPass
        ]
        if let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL(fileURLWithPath: NSTemporaryDirectory() + "brimlet-smoke-test.json"))
            print(String(decoding: data, as: UTF8.self))
        }
        controller.panel.orderOut(nil)
    }
}

import AppKit
import SwiftUI

/// Frames for the README animations: the app's own views on a made-up desktop, plus an ffmpeg concat list.
@MainActor enum DemoCapture {
    static func run() {
        guard let index = CommandLine.arguments.firstIndex(of: "--capture-demo"), CommandLine.arguments.count > index + 1 else {
            print("Usage: Brimlet --capture-demo <output-directory>")
            return
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[index + 1])
        do {
            for dark in [true, false] {
                let recorder = try DemoRecorder(folder: output.appendingPathComponent(dark ? "dark" : "light"))
                try record(dark: dark, into: recorder)
                try recorder.finish()
            }
            print("Demo frames: \(output.path)")
        } catch { fputs("Demo error: \(error.localizedDescription)\n", stderr) }
    }

    private static func record(dark: Bool, into recorder: DemoRecorder) throws {
        let model = AppModel(demo: true)
        model.preparePreview(compact: true)
        model.preferences.calendarEnabled = true
        model.applyPreferences()
        model.calendar.preparePreview()
        func frame(_ seconds: Double) throws {
            try recorder.add(PreviewCapture.render(DemoScene(model: model, dark: dark)), seconds: seconds)
        }
        // The equalizer follows the clock, so frames taken in a row move it.
        for _ in 0..<6 { try frame(0.2) }
        model.showAlert(.music, duration: 60)
        try frame(2.0)
        model.expand()
        try frame(2.0)
        model.music.showLyricsPreview(SampleData.lyrics)
        model.onPresentationChange?()
        try frame(2.4)
        model.music.toggleLyrics()
        model.select(.timer)
        model.timer.start(seconds: 25 * 60)
        for _ in 0..<3 {
            try frame(0.9)
            RunLoop.current.run(until: Date().addingTimeInterval(0.85))
        }
        model.timer.reset()
        model.select(.calendar)
        try frame(2.4)
        model.collapse()
        model.calendar.preparePreview(reminder: true)
        model.showAlert(.calendar, duration: 60)
        try frame(2.2)
        model.collapse()
        model.showExternalNotification(SampleData.notification)
        try frame(2.0)
        model.dismissExternalNotification()
        for _ in 0..<6 { try frame(0.2) }
    }
}

private struct DemoScene: View {
    @ObservedObject var model: AppModel
    let dark: Bool

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: dark ? [Color(red: 0.05, green: 0.15, blue: 0.13), Color(red: 0.12, green: 0.13, blue: 0.24)]
                                        : [Color(red: 0.86, green: 0.95, blue: 0.91), Color(red: 0.84, green: 0.88, blue: 0.97)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            MenuBarStrip(dark: dark, height: model.geometry.headerHeight, notchWidth: model.geometry.notchWidth)
            IslandView(model: model)
        }
        .frame(width: 900, height: 480)
    }
}

private struct MenuBarStrip: View {
    /// The real time, since the calendar's sample events are placed relative to it.
    private static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "EEE d MMM  HH:mm"
        return formatter
    }()
    let dark: Bool
    let height: Double
    let notchWidth: Double

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: "apple.logo").font(.system(size: 14))
            Text(verbatim: "Finder").fontWeight(.bold)
            Text(verbatim: "File")
            Text(verbatim: "Edit")
            Spacer()
            if let icon = NSImage(named: "MenuBarIconTemplate") {
                Image(nsImage: icon).renderingMode(.template)
            }
            Image(systemName: "wifi")
            Image(systemName: "battery.75percent")
            Image(systemName: "switch.2")
            Text(verbatim: Self.clock.string(from: Date()))
        }
        .font(.system(size: 13))
        .foregroundStyle((dark ? Color.white : Color.black).opacity(0.88))
        .padding(.horizontal, 16)
        .frame(height: height)
        .background(dark ? Color.black.opacity(0.22) : Color.white.opacity(0.4))
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(bottomLeadingRadius: 10, bottomTrailingRadius: 10).fill(Color.black)
                .frame(width: notchWidth, height: height)
        }
    }
}

private final class DemoRecorder {
    private let folder: URL
    private var frames: [(name: String, seconds: Double)] = []

    init(folder: URL) throws {
        self.folder = folder
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    func add(_ image: CGImage, seconds: Double) throws {
        let name = String(format: "frame-%03d.png", frames.count)
        guard let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: folder.appendingPathComponent(name))
        frames.append((name, seconds))
    }

    func finish() throws {
        guard let last = frames.last else { throw CocoaError(.fileWriteUnknown) }
        // The concat demuxer drops the last duration unless the last file is listed once more.
        let list = frames.map { "file '\($0.name)'\nduration \($0.seconds)\n" }.joined() + "file '\(last.name)'\n"
        try list.write(to: folder.appendingPathComponent("frames.txt"), atomically: true, encoding: .utf8)
    }
}

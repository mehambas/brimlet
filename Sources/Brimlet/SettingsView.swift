import AppKit
import SwiftUI
import ServiceManagement
import BrimletCore

enum SettingsTab: String, CaseIterable {
    case general, modules, calendar, notifications, quotes

    var title: String {
        switch self {
        case .general: return String(localized: "General")
        case .modules: return String(localized: "Modules")
        case .calendar: return String(localized: "Calendar")
        case .notifications: return String(localized: "Notifications")
        case .quotes: return String(localized: "Quotes")
        }
    }
    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .modules: return "square.stack.3d.up"
        case .calendar: return "calendar"
        case .notifications: return "bell.badge"
        case .quotes: return "quote.opening"
        }
    }
    @MainActor func height(model: AppModel) -> CGFloat {
        switch self {
        case .general, .modules: return 620
        case .calendar: return model.preferences.calendarEnabled ? min(620, 330 + CGFloat(model.calendar.calendars.count) * 42) : 290
        case .notifications: return min(620, 290 + CGFloat(model.preferences.externalNotificationRequirements.count) * 48)
        case .quotes: return min(620, 360 + CGFloat(model.quotes.quotes.count) * 80)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: Preferences
    @ObservedObject var updater: Updater
    var tab: SettingsTab? = nil
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            switch tab ?? model.settingsTab {
            case .general: general
            case .modules: modules
            case .calendar: calendarSettings
            case .notifications: notificationSettings
            case .quotes: quoteSettings
            }
        }
        .formStyle(.grouped)
        .font(.system(size: 13))
        .controlSize(.small)
        .tint(BrimletTheme.jade)
        .frame(width: 520)
        .frame(maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var modules: some View {
        Group {
            Section {
                ForEach(preferences.moduleOrder) { module in
                    HStack(spacing: 10) {
                        Image(systemName: module.symbol).font(.system(size: 15))
                            .frame(width: 26, height: 26)
                            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 7))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(module.title)
                            Text(moduleDescription(module)).font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 4)
                        VStack(spacing: 0) {
                            Button { preferences.move(module, by: -1) } label: { Image(systemName: "chevron.up").font(.system(size: 11)) }
                                .disabled(preferences.moduleOrder.first == module).help("Move Up").accessibilityLabel("Move Up")
                            Button { preferences.move(module, by: 1) } label: { Image(systemName: "chevron.down").font(.system(size: 11)) }
                                .disabled(preferences.moduleOrder.last == module).help("Move Down").accessibilityLabel("Move Down")
                        }.buttonStyle(.borderless)
                        Toggle(module.title, isOn: moduleBinding(module)).labelsHidden().toggleStyle(.switch)
                    }
                    .draggable(module.rawValue)
                    .dropDestination(for: String.self) { values, _ in
                        guard let value = values.first, let source = ModuleID(rawValue: value),
                              let from = preferences.moduleOrder.firstIndex(of: source),
                              let to = preferences.moduleOrder.firstIndex(of: module) else { return false }
                        var order = preferences.moduleOrder
                        order.remove(at: from)
                        order.insert(source, at: to)
                        preferences.moduleOrder = order
                        return true
                    }
                }
            } header: { Text("Modules") } footer: {
                footnote("When several modules have something going on, the higher one wins. In the open panel, the tabs switch between them.")
            }
            Section("Small View") {
                settingToggle("Keep music in front", detail: "The small view always shows the music module.", value: $preferences.pinMusic)
                settingToggle("Show track changes", detail: "Briefly shows the new track.", value: $preferences.trackAlerts)
            }
            Section("Music") {
                HStack {
                    Label(preferences.spotifyRequested ? "Connected to Spotify" : "Not connected", systemImage: preferences.spotifyRequested ? "checkmark.circle" : "music.note")
                    Spacer()
                    if preferences.spotifyRequested {
                        Button("Disconnect") { preferences.spotifyRequested = false }
                    } else {
                        Button("Connect to Spotify") { model.connectSpotify() }.buttonStyle(.borderedProminent).disabled(!preferences.musicEnabled)
                    }
                }
                if !preferences.musicEnabled { footnote("Turn on Music to connect Spotify.") }
            }
            Section {
                settingToggle("Play a sound when time’s up", detail: "A short sound when the timer ends.", value: $preferences.timerSound).disabled(!preferences.timerEnabled)
            } header: { Text("Timer") } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    footnote("Turning off the timer module resets a running timer.")
                    footnote("The timer runs while Brimlet is open and ends when you quit it.")
                }
            }
        }
    }

    private var calendarSettings: some View {
        Group {
            if !preferences.calendarEnabled {
                Section {
                    HStack {
                        Label("Calendar is off", systemImage: "calendar")
                        Spacer()
                        Button("Turn On") { preferences.calendarEnabled = true }.buttonStyle(.borderedProminent)
                    }
                } footer: { calendarPrivacy }
            } else {
                Section("Access") {
                    calendarAccess
                }
                if model.calendar.access == .ready {
                    Section {
                        Picker("Event reminder", selection: $preferences.calendarReminderMinutes) {
                            Text("Off").tag(0)
                            Text("5 minutes before").tag(5)
                            Text("10 minutes before").tag(10)
                        }
                    } footer: { footnote("Shows a short reminder while Brimlet is open and visible. Not for all-day events.") }
                    Section {
                        Toggle("All Calendars", isOn: Binding(get: { preferences.calendarSelection == nil }, set: { all in
                            preferences.calendarSelection = all ? nil : model.calendar.calendars.map(\.id)
                        })).toggleStyle(.switch)
                        ForEach(model.calendar.calendars) { source in
                            Toggle(isOn: Binding(get: { preferences.calendarSelection?.contains(source.id) ?? true }, set: { selected in
                                var ids = Set(preferences.calendarSelection ?? model.calendar.calendars.map(\.id))
                                if selected { ids.insert(source.id) } else { ids.remove(source.id) }
                                preferences.calendarSelection = ids.sorted()
                            })) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        if let color = source.colorRGB { Circle().fill(Color(hex: color)).frame(width: 7, height: 7) }
                                        Text(source.title)
                                    }
                                    Text(source.account).font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                            }.toggleStyle(.checkbox)
                        }
                        if model.calendar.calendars.isEmpty { footnote("Your calendars appear here once Brimlet has access.") }
                    } header: { Text("Calendars") } footer: {
                        if preferences.calendarSelection?.isEmpty == true {
                            footnote("No calendar is selected, so no events or reminders are shown.")
                        } else { calendarPrivacy }
                    }
                } else {
                    Section { footnote("Your calendars appear here once Brimlet has access.") } footer: { calendarPrivacy }
                }
            }
        }
    }

    @ViewBuilder private var calendarAccess: some View {
        switch model.calendar.access {
        case .ready: Label("Full access", systemImage: "checkmark.circle")
        case .requesting:
            HStack { ProgressView().controlSize(.small); Text("Waiting for calendar access…") }
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: 8) {
                Label("Calendar access is off", systemImage: "exclamationmark.triangle")
                footnote(model.calendar.access == .restricted ? "Calendar access is restricted on this Mac." : "Turn on full access in System Settings › Privacy & Security › Calendars.")
                if model.calendar.access != .restricted { Button("Open System Settings") { model.calendar.openPrivacySettings() } }
            }
        case .notRequested, .failed:
            VStack(alignment: .leading, spacing: 8) {
                footnote(model.calendar.access == .failed ? "Couldn’t connect to Calendar. You can try again." : "Allow calendar access to see your upcoming events.")
                Button("Connect Calendar") { model.calendar.requestAccess() }.buttonStyle(.borderedProminent)
            }
        }
    }

    private var calendarPrivacy: some View {
        footnote("Turning on Calendar asks macOS for access. Events are only read; your calendar is never changed.")
    }

    private var notificationSettings: some View {
        Group {
            Section {
                if preferences.externalNotificationRequirements.isEmpty { Text("No apps allowed yet").foregroundStyle(.secondary) }
                ForEach(preferences.externalNotificationRequirements.keys.sorted(), id: \.self) { id in
                    AllowedApplicationRow(id: id) { preferences.externalNotificationRequirements.removeValue(forKey: id) }
                }
                if let error = model.externalReceiverError { Text(error).font(.system(size: 11)).foregroundStyle(.orange) }
                Button("Allow an App…") { model.authorizeExternalApplication() }
            } header: { Text("Notifications from other apps") } footer: { footnote("Apps you allow can show short notifications in Brimlet.") }
            if CmuxSessionWatcher.isInstalled {
                Section("cmux") {
                    settingToggle("Show cmux sessions", detail: "Checks every 5 seconds for sessions waiting for your reply and opens them in cmux.", value: $preferences.cmuxEnabled)
                }
            }
        }
    }

    private var quoteSettings: some View {
        Group {
            Section {
                settingToggle("Show a quote now and then", detail: "The card slides in from the right edge and leaves the modules alone.", value: $preferences.quotesEnabled)
                Picker("How often?", selection: $preferences.quoteIntervalMinutes) {
                    Text("Every 15 minutes").tag(15)
                    Text("Every 30 minutes").tag(30)
                    Text("Every hour").tag(60)
                    Text("Every 2 hours").tag(120)
                    Text("Every 6 hours").tag(360)
                    Text("Every 12 hours").tag(720)
                    Text("Once a day").tag(1440)
                    Text("Every 2 days").tag(2880)
                }.font(.system(size: 12)).disabled(!preferences.quotesEnabled)
                Picker("Stays on screen for", selection: $preferences.quoteDisplaySeconds) {
                    Text("10 seconds").tag(10)
                    Text("15 seconds").tag(15)
                    Text("30 seconds").tag(30)
                    Text("1 minute").tag(60)
                    Text("2 minutes").tag(120)
                    Text("Until I close it").tag(0)
                }.font(.system(size: 12))
                Text("The card stays while the pointer is on it. Close it any time with ×.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)

            }
            Section {
                if model.quotes.quotes.isEmpty {
                    footnote("Select some text in a PDF or a web page, Control-click it and choose Services › Add to Brimlet as Quote.")
                }
                ForEach(model.quotes.quotes) { quote in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: "“\(quote.text)”").font(.system(size: 13, design: .serif)).lineLimit(3)
                            let attribution = [quote.author, quote.source].filter { !$0.isEmpty }.joined(separator: " · ")
                            if !attribution.isEmpty { Text(attribution).font(.system(size: 11)).foregroundStyle(.secondary) }
                        }
                        Spacer(minLength: 0)
                        Button(role: .destructive) { model.quotes.delete(quote) } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless).help("Delete Quote").accessibilityLabel("Delete Quote")
                    }
                }
                if let quote = model.quotes.quotes.first { Button("Show Now") { model.onShowQuote?(quote) } }
            } header: { Text("Saved quotes · \(model.quotes.quotes.count)") } footer: {
                footnote("Your quotes are kept on this Mac. Quotes you haven’t seen yet come first.")
            }
        }
    }

    private var general: some View {
        Group {
            Section {
                HStack(spacing: 10) {
                    Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 32, height: 32)
                    UpdateRow(updater: updater)
                }
                settingToggle("Check for updates automatically", detail: "Once a day Brimlet asks GitHub for the latest version number.", value: $updater.automatic)
            }
            Section {
                settingToggle("Open at Login", detail: "Starts Brimlet when you log in.", value: loginBinding)
                if let loginError { Text(loginError).font(.system(size: 11)).foregroundStyle(.orange) }
            }
            Section {
                Picker("Display", selection: $preferences.displayID) {
                    Text("Automatic · Notched display first").tag("auto")
                    ForEach(model.availableDisplays, id: \.id) { display in Text(display.name).tag(display.id) }
                    if preferences.displayID != "auto" && !model.availableDisplays.contains(where: { $0.id == preferences.displayID }) {
                        Text("Chosen display isn’t connected").tag(preferences.displayID)
                    }
                }
                footnote("If the display goes away, Brimlet moves to another one. On displays without a notch it shows as a small capsule.")
                settingToggle("Expand on hover", detail: "You can also click it open.", value: $preferences.expandOnHover)
                settingToggle("Hide in full screen", detail: "Leaves the space empty when an app fills the screen.", value: $preferences.hideInFullscreen)
                Button("Show Brimlet") { model.hidden = false; model.expand() }
            } header: { Text("On Screen") } footer: {
                footnote("Brimlet follows the Reduce Motion setting of macOS. Click its top bar to close it, or press Esc while it has keyboard focus.")
            }
            Section {
                Label("No account, no analytics.", systemImage: "lock.shield")
                footnote("Brimlet asks for macOS Automation access only when you connect Spotify. It uses it to read the current track and control playback.")
                footnote("Album art comes from Spotify’s servers and lyrics from LRCLIB. There is no account and no analytics, and nothing is sent to a server of ours.")
            }
        }
    }

    private var loginBinding: Binding<Bool> {
        Binding(get: { launchAtLogin }, set: { enabled in
            do {
                if enabled { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
                loginError = nil
            } catch {
                loginError = String(localized: "Open at Login couldn’t be changed. Move Brimlet to Applications and try again.")
            }
            let status = SMAppService.mainApp.status
            launchAtLogin = status == .enabled || status == .requiresApproval
            if status == .requiresApproval {
                loginError = String(localized: "Allow Brimlet in System Settings › General › Login Items.")
            }
        })
    }

    private func moduleDescription(_ module: ModuleID) -> LocalizedStringKey {
        switch module {
        case .music: return "Spotify · The track and playback controls"
        case .timer: return "A short break or some focus time"
        case .calendar: return "Upcoming events and meeting links"
        case .todos: return "Keep track of home, personal and work tasks"
        }
    }

    private func moduleBinding(_ module: ModuleID) -> Binding<Bool> {
        switch module {
        case .music: return $preferences.musicEnabled
        case .timer: return $preferences.timerEnabled
        case .calendar: return $preferences.calendarEnabled
        case .todos: return $preferences.todosEnabled
        }
    }


    private func footnote(_ text: LocalizedStringKey) -> some View {
        Text(text).font(.system(size: 11)).foregroundStyle(.secondary)
            .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingToggle(_ title: LocalizedStringKey, detail: LocalizedStringKey, value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                footnote(detail)
            }
        }.toggleStyle(.switch)
    }
}

private struct AllowedApplicationRow: View {
    let id: String
    let remove: () -> Void
    @State private var url: URL?

    var body: some View {
        HStack(spacing: 10) {
            if let url { Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)).resizable().frame(width: 24, height: 24) }
            VStack(alignment: .leading, spacing: 2) {
                Text(url.map { FileManager.default.displayName(atPath: $0.path) } ?? id)
                if url != nil { Text(id).font(.system(size: 11)).foregroundStyle(.secondary) }
            }
            Spacer()
            Button("Remove", action: remove)
        }.onAppear { url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) }
    }
}

private struct UpdateRow: View {
    @ObservedObject var updater: Updater

    var body: some View {
        if let release = updater.release, let version = release.version {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Brimlet \(version.description) is available").font(.system(size: 12, weight: .medium))
                    switch updater.status {
                    case .downloading(let fraction):
                        ProgressView(value: fraction).accessibilityLabel("Downloading Brimlet \(version.description)")
                    case .opening:
                        detail("Drag Brimlet from the disk image to Applications and replace this version.")
                    case .failed(let reason):
                        Text(reason).font(.system(size: 11)).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                    default:
                        HStack(spacing: 4) {
                            detail("You have \(updater.current.description).")
                            Link("Release Notes", destination: release.page).font(.system(size: 11))
                        }
                    }
                }
                Spacer(minLength: 0)
                Button("Download and Install") { updater.install() }
                    .buttonStyle(.borderedProminent).disabled(busy)
                    .help("Downloads the disk image and opens it, then Brimlet quits so you can drag the new version to Applications.")
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Brimlet \(updater.current.description)").font(.system(size: 12, weight: .medium))
                    switch updater.status {
                    case .checking: detail("Checking for updates…")
                    case .upToDate: detail("This is the latest version.")
                    case .checkFailed(let reason):
                        Text("Couldn’t check for updates. \(reason)").font(.system(size: 11)).foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    default:
                        if let lastCheck = updater.lastCheck {
                            detail("Last checked: \(lastCheck.formatted(date: .abbreviated, time: .shortened))")
                        } else {
                            detail("Not checked yet.")
                        }
                    }
                }
                Spacer(minLength: 0)
                Button("Check Now") { updater.check(manual: true) }.font(.system(size: 11)).disabled(updater.status == .checking)
            }
        }
    }

    private var busy: Bool {
        switch updater.status {
        case .downloading, .opening: return true
        default: return false
        }
    }

    private func detail(_ text: LocalizedStringKey) -> some View {
        Text(text).font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }
}

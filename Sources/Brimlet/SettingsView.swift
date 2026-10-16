import AppKit
import SwiftUI
import ServiceManagement
import BrimletCore

enum SettingsTab: Int { case modules, appearance, general, quotes }

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var preferences: Preferences
    @ObservedObject var updater: Updater
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 42, height: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: "Brimlet").font(.system(size: 22, weight: .semibold, design: .rounded))
                        Text("A little room up top.").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                }.padding(.bottom, 27).padding(.top, 20)
                navigation("Modules", symbol: "square.stack.3d.up", tab: .modules)
                navigation("Appearance", symbol: "rectangle.topthird.inset.filled", tab: .appearance)
                navigation("General", symbol: "slider.horizontal.3", tab: .general)
                navigation("Quotes", symbol: "quote.opening", tab: .quotes)
                Spacer()
                HStack(spacing: 5) {
                    Circle().fill(BrimletTheme.mint).frame(width: 5, height: 5)
                    Text("No account, no analytics.").font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Text("Version \(updater.current.description)").font(.system(size: 9)).foregroundStyle(.tertiary).padding(.top, 5)
            }
            .padding(20).frame(width: 205)
            .background(Color.white.opacity(0.025))
            Rectangle().fill(Color.white.opacity(0.07)).frame(width: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    switch model.settingsTab {
                    case .modules: modules
                    case .appearance: appearance
                    case .general: general
                    case .quotes: quoteSettings
                    }
                }.padding(28)
            }.frame(maxWidth: .infinity)
        }
        .frame(width: 700, height: 550)
        .background(Color(red: 0.075, green: 0.085, blue: 0.085))
        .foregroundStyle(Color.white)
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
        .tint(BrimletTheme.mint)
    }

    private func navigation(_ title: LocalizedStringKey, symbol: String, tab: SettingsTab) -> some View {
        let selected = model.settingsTab == tab
        return Button { model.settingsTab = tab } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol).frame(width: 18)
                Text(title)
                Spacer()
            }
            .font(.system(size: 12, weight: selected ? .semibold : .regular))
            .foregroundStyle(selected ? BrimletTheme.mint : Color.white.opacity(0.55))
            .padding(.horizontal, 12).padding(.vertical, 11)
            .background(selected ? BrimletTheme.mint.opacity(0.09) : Color.clear, in: RoundedRectangle(cornerRadius: 9))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var modules: some View {
        Group {
            heading("What should live up here?", subtitle: "Turn on what you need, in the order you like.")
            VStack(spacing: 10) {
                ForEach(preferences.moduleOrder) { module in
                    HStack(spacing: 12) {
                        Image(systemName: module.symbol).font(.system(size: 18)).foregroundStyle(BrimletTheme.mint)
                            .frame(width: 38, height: 42).background(BrimletTheme.mint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(module.title).font(.system(size: 13, weight: .semibold))
                            Text(moduleDescription(module))
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        VStack(spacing: 1) {
                            Button { preferences.move(module, by: -1) } label: { Image(systemName: "chevron.up").font(.system(size: 9)) }
                                .disabled(preferences.moduleOrder.first == module).help("Move Up")
                            Button { preferences.move(module, by: 1) } label: { Image(systemName: "chevron.down").font(.system(size: 9)) }
                                .disabled(preferences.moduleOrder.last == module).help("Move Down")
                        }.buttonStyle(.plain).foregroundStyle(.secondary)
                        Toggle(module.title, isOn: moduleBinding(module))
                            .labelsHidden().toggleStyle(.switch).controlSize(.small)
                    }.padding(13).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 13))
                }
            }
            Text("When several modules have something going on, the higher one wins. In the open panel, the tabs switch between them.")
                .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(4)
            VStack(alignment: .leading, spacing: 16) {
                settingToggle("Keep music in front", detail: "The small view always shows the music module.", value: $preferences.pinMusic)
                settingToggle("Show track changes", detail: "Briefly shows the new track.", value: $preferences.trackAlerts)
                settingToggle("Play a sound when time’s up", detail: "A short sound when the timer ends.", value: $preferences.timerSound)
            }
            if !preferences.spotifyRequested {
                Button("Connect to Spotify") { model.connectSpotify() }.buttonStyle(MintButtonStyle()).disabled(!preferences.musicEnabled)
            } else {
                HStack {
                    Label("Connected to Spotify", systemImage: "checkmark.circle").font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer()
                    Button("Disconnect") { preferences.spotifyRequested = false }.font(.system(size: 11))
                }
            }
            if preferences.calendarEnabled { calendarSettings }
            VStack(alignment: .leading, spacing: 8) {
                Text("Notifications from other apps").font(.system(size: 13, weight: .semibold))
                Text("Apps you allow can show short notifications in Brimlet.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                ForEach(preferences.externalNotificationRequirements.keys.sorted(), id: \.self) { id in
                    HStack {
                        Text(verbatim: id).font(.system(size: 11))
                        Spacer()
                        Button("Remove") { preferences.externalNotificationRequirements.removeValue(forKey: id) }
                    }
                }
                Button("Allow an App…") { model.authorizeExternalApplication() }
                if let error = model.externalReceiverError { Text(error).font(.system(size: 11)).foregroundStyle(.orange) }
            }
            if CmuxSessionWatcher.isInstalled {
                VStack(alignment: .leading, spacing: 10) {
                    settingToggle("Show cmux sessions", detail: "Checks every 5 seconds for sessions waiting for your reply and opens them in cmux.", value: $preferences.cmuxEnabled)
                }.padding(14).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            }
            Text("Turning on Calendar asks macOS for access. Events are only read; your calendar is never changed.")
                .font(.system(size: 10)).foregroundStyle(.secondary)
            Text("Turning off the timer module resets a running timer.").font(.system(size: 10)).foregroundStyle(.tertiary)
        }
    }

    private var calendarSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar").font(.system(size: 14, weight: .semibold))
            Picker("Event reminder", selection: $preferences.calendarReminderMinutes) {
                Text("Off").tag(0)
                Text("5 minutes before").tag(5)
                Text("10 minutes before").tag(10)
            }.font(.system(size: 12))
            Text("Shows a short reminder while Brimlet is open and visible. Not for all-day events.")
                .font(.system(size: 10)).foregroundStyle(.secondary)
            Divider()
            Toggle("All Calendars", isOn: Binding(get: {
                preferences.calendarSelection == nil
            }, set: { all in
                preferences.calendarSelection = all ? nil : model.calendar.calendars.map(\.id)
            })).toggleStyle(.switch).controlSize(.small)
            if model.calendar.calendars.isEmpty {
                Text("Your calendars appear here once Brimlet has access.")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            }
            ForEach(model.calendar.calendars) { source in
                Toggle(isOn: Binding(get: {
                    preferences.calendarSelection?.contains(source.id) ?? true
                }, set: { selected in
                    var ids = Set(preferences.calendarSelection ?? model.calendar.calendars.map(\.id))
                    if selected { ids.insert(source.id) } else { ids.remove(source.id) }
                    preferences.calendarSelection = ids.sorted()
                })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(source.title).font(.system(size: 12))
                        Text(source.account).font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }.toggleStyle(.checkbox)
            }
            if preferences.calendarSelection?.isEmpty == true {
                Text("No calendar is selected, so no events or reminders are shown.")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }.padding(16).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 13))
    }

    private var quoteSettings: some View {
        Group {
            heading("Words to keep you company.", subtitle: "Quotes you save show up next to Brimlet, on a calm card of their own.")
            VStack(alignment: .leading, spacing: 15) {
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
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            }.padding(16).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 13))
            HStack {
                Text("Saved quotes · \(model.quotes.quotes.count)").font(.system(size: 13, weight: .semibold))
                Spacer()
                if let quote = model.quotes.quotes.first {
                    Button("Show Now") { model.onShowQuote?(quote) }.font(.system(size: 11))
                }
            }
            if model.quotes.quotes.isEmpty {
                Text("Select some text in a PDF or a web page, Control-click it and choose Services › Add to Brimlet as Quote.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(4)
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(model.quotes.quotes) { quote in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(verbatim: "“\(quote.text)”").font(.system(size: 12, design: .serif)).lineLimit(4)
                            let attribution = [quote.author, quote.source].filter { !$0.isEmpty }.joined(separator: " · ")
                            if !attribution.isEmpty { Text(attribution).font(.system(size: 10)).foregroundStyle(.secondary) }
                        }
                        Spacer(minLength: 0)
                        Button(role: .destructive) { model.quotes.delete(quote) } label: { Image(systemName: "trash") }
                            .buttonStyle(.plain).foregroundStyle(.secondary).help("Delete Quote")
                    }.padding(13).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            Text("Your quotes are kept on this Mac. Quotes you haven’t seen yet come first.")
                .font(.system(size: 10)).foregroundStyle(.tertiary).lineSpacing(3)
        }
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

    private var appearance: some View {
        Group {
            heading("Right where it belongs.", subtitle: "How Brimlet behaves on your screen.")
            VStack(alignment: .leading, spacing: 18) {
                Picker("Display", selection: $preferences.displayID) {
                    Text("Automatic · Notched display first").tag("auto")
                    ForEach(model.availableDisplays, id: \.id) { display in Text(display.name).tag(display.id) }
                    if preferences.displayID != "auto" && !model.availableDisplays.contains(where: { $0.id == preferences.displayID }) {
                        Text("Chosen display isn’t connected").tag(preferences.displayID)
                    }
                }.font(.system(size: 12))
                Text("If the display goes away, Brimlet moves to another one. On displays without a notch it shows as a small capsule.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(4)
                Divider()
                settingToggle("Expand on hover", detail: "You can also click it open.", value: $preferences.expandOnHover)
                settingToggle("Hide in full screen", detail: "Leaves the space empty when an app fills the screen.", value: $preferences.hideInFullscreen)
            }.padding(18).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 13))
            Text("Brimlet follows the Reduce Motion setting of macOS. Click its top bar to close it, or press Esc while it has keyboard focus.")
                .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(4)
            Button("Show Brimlet") {
                model.hidden = false
                model.expand()
            }.buttonStyle(MintButtonStyle())
        }
    }

    private var general: some View {
        Group {
            heading("Simple and local.", subtitle: "No account needed.")
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Open at Login").font(.system(size: 12, weight: .medium))
                    Spacer()
                    Toggle("Open at Login", isOn: loginBinding).labelsHidden().toggleStyle(.switch).controlSize(.small)
                }
                if let loginError { Text(loginError).font(.system(size: 11)).foregroundStyle(.orange) }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 14) {
                settingToggle("Check for updates automatically", detail: "Once a day Brimlet asks GitHub for the latest version number.", value: $updater.automatic)
                Divider()
                UpdateRow(updater: updater)
            }.padding(18).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 10) {
                Label("Privacy", systemImage: "lock.shield").font(.system(size: 12, weight: .semibold))
                Text("Brimlet asks for macOS Automation access only when you connect Spotify. It uses it to read the current track and control playback.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(4)
                Text("Album art comes from Spotify’s servers and lyrics from LRCLIB. There is no account and no analytics, and nothing is sent to a server of ours.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(4)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 13))
            Text("The timer runs while Brimlet is open and ends when you quit it.")
                .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(4)
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

    private func heading(_ title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 24, weight: .semibold, design: .rounded))
            Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
        }.padding(.top, 9)
    }

    private func settingToggle(_ title: LocalizedStringKey, detail: LocalizedStringKey, value: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 12, weight: .medium))
                Text(detail).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle(title, isOn: value).labelsHidden().toggleStyle(.switch).controlSize(.small)
        }
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
                        Text(reason).font(.system(size: 10)).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                    default:
                        HStack(spacing: 4) {
                            detail("You have \(updater.current.description).")
                            Link("Release Notes", destination: release.page).font(.system(size: 10))
                        }
                    }
                }
                Spacer(minLength: 0)
                Button("Download and Install") { updater.install() }
                    .buttonStyle(MintButtonStyle()).disabled(busy)
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
                        Text("Couldn’t check for updates. \(reason)").font(.system(size: 10)).foregroundStyle(.orange)
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
        Text(text).font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }
}

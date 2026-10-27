import AppKit
import SwiftUI
import BrimletCore

struct IslandShape: Shape {
    var hasNotch: Bool
    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(topLeadingRadius: hasNotch ? 5 : 20,
                               bottomLeadingRadius: 24, bottomTrailingRadius: 24,
                               topTrailingRadius: hasNotch ? 5 : 20).path(in: rect)
    }
}

struct IslandView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(spacing: 0) {
            header
            if model.isExpanded {
                expandedBody
                    .transition(.opacity)
            } else if model.isPeeking {
                peek
                    .transition(.opacity)
            }
        }
        .frame(width: model.width, height: model.height, alignment: .top)
        .background(Color.black)
        .clipShape(IslandShape(hasNotch: model.geometry.hasNotch))
        .overlay {
            IslandShape(hasNotch: model.geometry.hasNotch)
                .strokeBorderCompatible(Color.white.opacity(contrast == .increased ? 0.2 : 0.09))
                .mask(alignment: .bottom) { Rectangle().padding(.top, model.geometry.hasNotch ? 1 : 0) }
                .allowsHitTesting(false)
        }
        // AppKit animates the window's height independently of SwiftUI's target height.
        // Keep that target-sized content at the top of the intermediate hosting bounds.
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .clipped()
        .contentShape(IslandShape(hasNotch: model.geometry.hasNotch))
        .onHover { model.hover($0) }
        .foregroundStyle(BrimletTheme.primary)
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : .easeInOut(duration: LyricsPresentation.resizeDuration), value: model.music.lyricsVisible)
        .animation(reduceMotion ? nil : .smooth(duration: 0.24), value: model.isExpanded)
        .animation(reduceMotion ? nil : .smooth(duration: 0.24), value: model.isPeeking)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.currentModule)
    }

    private var header: some View {
        Button { model.isExpanded ? model.collapse() : model.expand() } label: {
            HStack(spacing: 0) {
                Group {
                    if model.currentModule == .music && model.music.track != nil {
                        AlbumArt(image: model.music.artwork, size: 23, demo: model.demo)
                    } else {
                        Image(systemName: model.currentModule?.symbol ?? "circle.hexagongrid.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(BrimletTheme.secondary)
                    }
                }
                .frame(width: 44)
                .overlay(alignment: .topTrailing) {
                    if !model.cmux.sessions.isEmpty {
                        Text(model.cmux.sessions.count > 9 ? "9+" : "\(model.cmux.sessions.count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(minWidth: 15, minHeight: 15)
                            .background(BrimletTheme.mint, in: Circle())
                            .offset(x: -2, y: 1)
                            .accessibilityLabel("\(model.cmux.sessions.count) cmux sessions waiting for you")
                    }
                }
                Spacer(minLength: model.geometry.hasNotch ? model.geometry.notchWidth : 20)
                Group {
                    if model.currentModule == .timer {
                        if model.timer.countdown.phase == .running || model.timer.countdown.phase == .paused {
                            Text(Countdown.formatted(model.timer.countdown.remaining(at: model.timer.now)))
                                .font(.system(size: 12, weight: .semibold)).monospacedDigit()
                                .foregroundStyle(model.timer.countdown.phase == .running ? BrimletTheme.mint : BrimletTheme.secondary)
                        } else {
                            Image(systemName: model.timer.countdown.phase == .finished ? "checkmark" : "timer")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(BrimletTheme.secondary)
                        }
                    } else if model.currentModule == .calendar {
                        Text(model.calendar.compactText)
                            .font(.system(size: 12, weight: .semibold)).monospacedDigit()
                            .foregroundStyle(BrimletTheme.primary)
                            .accessibilityLabel(model.calendar.next?.status(at: model.calendar.now) ?? String(localized: "No upcoming events"))
                    } else {
                        Equalizer(active: model.music.track?.isPlaying == true, animate: !reduceMotion && model.isPresented)
                    }
                }.frame(width: 44)
            }
            .padding(.horizontal, 8)
            .frame(height: model.geometry.headerHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(model.isExpanded ? "Collapse Brimlet" : "Expand Brimlet")
        .help(model.isExpanded ? "Collapse" : "Expand")
    }

    private var expandedBody: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                // Narrow layouts keep the selected title and show symbols for the other tabs.
                ViewThatFits(in: .horizontal) {
                    tabBar(titles: true)
                    tabBar(titles: false)
                }
                SettingsUpdateButton(updater: model.updater) {
                    if model.updater.release != nil { model.settingsTab = .general }
                    model.onOpenSettings?()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 10)

            if model.isShowingCmuxQueue {
                cmuxQueue
            } else {
                switch model.currentModule {
                case .music: MusicCard(module: model.music, connect: model.connectSpotify, demo: model.demo)
                case .timer: TimerCard(module: model.timer)
                case .calendar: CalendarCard(module: model.calendar)
                case .todos: TodoCard(module: model.todos)
                case nil:
                    EmptyCard(symbol: "square.stack.3d.up", title: "This space is yours", subtitle: "Start by turning on a module in Settings.", actionTitle: "Choose Modules") {
                        model.settingsTab = .modules
                        model.onOpenSettings?()
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: model.height - model.geometry.headerHeight)
    }

    private func tabBar(titles: Bool) -> some View {
        HStack(spacing: 6) {
            ForEach(model.modules) { module in
                let selected = model.currentModule == module
                Button { model.select(module) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: module.symbol).font(.system(size: 13, weight: .medium))
                        if titles || selected {
                            Text(module.title).font(.system(size: 12, weight: .medium)).lineLimit(1).fixedSize()
                        }
                        if module == .timer && model.timer.countdown.phase == .running {
                            Circle().fill(BrimletTheme.mint).frame(width: 4, height: 4)
                        }
                    }
                    .foregroundStyle(selected ? Color.white : BrimletTheme.secondary)
                    .padding(.horizontal, 10).frame(height: 28)
                }
                .buttonStyle(IslandSelectionStyle(selected: selected))
                .help(module.title)
                .accessibilityLabel(module.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .onMoveCommand { direction in
                    guard let index = model.modules.firstIndex(of: module) else { return }
                    let offset = direction == .left ? -1 : direction == .right ? 1 : 0
                    if offset != 0 { model.select(model.modules[(index + offset + model.modules.count) % model.modules.count]) }
                }
            }
            Spacer(minLength: 0)
            if !model.cmux.sessions.isEmpty {
                Button { model.isShowingCmuxQueue.toggle() } label: {
                    Label("\(model.cmux.sessions.count)", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(BrimletTheme.mint)
                        .padding(.horizontal, 9).padding(.vertical, 6)
                        .background(BrimletTheme.mint.opacity(0.1), in: Capsule())
                }.buttonStyle(.plain).help("cmux sessions waiting for you")
            }

        }
    }

    @ViewBuilder private var peek: some View {
        if let notification = model.externalNotification {
            externalPeek(notification)
        } else if let session = model.cmux.sessions.first {
            cmuxPeek(session)
        } else {
            regularPeek
        }
    }

    private var cmuxQueue: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sessions waiting for you").font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("Live · every 5 s").font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)
            }
            if model.cmux.sessions.isEmpty {
                Text("No session is waiting for you.").font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary).padding(.top, 24)
            } else {
                ScrollView {
                    VStack(spacing: 5) {
                        ForEach(model.cmux.sessions) { session in
                            Button { model.cmux.open(session) } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "terminal.fill").foregroundStyle(BrimletTheme.secondary).frame(width: 18)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(session.title).font(.system(size: 11, weight: .medium)).lineLimit(1)
                                        Text("\(session.agent) · Waiting for your reply").font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary).lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right").font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)
                                }.padding(.horizontal, 10).padding(.vertical, 7).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 9))
                            }.buttonStyle(.plain).help("Open this session in cmux")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20).frame(height: 186, alignment: .top)
    }

    private func cmuxPeek(_ session: WaitingCmuxSession) -> some View {
        Button { model.cmux.open(session) } label: {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill").font(.system(size: 22)).foregroundStyle(BrimletTheme.mint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(session.title) is waiting").font(.system(size: 12, weight: .semibold)).lineLimit(1)
                    Text("\(session.agent) · Open in cmux").font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
                if model.cmux.sessions.count > 1 {
                    Text("+\(model.cmux.sessions.count - 1)").font(.system(size: 11, weight: .semibold)).foregroundStyle(BrimletTheme.mint)
                }
                Image(systemName: "arrow.up.right").font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)
            }.padding(.horizontal, 20).frame(height: 66).contentShape(Rectangle())
        }.buttonStyle(.plain).help("Open this session in cmux")
    }

    private var regularPeek: some View {
        HStack(spacing: 12) {
            Button { model.expand() } label: {
                HStack(spacing: 12) {
                    if model.currentModule == .music {
                        AlbumArt(image: model.music.artwork, size: 40, demo: model.demo)
                    } else {
                        Image(systemName: model.currentModule == .calendar ? "calendar.badge.clock" : "checkmark.circle.fill").font(.system(size: 20)).foregroundStyle(BrimletTheme.primary)
                            .frame(width: 40, height: 40).background(BrimletTheme.raised, in: RoundedRectangle(cornerRadius: 10))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.activity?.title ?? "Brimlet").font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        Text(model.activity?.subtitle ?? "").font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Expand Brimlet")

            if model.currentModule == .calendar, let event = model.calendar.reminderEvent, event.meetingURL != nil {
                Button("Join") { model.calendar.openMeeting(event) }.buttonStyle(MintButtonStyle())
                    .accessibilityLabel("Join the meeting")
            }
            if model.currentModule == .music, let track = model.music.track {
                HStack(spacing: 5) {
                    peekControl("backward.fill", label: "Previous Track") { model.music.send(.previous) }
                    peekControl(track.isPlaying ? "pause.fill" : "play.fill",
                                label: track.isPlaying ? "Pause" : "Play", prominent: true) {
                        model.music.send(.playPause)
                    }
                    peekControl("forward.fill", label: "Next Track") { model.music.send(.next) }
                    peekControl("quote.bubble", label: "Show Lyrics") {
                        model.expand()
                        model.music.toggleLyrics()
                    }
                }
                .fixedSize()
                .disabled(model.music.commandPending)
                .opacity(model.music.commandPending ? 0.45 : 1)
            }
        }
        .padding(.horizontal, 20).frame(height: 66)
    }

    private func externalPeek(_ notification: ExternalNotification) -> some View {
        HStack(spacing: 12) {
            Image(systemName: notification.symbol).font(.system(size: 20, weight: .medium)).foregroundStyle(BrimletTheme.primary)
                .frame(width: 40, height: 40).background(BrimletTheme.raised, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                Text(notification.body).font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary).lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20).frame(height: 66)
        .accessibilityElement(children: .combine)
        .onTapGesture { model.dismissExternalNotification() }
        .accessibilityAction(named: "Dismiss Notification") { model.dismissExternalNotification() }
    }

    private func peekControl(_ symbol: String, label: LocalizedStringKey, prominent: Bool = false,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: prominent ? 12 : 11, weight: .semibold))
                .foregroundStyle(prominent ? BrimletTheme.ink : BrimletTheme.primary)
                .frame(width: prominent ? 30 : 28, height: 30)
                .background(prominent ? BrimletTheme.mint : Color.clear, in: Circle())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

private extension Shape {
    func strokeBorderCompatible(_ color: Color) -> some View { stroke(color, lineWidth: 1) }
}

/// Observe the updater directly so a background check updates the dot while the panel is open.
private struct SettingsUpdateButton: View {
    @ObservedObject var updater: Updater
    let action: () -> Void

    private var label: LocalizedStringKey {
        updater.release == nil ? "Settings" : "Settings — Update available"
    }

    var body: some View {
        IconButton(symbol: "gearshape", help: label, action: action)
            .overlay(alignment: .topTrailing) {
                if updater.release != nil {
                    Circle()
                        .fill(BrimletTheme.mint)
                        .frame(width: 7, height: 7)
                        .overlay { Circle().stroke(Color.black, lineWidth: 2) }
                        .offset(x: -1, y: 1)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }
}

struct IconButton: View {
    let symbol: String
    let help: LocalizedStringKey
    var size: CGFloat = 15
    var prominent = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: size, weight: .medium))
                .foregroundStyle(prominent ? BrimletTheme.ink : BrimletTheme.secondary).frame(width: 28, height: 28)
                .background(prominent ? BrimletTheme.mint : .clear, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }
        .buttonStyle(IslandSelectionStyle()).help(help).accessibilityLabel(help)
    }
}

struct AlbumArt: View {
    var image: NSImage?
    var size: CGFloat
    var demo = false
    var body: some View {
        Group {
            if let image { Image(nsImage: image).resizable().scaledToFill() }
            else if demo {
                ZStack {
                    LinearGradient(colors: [Color(red: 0.16, green: 0.41, blue: 0.51), Color(red: 0.77, green: 0.85, blue: 0.73)], startPoint: .top, endPoint: .bottom)
                    Circle().fill(Color(red: 0.95, green: 0.54, blue: 0.37)).frame(width: size * 0.52).offset(y: -size * 0.04)
                    VStack { Spacer(); Rectangle().fill(Color(red: 0.12, green: 0.32, blue: 0.38)).frame(height: size * 0.27) }
                }
            } else {
                ZStack {
                    LinearGradient(colors: [Color(white: 0.17), Color(white: 0.07)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "music.note").font(.system(size: size * 0.38, weight: .medium)).foregroundStyle(BrimletTheme.mint)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.16))
        .overlay(RoundedRectangle(cornerRadius: size * 0.16).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
        .accessibilityHidden(true)
    }
}

struct Equalizer: View {
    let active: Bool
    var animate = true
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12, paused: !active || !animate)) { context in
            HStack(alignment: .center, spacing: 2.5) {
                ForEach(0..<5) { index in
                    let phase = context.date.timeIntervalSinceReferenceDate * 4 + Double(index) * 1.4
                    let height = active ? (animate ? 5 + (sin(phase) + 1) * 6 : Double([7, 14, 9, 16, 11][index])) : 4
                    Capsule().fill(active ? BrimletTheme.mint : BrimletTheme.secondary).frame(width: 2.5, height: height)
                }
            }.frame(width: 24, height: 20)
        }
        .accessibilityLabel(active ? "Playing" : "Paused")
    }
}

struct EmptyCard: View {
    let symbol: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let action: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 22, weight: .medium)).foregroundStyle(BrimletTheme.secondary)
            VStack(spacing: 5) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary).multilineTextAlignment(.center)
            }
            Button(actionTitle, action: action).buttonStyle(MintButtonStyle()).padding(.top, 2)
        }
        .frame(maxWidth: .infinity).frame(height: 158).padding(.horizontal, 20)
    }
}

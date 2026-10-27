import AppKit
import SwiftUI
import BrimletCore

struct MusicCard: View {
    @ObservedObject var module: MusicModule
    let connect: () -> Void
    var demo = false
    @State private var seekValue: Double?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let track = module.track {
            VStack(spacing: 13) {
                HStack(spacing: 14) {
                    AlbumArt(image: module.artwork, size: 64, demo: demo)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(track.title).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                        Text(track.artist).font(.system(size: 12)).foregroundStyle(BrimletTheme.secondary).lineLimit(1)
                        Text(verbatim: "Spotify").font(.system(size: 11)).foregroundStyle(BrimletTheme.tertiary)
                    }
                    Spacer(minLength: 0)
                    IconButton(symbol: "arrow.up.right", help: "Open in Spotify") { module.openSpotify() }
                }
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 3) {
                        SeekBar(value: seekValue ?? track.elapsed(at: context.date), duration: track.duration,
                                enabled: !module.commandPending && track.duration > 0,
                                onChange: { seekValue = $0 }, onCommit: { value in
                            module.send(.seek(value))
                            seekValue = nil
                        })
                        HStack {
                            Text(Countdown.formatted(seekValue ?? track.elapsed(at: context.date)))
                            Spacer()
                            Text("−" + Countdown.formatted(track.duration - (seekValue ?? track.elapsed(at: context.date))))
                        }
                        .font(.system(size: 11, weight: .medium)).monospacedDigit()
                        .foregroundStyle(BrimletTheme.secondary)
                    }
                }
                HStack(spacing: 22) {
                    playbackButton("backward.fill", label: "Previous Track", size: 17) { module.send(.previous) }
                    Button { module.send(.playPause) } label: {
                        Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(BrimletTheme.ink).frame(width: 40, height: 40)
                            .background(BrimletTheme.mint, in: Circle())
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1).mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(track.isPlaying ? "Pause" : "Play")
                    .help(track.isPlaying ? "Pause" : "Play")
                    playbackButton("forward.fill", label: "Next Track", size: 17) { module.send(.next) }
                    Button { module.toggleLyrics() } label: {
                        Image(systemName: "quote.bubble")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(module.lyricsVisible ? BrimletTheme.mint : Color.white.opacity(0.75))
                            .frame(width: 28, height: 28)
                            .background(module.lyricsVisible ? Color(hex: 0x0D2019) : .clear, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .help(module.lyricsVisible ? "Hide Lyrics" : "Show Lyrics")
                    .accessibilityLabel(module.lyricsVisible ? "Hide Lyrics" : "Show Lyrics")
                }
                .frame(maxWidth: .infinity)
                .disabled(module.commandPending)
                // Keep the content alive while its viewport folds upward on close.
                LyricsPanel(module: module, track: track)
                    .frame(height: module.lyricsVisible ? LyricsPresentation.panelHeight : 0, alignment: .top)
                    .clipped()
                    .allowsHitTesting(module.lyricsVisible)
                    .accessibilityHidden(!module.lyricsVisible)
                    .animation(reduceMotion ? nil : .easeInOut(duration: LyricsPresentation.resizeDuration),
                               value: module.lyricsVisible)
            }
            .padding(.horizontal, 20)
            .onChange(of: track.id) { _, _ in seekValue = nil }
        } else {
            connectionCard
        }
    }

    @ViewBuilder private var connectionCard: some View {
        switch module.connection {
        case .notConnected:
            EmptyCard(symbol: "music.note", title: "A little room for your music.",
                      subtitle: "What’s playing and its controls, right here.", actionTitle: "Connect to Spotify", action: connect)
        case .waiting:
            EmptyCard(symbol: "headphones", title: "Play something, and it shows up here.",
                      subtitle: "Brimlet is ready as soon as Spotify plays.", actionTitle: "Open Spotify") { module.openSpotify() }
        case .connected:
            EmptyCard(symbol: "waveform", title: "Waiting for your next track.",
                      subtitle: "Start playing something in Spotify.", actionTitle: "Open Spotify") { module.openSpotify() }
        case .denied:
            VStack(spacing: 0) {
                EmptyCard(symbol: "lock.open", title: "Brimlet needs your permission.",
                          subtitle: "Allow Spotify under Privacy & Security ›\nAutomation › Brimlet.", actionTitle: "Open Privacy Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("I’ve allowed it, try again") { module.retry() }
                    .font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary).buttonStyle(.plain)
            }
        case .failed(let message):
            EmptyCard(symbol: "arrow.clockwise", title: "Let’s reconnect.", subtitle: "\(message)",
                      actionTitle: "Try Again") { module.retry() }
        }
    }

    private func playbackButton(_ symbol: String, label: LocalizedStringKey, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: size, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.88)).frame(width: 34, height: 34).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(label).help(label)
    }
}

private struct LyricsPanel: View {
    @ObservedObject var module: MusicModule
    let track: SpotifyTrack

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Lyrics")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BrimletTheme.secondary)
                Spacer()
                Text(module.lyrics?.isSynced == true ? "Synced" : "Plain")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BrimletTheme.secondary)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(BrimletTheme.raised, in: RoundedRectangle(cornerRadius: 5))
            }
            if module.lyricsLoading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Looking for lyrics…").font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).frame(height: LyricsPresentation.viewportHeight)
            } else if let lyrics = module.lyrics, !lyrics.lines.isEmpty {
                if module.lyricsVisible && track.isPlaying && lyrics.isSynced {
                    TimelineView(.periodic(from: .now, by: 0.25)) { context in
                        LyricsLines(lyrics: lyrics, position: track.elapsed(at: context.date))
                    }
                } else {
                    LyricsLines(lyrics: lyrics, position: track.position)
                }
            } else {
                Text("No lyrics found for this track.")
                    .font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).frame(height: LyricsPresentation.viewportHeight, alignment: .top)
            }
        }
        .padding(12)
        .frame(height: LyricsPresentation.panelHeight, alignment: .top)
        .background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }
}

enum LyricsPresentation {
    static let viewportHeight: CGFloat = 120
    static let panelHeight: CGFloat = 174
    static let extraHeight: Double = 200
    static let resizeDuration: Double = 0.45
}

struct LyricsLines: View {
    let lyrics: SpotifyLyrics
    let position: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let active = lyrics.activeLine(at: position)
        ScrollViewReader { reader in
            ScrollView {
                // Stable rows let the viewport slide across wrapped sentences instead of replacing them.
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(lyrics.lines) { line in
                        Text(line.text)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(line.id == lyrics.lines[active].id ? Color.white : BrimletTheme.secondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(line.id)
                    }
                    // The last sentence can reach the same reading position as the first.
                    Color.clear.frame(height: LyricsPresentation.viewportHeight - 18)
                        .accessibilityHidden(true)
                }
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: active)
            }
            .scrollIndicators(.hidden)
            .frame(height: LyricsPresentation.viewportHeight)
            .onAppear { reader.scrollTo(lyrics.lines[active].id, anchor: .top) }
            .onChange(of: active) { _, _ in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.55)) {
                    reader.scrollTo(lyrics.lines[active].id, anchor: .top)
                }
            }
            .onChange(of: lyrics.trackID) { _, _ in
                reader.scrollTo(lyrics.lines[active].id, anchor: .top)
            }
        }
    }
}

private struct SeekBar: View {
    var value: Double
    var duration: Double
    var enabled: Bool
    var onChange: (Double) -> Void
    var onCommit: (Double) -> Void
    @State private var hovered = false
    private var fraction: Double { min(1, max(0, value / max(1, duration))) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.13)).frame(height: 3)
                Capsule().fill(BrimletTheme.primary).frame(width: max(0, proxy.size.width * fraction), height: 3)
                Circle().fill(BrimletTheme.primary).frame(width: hovered ? 9 : 6, height: hovered ? 9 : 6)
                    .offset(x: max(0, min(proxy.size.width - 6, proxy.size.width * fraction - 3)))
            }
            .frame(height: 14)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    guard enabled else { return }
                    onChange(min(1, max(0, gesture.location.x / max(1, proxy.size.width))) * duration)
                }
                .onEnded { gesture in
                    guard enabled else { return }
                    onCommit(min(1, max(0, gesture.location.x / max(1, proxy.size.width))) * duration)
                })
            .onHover { hovered = $0 }
        }
        .frame(height: 14)
        .focusable(enabled)
        .onMoveCommand { direction in
            guard enabled else { return }
            if direction == .left { onCommit(max(0, value - 5)) }
            if direction == .right { onCommit(min(duration, value + 5)) }
        }
        .accessibilityElement()
        .accessibilityLabel("Track position")
        .accessibilityValue(Countdown.formatted(value) + " / " + Countdown.formatted(duration))
        .accessibilityAdjustableAction { direction in
            guard enabled else { return }
            switch direction {
            case .increment: onCommit(min(duration, value + 5))
            case .decrement: onCommit(max(0, value - 5))
            @unknown default: break
            }
        }
    }
}

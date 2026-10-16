import AppKit
import SwiftUI
import BrimletCore

struct MusicCard: View {
    @ObservedObject var module: MusicModule
    let connect: () -> Void
    var demo = false
    @State private var seekValue: Double?

    var body: some View {
        if let track = module.track {
            VStack(spacing: 13) {
                HStack(spacing: 14) {
                    AlbumArt(image: module.artwork, size: 64, demo: demo)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(track.title).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                        Text(track.artist).font(.system(size: 12)).foregroundStyle(BrimletTheme.secondary).lineLimit(1)
                        HStack(spacing: 4) {
                            Circle().fill(BrimletTheme.mint).frame(width: 4, height: 4)
                            Text(verbatim: "SPOTIFY").font(.system(size: 8, weight: .semibold)).tracking(1.5)
                        }.foregroundStyle(BrimletTheme.mint.opacity(0.85))
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
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(BrimletTheme.secondary)
                    }
                }
                HStack(spacing: 28) {
                    playbackButton("backward.fill", label: "Previous Track", size: 17) { module.send(.previous) }
                    Button { module.send(.playPause) } label: {
                        Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.black).frame(width: 40, height: 40)
                            .background(Color.white, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(track.isPlaying ? "Pause" : "Play")
                    playbackButton("forward.fill", label: "Next Track", size: 17) { module.send(.next) }
                    Button { module.toggleLyrics() } label: {
                        Image(systemName: "quote.bubble")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(module.lyricsVisible ? BrimletTheme.mint : Color.white.opacity(0.75))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .help(module.lyricsVisible ? "Hide Lyrics" : "Show Lyrics")
                    .accessibilityLabel(module.lyricsVisible ? "Hide Lyrics" : "Show Lyrics")
                }
                .frame(maxWidth: .infinity)
                if module.lyricsVisible {
                    LyricsPanel(module: module, track: track)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)
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
                    .font(.system(size: 10)).foregroundStyle(BrimletTheme.secondary).buttonStyle(.plain)
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
                Label("Lyrics", systemImage: "quote.bubble.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(BrimletTheme.mint)
                Spacer()
                Text(module.lyrics?.isSynced == true ? "SYNCED" : "LYRICS")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(BrimletTheme.secondary)
            }
            if module.lyricsLoading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Looking for lyrics…").font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).frame(height: 72)
            } else if let lyrics = module.lyrics, !lyrics.lines.isEmpty {
                TimelineView(.periodic(from: .now, by: 0.25)) { context in
                    let position = track.elapsed(at: context.date)
                    let active = lyrics.activeLine(at: position)
                    let start = max(0, min(active - 1, max(0, lyrics.lines.count - 4)))
                    let visible = Array(lyrics.lines.dropFirst(start).prefix(4))
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(visible) { line in
                            Text(line.text)
                                .font(.system(size: line.id == lyrics.lines[active].id ? 13 : 11,
                                              weight: line.id == lyrics.lines[active].id ? .semibold : .regular))
                                .foregroundStyle(line.id == lyrics.lines[active].id ? Color.white : BrimletTheme.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 75, alignment: .top)
                }
            } else {
                Text("No lyrics found for this track.")
                    .font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).frame(height: 72, alignment: .top)
            }
        }
        .padding(12)
        .background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 12))
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
                Capsule().fill(BrimletTheme.mint).frame(width: max(0, proxy.size.width * fraction), height: 3)
                Circle().fill(BrimletTheme.mint).frame(width: hovered ? 9 : 6, height: hovered ? 9 : 6)
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

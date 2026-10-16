import AppKit
import Combine
import BrimletCore

@MainActor final class MusicModule: IslandModule {
    enum Connection: Equatable { case notConnected, waiting, connected, denied, failed(String) }
    let id: ModuleID = .music
    @Published var track: SpotifyTrack?
    @Published var artwork: NSImage?
    @Published var connection: Connection = .notConnected
    @Published var commandPending = false
    @Published private(set) var lyrics: SpotifyLyrics?
    @Published private(set) var lyricsLoading = false
    @Published private(set) var lyricsVisible = false
    var onTrackChange: (() -> Void)?
    var onPresentationChange: (() -> Void)?
    private let bridge = SpotifyBridge()
    private let lyricsProvider = LyricsProvider()
    private var polling: Task<Void, Never>?
    private var playbackObserver: NSObjectProtocol?
    private var artworkTask: Task<Void, Never>?
    private var enabled = false
    private var requested = false
    private var reading = false
    private var generation = 0
    private var artworkKey = ""
    private var lyricsTask: Task<Void, Never>?
    private let demo: Bool

    init(demo: Bool = false) { self.demo = demo }

    var activity: Activity {
        Activity(module: id, title: track?.title ?? String(localized: "Your music lives here"),
                 subtitle: track?.artist ?? String(localized: "Connect to Spotify"), isActive: track?.isPlaying == true)
    }

    var spotifyRunning: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.spotify.client" }
    }

    func configure(enabled: Bool, requested: Bool) {
        guard self.enabled != enabled || self.requested != requested else { return }
        self.requested = requested
        setEnabled(enabled)
    }

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        generation += 1
        polling?.cancel()
        polling = nil
        if let playbackObserver { DistributedNotificationCenter.default().removeObserver(playbackObserver) }
        playbackObserver = nil
        guard !demo else { return }
        guard enabled && requested else {
            artworkTask?.cancel()
            artworkKey = ""
            track = nil
            artwork = nil
            lyrics = nil
            lyricsVisible = false
            connection = .notConnected
            return
        }
        connection = .waiting
        // Spotify announces track changes and play/pause itself, so they show without waiting for the next poll.
        playbackObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.spotify.client.PlaybackStateChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
        polling = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.refresh()
                let seconds: UInt64 = self.track?.isPlaying == true ? 2 : 5
                do { try await Task.sleep(nanoseconds: seconds * 1_000_000_000) }
                catch { return }
            }
        }
    }

    func refreshAfterWake() {
        Task { await refresh() }
    }

    func retry() {
        guard enabled && requested else { return }
        connection = .waiting
        Task { await refresh() }
    }

    func refresh() async {
        guard !demo, enabled, requested, !reading, connection != .denied else { return }
        guard spotifyRunning else {
            track = nil
            artwork = nil
            artworkKey = ""
            artworkTask?.cancel()
            connection = .waiting
            return
        }
        reading = true
        let currentGeneration = generation
        let result = await bridge.read()
        reading = false
        guard currentGeneration == generation, enabled, !Task.isCancelled else { return }
        switch result {
        case .success(let value):
            let previousID = track?.id
            track = value
            connection = .connected
            if previousID != value?.id {
                lyricsTask?.cancel()
                lyrics = nil
                lyricsLoading = false
                if lyricsVisible, value != nil { loadLyrics() }
            }
            loadArtwork(value?.artworkURL ?? "")
            if let value, value.isPlaying, previousID != value.id { onTrackChange?() }
        case .failure(let error): handle(error)
        }
    }

    func send(_ command: SpotifyBridge.Command) {
        guard !demo, enabled, !commandPending, spotifyRunning, connection == .connected else { return }
        commandPending = true
        let currentGeneration = generation
        Task {
            let result = await bridge.send(command)
            commandPending = false
            guard currentGeneration == generation else { return }
            if case .failure(let error) = result { handle(error) }
            else { await refresh() }
        }
    }

    func toggleLyrics() {
        lyricsVisible.toggle()
        onPresentationChange?()
        guard lyricsVisible, lyrics?.trackID != track?.id else { return }
        loadLyrics()
    }

    func showLyricsPreview(_ value: SpotifyLyrics) {
        guard demo else { return }
        lyrics = value
        lyricsVisible = true
    }

    private func loadLyrics() {
        guard let track, lyrics?.trackID != track.id, !lyricsLoading else { return }
        lyricsLoading = true
        lyricsTask?.cancel()
        lyricsTask = Task { [weak self] in
            guard let self else { return }
            let result = await self.lyricsProvider.fetch(for: track)
            guard !Task.isCancelled, self.track?.id == track.id else { return }
            self.lyricsLoading = false
            switch result {
            case .success(let lyrics): self.lyrics = lyrics
            case .failure: self.lyrics = nil
            }
        }
    }

    private func handle(_ error: SpotifyFailure) {
        switch error {
        case .permissionDenied: connection = .denied
        case .unavailable: connection = .failed(String(localized: "Couldn’t read the track yet."))
        case .script(let message): connection = .failed(message)
        }
        track = nil
        lyrics = nil
        lyricsLoading = false
        loadArtwork("")
    }

    private func loadArtwork(_ urlString: String) {
        guard artworkKey != urlString else { return }
        artworkKey = urlString
        artwork = nil
        artworkTask?.cancel()
        guard let url = URL(string: urlString), url.scheme == "https" else { return }
        artworkTask = Task { [weak self] in
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 10
                let (data, response) = try await URLSession.shared.data(for: request)
                guard !Task.isCancelled, data.count < 8_000_000,
                      (response as? HTTPURLResponse)?.statusCode == 200,
                      let self, self.artworkKey == urlString else { return }
                self.artwork = NSImage(data: data)
            } catch { /* Artwork is optional; playback remains available. */ }
        }
    }

    func openSpotify() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client") else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}

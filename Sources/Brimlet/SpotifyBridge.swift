import AppKit

struct SpotifyTrack: Equatable, Sendable {
    var id: String
    var title: String
    var artist: String
    var artworkURL: String
    var duration: Double
    var position: Double
    var isPlaying: Bool
    var observedAt: Date

    func elapsed(at now: Date) -> Double {
        min(duration, max(0, position + (isPlaying ? now.timeIntervalSince(observedAt) : 0)))
    }
}

enum SpotifyFailure: Error, LocalizedError, Sendable {
    case permissionDenied, unavailable, script(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return String(localized: "Brimlet needs permission to control Spotify.")
        case .unavailable: return String(localized: "Spotify isn’t available right now.")
        case .script(let message): return message
        }
    }
}

struct LyricsLine: Equatable, Identifiable, Sendable {
    let id: Int
    let timestamp: Double?
    let text: String
}

struct SpotifyLyrics: Equatable, Sendable {
    let trackID: String
    let lines: [LyricsLine]
    let isSynced: Bool

    func activeLine(at position: Double) -> Int {
        guard isSynced else { return 0 }
        return lines.lastIndex(where: { ($0.timestamp ?? 0) <= position }) ?? 0
    }
}

/// Apple Events run serially off the UI thread, with a bounded reply timeout.
final class SpotifyBridge: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.hamzabasaran.brimlet.spotify", qos: .utility)

    func read() async -> Result<SpotifyTrack?, SpotifyFailure> {
        return await withCheckedContinuation { continuation in
            queue.async {
                let source = """
                with timeout of 3 seconds
                    tell application id "com.spotify.client"
                        if player state is stopped then return {"stopped"}
                        set t to current track
                        return {id of t, name of t, artist of t, artwork url of t, duration of t, player position, player state as text}
                    end tell
                end timeout
                """
                switch self.execute(source) {
                case .failure(let error): continuation.resume(returning: .failure(error))
                case .success(let result):
                    if result.numberOfItems == 1 {
                        continuation.resume(returning: .success(nil))
                        return
                    }
                    guard result.numberOfItems == 7 else {
                        continuation.resume(returning: .failure(.unavailable))
                        return
                    }
                    let track = SpotifyTrack(
                        id: result.atIndex(1)?.stringValue ?? "",
                        title: result.atIndex(2)?.stringValue ?? String(localized: "Unknown track"),
                        artist: result.atIndex(3)?.stringValue ?? "Spotify",
                        artworkURL: result.atIndex(4)?.stringValue ?? "",
                        // Spotify's desktop scripting API returns milliseconds for duration.
                        duration: max(0, (result.atIndex(5)?.doubleValue ?? 0) / 1000),
                        position: max(0, result.atIndex(6)?.doubleValue ?? 0),
                        isPlaying: result.atIndex(7)?.stringValue == "playing",
                        observedAt: Date()
                    )
                    continuation.resume(returning: .success(track))
                }
            }
        }
    }

    enum Command: Sendable {
        case playPause, next, previous, seek(Double)
        var script: String {
            switch self {
            case .playPause: return "playpause"
            case .next: return "next track"
            case .previous: return "previous track"
            case .seek(let position): return "set player position to \(max(0, position.isFinite ? position : 0))"
            }
        }
    }

    func send(_ command: Command) async -> Result<Void, SpotifyFailure> {
        return await withCheckedContinuation { continuation in
            queue.async {
                let source = "with timeout of 3 seconds\ntell application id \"com.spotify.client\" to \(command.script)\nend timeout"
                continuation.resume(returning: self.execute(source).map { _ in () })
            }
        }
    }

    private func execute(_ source: String) -> Result<NSAppleEventDescriptor, SpotifyFailure> {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return .failure(.unavailable) }
        let result = script.executeAndReturnError(&error)
        if let error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            if code == -1743 || code == -1744 { return .failure(.permissionDenied) }
            return .failure(.script(String(localized: "Spotify didn’t respond (\(code)).")))
        }
        return .success(result)
    }
}

import Foundation

/// LRCLIB returns optional LRC timestamps and plain lyrics without requiring an account.
final class LyricsProvider: Sendable {
    private struct Response: Decodable {
        let syncedLyrics: String?
        let plainLyrics: String?
    }

    private static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

    func fetch(for track: SpotifyTrack) async -> Result<SpotifyLyrics?, Error> {
        var components = URLComponents(string: "https://lrclib.net/api/get")
        components?.queryItems = [
            URLQueryItem(name: "track_name", value: track.title),
            URLQueryItem(name: "artist_name", value: track.artist),
            URLQueryItem(name: "duration", value: String(Int(track.duration.rounded())))
        ]
        guard let url = components?.url else { return .success(nil) }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 8
            // LRCLIB asks clients to name themselves and link to their source.
            request.setValue("Brimlet/\(Self.version) (https://github.com/mehambas/brimlet)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return .success(nil) }
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            if let synced = decoded.syncedLyrics, !synced.isEmpty {
                return .success(SpotifyLyrics(trackID: track.id, lines: Self.parseLRC(synced), isSynced: true))
            }
            guard let plain = decoded.plainLyrics, !plain.isEmpty else { return .success(nil) }
            let lines = plain.components(separatedBy: .newlines).enumerated().compactMap { index, text -> LyricsLine? in
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : LyricsLine(id: index, timestamp: nil, text: trimmed)
            }
            return .success(SpotifyLyrics(trackID: track.id, lines: lines, isSynced: false))
        } catch {
            return .failure(error)
        }
    }

    private static func parseLRC(_ source: String) -> [LyricsLine] {
        let pattern = try? NSRegularExpression(pattern: #"\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)"#)
        return source.components(separatedBy: .newlines).enumerated().compactMap { index, line in
            guard let pattern,
                  let match = pattern.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  let minuteRange = Range(match.range(at: 1), in: line),
                  let secondRange = Range(match.range(at: 2), in: line),
                  let textRange = Range(match.range(at: 3), in: line),
                  let minutes = Double(line[minuteRange]),
                  let seconds = Double(line[secondRange]) else { return nil }
            let text = String(line[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            return LyricsLine(id: index, timestamp: minutes * 60 + seconds, text: text)
        }
    }
}

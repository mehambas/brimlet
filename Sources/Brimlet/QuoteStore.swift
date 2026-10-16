import Foundation
import Combine

struct SavedQuote: Codable, Identifiable, Equatable {
    var id = UUID()
    var text: String
    var source: String = ""
    var author: String = ""
    var addedAt = Date()
    var lastShownAt: Date?
}

@MainActor final class QuoteStore: ObservableObject {
    @Published private(set) var quotes: [SavedQuote] = [] { didSet { save() } }
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: "savedQuotes"), let values = try? JSONDecoder().decode([SavedQuote].self, from: data) { quotes = values }
    }
    func add(text: String, source: String = "", author: String = "") {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        quotes.insert(SavedQuote(text: cleaned, source: source.trimmingCharacters(in: .whitespacesAndNewlines), author: author.trimmingCharacters(in: .whitespacesAndNewlines)), at: 0)
    }
    func delete(_ quote: SavedQuote) { quotes.removeAll { $0.id == quote.id } }
    func nextQuote() -> SavedQuote? {
        guard !quotes.isEmpty else { return nil }
        let next = quotes.filter { $0.lastShownAt == nil }.randomElement() ?? quotes.min { ($0.lastShownAt ?? .distantPast) < ($1.lastShownAt ?? .distantPast) }
        if let next, let index = quotes.firstIndex(where: { $0.id == next.id }) { quotes[index].lastShownAt = Date(); return quotes[index] }
        return next
    }
    private func save() { if let data = try? JSONEncoder().encode(quotes) { defaults.set(data, forKey: "savedQuotes") } }
}

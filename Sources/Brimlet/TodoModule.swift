import Foundation
import Combine
import UserNotifications
import BrimletCore

enum TodoCategory: String, CaseIterable, Codable, Identifiable {
    case home, personal, work
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return String(localized: "Home")
        case .personal: return String(localized: "Personal")
        case .work: return String(localized: "Work")
        }
    }
    var symbol: String {
        switch self { case .home: return "house"; case .personal: return "person"; case .work: return "briefcase" }
    }
}

struct TodoItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var note: String = ""
    var category: TodoCategory = .home
    var dueDate: Date?
    var reminderEnabled = false
    var completedAt: Date?
    var createdAt = Date()
}

@MainActor final class TodoModule: IslandModule {
    let id: ModuleID = .todos
    @Published private(set) var items: [TodoItem] = []
    @Published var showCompleted = false
    @Published var isEditorPresented = false
    @Published var selectedCategory: TodoCategory?
    @Published private(set) var recentlyCompleted: UUID?
    private let defaults: UserDefaults
    private let storageKey = "todoItems"
    private var undoTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey), let saved = try? JSONDecoder().decode([TodoItem].self, from: data) {
            items = saved
        }
        purgeExpired(at: Date())
        refreshReminders()
    }

    var activeItems: [TodoItem] { filtered(items.filter { $0.completedAt == nil }).sorted(by: sortOrder) }
    var completedItems: [TodoItem] {
        filtered(items.filter { $0.completedAt != nil }).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }
    var activity: Activity {
        let count = activeItems.count
        return Activity(module: id, title: count == 1 ? String(localized: "1 task") : String(localized: "\(count) tasks"),
                        subtitle: String(localized: "Tasks"), isActive: false)
    }

    func add(title: String, note: String, category: TodoCategory, dueDate: Date?, reminder: Bool) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        let item = TodoItem(title: cleanTitle, note: note.trimmingCharacters(in: .whitespacesAndNewlines), category: category,
                            dueDate: dueDate.map { Calendar.current.startOfDay(for: $0) }, reminderEnabled: reminder && dueDate != nil)
        items.append(item)
        persist()
        scheduleReminder(for: item)
    }

    func complete(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id && $0.completedAt == nil }) else { return }
        items[index].completedAt = Date()
        recentlyCompleted = id
        undoTask?.cancel()
        undoTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            guard !Task.isCancelled else { return }
            self?.recentlyCompleted = nil
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        purgeExpired(at: Date())
        persist()
    }

    func undoCompletion() {
        guard let id = recentlyCompleted, let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].completedAt = nil
        recentlyCompleted = nil
        undoTask?.cancel()
        persist()
        scheduleReminder(for: items[index])
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        persist()
    }

    func refreshAfterWake() { purgeExpired(at: Date()); refreshReminders() }
    func setEnabled(_ enabled: Bool) { if enabled { refreshAfterWake() } }

    private func filtered(_ source: [TodoItem]) -> [TodoItem] {
        guard let selectedCategory else { return source }
        return source.filter { $0.category == selectedCategory }
    }

    private func sortOrder(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        switch (lhs.dueDate, rhs.dueDate) {
        case let (a?, b?): return a == b ? lhs.createdAt < rhs.createdAt : a < b
        case (_?, nil): return true
        case (nil, _?): return false
        case (nil, nil): return lhs.createdAt < rhs.createdAt
        }
    }

    private func purgeExpired(at now: Date) {
        let cutoff = now.addingTimeInterval(-30 * 24 * 60 * 60)
        let expired = items.filter { ($0.completedAt ?? .distantFuture) < cutoff }
        for item in expired { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString]) }
        if !expired.isEmpty { items.removeAll { ($0.completedAt ?? .distantFuture) < cutoff }; persist() }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func refreshReminders() {
        let center = UNUserNotificationCenter.current()
        for item in items where item.completedAt != nil || !item.reminderEnabled || item.dueDate == nil {
            center.removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
        }
        for item in items where item.completedAt == nil && item.reminderEnabled { scheduleReminder(for: item) }
    }

    private func scheduleReminder(for item: TodoItem) {
        guard item.completedAt == nil, item.reminderEnabled, let dueDate = item.dueDate else { return }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = 9
        components.minute = 0
        guard let fireDate = Calendar.current.date(from: components), fireDate > Date() else { return }
        let center = UNUserNotificationCenter.current()
        Task { [weak self] in
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted, let self,
                  self.items.contains(where: { $0.id == item.id && $0.completedAt == nil && $0.reminderEnabled }) else { return }
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Due today")
            content.body = item.title
            content.sound = .default
            let request = UNNotificationRequest(identifier: item.id.uuidString, content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
            try? await center.add(request)
        }
    }
}

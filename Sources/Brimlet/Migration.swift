import Foundation

/// Brimlet was called Ada before its first release. Ada's settings and files are copied over once and left in place.
enum Migration {
    static let legacyFolder = "Ada"
    private static let marker = "migratedFromAda"
    /// Spotify Web API tokens and window state stay behind.
    static let keys = ["musicEnabled", "timerEnabled", "calendarEnabled", "todosEnabled", "calendarSelection",
                       "calendarReminderMinutes", "moduleOrder", "pinMusic", "expandOnHover", "trackAlerts", "timerSound",
                       "hideInFullscreen", "displayID", "spotifyRequested", "externalNotificationRequirements", "cmuxEnabled",
                       "cmuxAcknowledgedTurns", "quotesEnabled", "quoteIntervalHours", "quoteIntervalMinutes",
                       "quoteNextDisplayAt", "quoteDisplaySeconds", "savedQuotes", "todoItems", "didWelcome"]

    static func run(defaults: UserDefaults = .standard, legacyDomain: String = "de.hamza.ada", supportDirectory: URL? = nil) {
        guard !defaults.bool(forKey: marker) else { return }
        defaults.set(true, forKey: marker)
        if let legacy = defaults.persistentDomain(forName: legacyDomain) {
            copySettings(from: legacy, to: defaults)
        }
        let support = supportDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        copyFolder(from: support.appendingPathComponent(legacyFolder), to: support.appendingPathComponent("Brimlet"))
    }

    static func copySettings(from legacy: [String: Any], to defaults: UserDefaults) {
        for key in keys where defaults.object(forKey: key) == nil {
            if let value = legacy[key] { defaults.set(value, forKey: key) }
        }
        // Ada showed cmux sessions unless they were turned off; Brimlet only when they are turned on.
        if legacy["cmuxEnabled"] == nil, defaults.object(forKey: "cmuxEnabled") == nil {
            defaults.set(true, forKey: "cmuxEnabled")
        }
    }

    /// Sockets are left out: the notification server creates its own.
    static func copyFolder(from old: URL, to new: URL) {
        let files = FileManager.default
        guard !files.fileExists(atPath: new.path),
              let items = try? files.contentsOfDirectory(at: old, includingPropertiesForKeys: [.fileResourceTypeKey]) else { return }
        let copied = items.filter { (try? $0.resourceValues(forKeys: [.fileResourceTypeKey]).fileResourceType) != .socket }
        guard !copied.isEmpty else { return }
        // The notification server only accepts a folder that no one else can read.
        guard (try? files.createDirectory(at: new, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])) != nil else { return }
        for item in copied { try? files.copyItem(at: item, to: new.appendingPathComponent(item.lastPathComponent)) }
    }
}

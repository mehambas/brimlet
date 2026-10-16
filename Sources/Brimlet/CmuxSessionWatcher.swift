import AppKit
import Combine
import Foundation

struct WaitingCmuxSession: Identifiable, Equatable {
    let id: String
    let agent: String
    let title: String
    let workspaceID: String
    let surfaceID: String
    let directory: String
    let updatedAt: String
    let notificationID: String?
    let status: String

    var turnKey: String { "\(workspaceID)|\(status)" }

    var projectName: String {
        URL(fileURLWithPath: directory).lastPathComponent.isEmpty ? String(localized: "cmux session") : URL(fileURLWithPath: directory).lastPathComponent
    }
}

@MainActor final class CmuxSessionWatcher: ObservableObject {
    @Published private(set) var sessions: [WaitingCmuxSession] = []
    @Published private(set) var isAvailable = false
    var onNewSession: ((WaitingCmuxSession) -> Void)?
    private var timer: Timer?
    private var knownIDs = Set<String>()
    private var isRefreshing = false
    private let acknowledgedKey = "cmuxAcknowledgedTurns"
    private var acknowledgedTurns: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "cmuxAcknowledgedTurns") ?? [])

    static var isInstalled: Bool { executableCandidates.contains { FileManager.default.isExecutableFile(atPath: $0) } }

    private static let executableCandidates = [
        "/Applications/cmux.app/Contents/Resources/bin/cmux",
        "/opt/homebrew/bin/cmux",
        "/usr/local/bin/cmux"
    ]

    func start() {
        guard timer == nil else { return }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        sessions = []
        knownIDs = []
    }

    func refresh() {
        guard !isRefreshing, let executable = Self.executableCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            if Self.executableCandidates.allSatisfy({ !FileManager.default.isExecutableFile(atPath: $0) }) {
                sessions = []
                isAvailable = false
                knownIDs = []
            }
            return
        }
        isRefreshing = true
        let cmuxIsFrontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.cmuxterm.app"
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let found = Self.readWaitingSessions(executable: executable, skipSelected: cmuxIsFrontmost)
            DispatchQueue.main.async {
                guard let self else { return }
                self.isRefreshing = false
                self.isAvailable = found != nil
                guard let found else {
                    self.sessions = []
                    self.knownIDs = []
                    return
                }
                // Keys name a workspace and its status, so forget them once the bridge
                // clears that status; the workspace's next reply must appear again.
                let current = Set(found.map(\.turnKey))
                if !self.acknowledgedTurns.isSubset(of: current) {
                    self.acknowledgedTurns.formIntersection(current)
                    UserDefaults.standard.set(Array(self.acknowledgedTurns), forKey: self.acknowledgedKey)
                }
                let visible = found.filter { !self.acknowledgedTurns.contains($0.turnKey) }
                let newSessions = visible.filter { !self.knownIDs.contains($0.turnKey) }
                self.knownIDs = Set(visible.map(\.turnKey))
                self.sessions = visible
                if let newest = newSessions.first { self.onNewSession?(newest) }
            }
        }
    }

    func open(_ session: WaitingCmuxSession) {
        guard UUID(uuidString: session.workspaceID) != nil,
              UUID(uuidString: session.surfaceID) != nil,
              let executable = Self.executableCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else { return }
        let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.cmuxterm.app")
        let arguments = session.notificationID.map { ["open-notification", "--id", $0] }
            ?? ["focus-panel", "--panel", session.surfaceID, "--workspace", session.workspaceID]
        let didAcknowledge: (Data?) -> Void = { [weak self] result in
            guard result != nil else { return }
            DispatchQueue.main.async { self?.acknowledge(session) }
        }
        if let applicationURL {
            NSWorkspace.shared.openApplication(at: applicationURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
                DispatchQueue.global(qos: .userInitiated).async {
                    didAcknowledge(Self.run(executable, arguments: arguments))
                }
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                didAcknowledge(Self.run(executable, arguments: arguments))
            }
        }
    }

    private func acknowledge(_ session: WaitingCmuxSession) {
        acknowledgedTurns.insert(session.turnKey)
        if acknowledgedTurns.count > 128 {
            acknowledgedTurns = Set(acknowledgedTurns.sorted().suffix(128))
        }
        UserDefaults.standard.set(Array(acknowledgedTurns), forKey: acknowledgedKey)
        sessions.removeAll { $0.turnKey == session.turnKey }
        knownIDs = Set(sessions.map(\.turnKey))
    }

    nonisolated private static func readWaitingSessions(executable: String, skipSelected: Bool) -> [WaitingCmuxSession]? {
        guard let workspaceData = run(executable, arguments: ["workspace", "list", "--json"]),
              let workspaceRoot = try? JSONSerialization.jsonObject(with: workspaceData) as? [String: Any],
              let workspaces = workspaceRoot["workspaces"] as? [[String: Any]],
              let sessionData = run(executable, arguments: ["sessions", "list", "--json"]),
              let sessionRoot = try? JSONSerialization.jsonObject(with: sessionData) as? [String: Any],
              let records = sessionRoot["sessions"] as? [[String: Any]] else { return nil }

        let notificationData = run(executable, arguments: ["--json", "list-notifications"])
        let notifications = notificationData.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [[String: Any]] } ?? []
        return waitingSessions(workspaces: workspaces, records: records, notifications: notifications, skipSelected: skipSelected)
    }

    /// Status comes from cmux-status-bridge, which writes "STATUS|note" into the
    /// workspace description after reading the transcript. cmux's own lifecycle and
    /// completion notifications drift apart when background subagents keep updating
    /// a session after its reply, so matching them here missed finished turns.
    /// The bridge keeps a reply that arrives in the selected workspace Ready until
    /// the user leaves it; while cmux is in front, that one is already being read.
    nonisolated static func waitingSessions(workspaces: [[String: Any]], records: [[String: Any]],
                                            notifications: [[String: Any]], skipSelected: Bool) -> [WaitingCmuxSession] {
        workspaces.compactMap { workspace in
            guard let workspaceID = workspace["id"] as? String, UUID(uuidString: workspaceID) != nil,
                  let description = workspace["description"] as? String,
                  !(skipSelected && workspace["selected"] as? Bool == true) else { return nil }
            let status = description.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
                .first.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
            guard status == "Ready" || status == "Needs input" else { return nil }

            let record = records.filter { record in
                sameID(record["workspace_id"], workspaceID)
                    && record["stored_pid_exists"] as? Bool == true
                    && record["active_for_surface"] as? Bool == true
                    && nonEmptyString(record["session_id"]) != nil
                    && UUID(uuidString: record["surface_id"] as? String ?? "") != nil
            }.max { ($0["updated_at"] as? String ?? "") < ($1["updated_at"] as? String ?? "") }
            guard let record, let sessionID = record["session_id"] as? String,
                  let surfaceID = record["surface_id"] as? String else { return nil }

            let notification = notifications.filter { item in
                sameID(item["workspace_id"], workspaceID) && sameID(item["surface_id"], surfaceID)
                    && item["is_read"] as? Bool != true
                    && UUID(uuidString: item["id"] as? String ?? "") != nil
            }.max { ($0["created_at"] as? String ?? "") < ($1["created_at"] as? String ?? "") }

            let agent = nonEmptyString(record["agent_display_name"]) ?? String(localized: "Coding session")
            let directory = nonEmptyString(record["cwd"]) ?? nonEmptyString(workspace["current_directory"]) ?? ""
            let project = URL(fileURLWithPath: directory).lastPathComponent
            let title = nonEmptyString(notification?["tab_title"]) ?? nonEmptyString(workspace["title"])
                ?? (project.isEmpty ? String(localized: "cmux session") : project)
            return WaitingCmuxSession(id: sessionID, agent: agent, title: title, workspaceID: workspaceID,
                                      surfaceID: surfaceID, directory: directory,
                                      updatedAt: record["updated_at"] as? String ?? "",
                                      notificationID: notification?["id"] as? String, status: status)
        }.sorted { $0.updatedAt > $1.updatedAt }
    }

    nonisolated private static func sameID(_ value: Any?, _ id: String) -> Bool {
        (value as? String)?.caseInsensitiveCompare(id) == .orderedSame
    }

    nonisolated private static func nonEmptyString(_ value: Any?) -> String? {
        guard let value = value as? String, !value.isEmpty else { return nil }
        return value
    }

    nonisolated private static func run(_ executable: String, arguments: [String]) -> Data? {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return nil }

        let resultLock = NSLock()
        var result = Data()
        let reader = DispatchGroup()
        reader.enter()
        DispatchQueue.global(qos: .utility).async {
            defer { reader.leave() }
            while true {
                let chunk = output.fileHandleForReading.readData(ofLength: 16_384)
                if chunk.isEmpty { break }
                resultLock.lock()
                if result.count < 4_000_000 { result.append(chunk.prefix(4_000_000 - result.count)) }
                resultLock.unlock()
            }
        }
        process.waitUntilExit()
        _ = reader.wait(timeout: .now() + 2)
        guard process.terminationStatus == 0 else { return nil }
        resultLock.lock()
        defer { resultLock.unlock() }
        return result
    }
}

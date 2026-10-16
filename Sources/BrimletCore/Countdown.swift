import Foundation

/// A deadline rather than tick counting keeps time correct across system sleep.
public struct Countdown: Equatable, Sendable {
    public enum Phase: Equatable, Sendable { case idle, running, paused, finished }
    public private(set) var phase: Phase = .idle
    public private(set) var duration: TimeInterval = 25 * 60
    public private(set) var deadline: Date?
    private var pausedRemaining: TimeInterval = 0

    public init() {}

    public mutating func start(seconds: TimeInterval, at now: Date) {
        duration = max(1, min(seconds.isFinite ? seconds : 1, 24 * 60 * 60))
        deadline = now.addingTimeInterval(duration)
        pausedRemaining = duration
        phase = .running
    }

    public func remaining(at now: Date) -> TimeInterval {
        switch phase {
        case .idle: return duration
        case .running: return max(0, deadline?.timeIntervalSince(now) ?? 0)
        case .paused: return pausedRemaining
        case .finished: return 0
        }
    }

    public func progress(at now: Date) -> Double {
        min(1, max(0, 1 - remaining(at: now) / duration))
    }

    public mutating func pause(at now: Date) {
        guard phase == .running else { return }
        if tick(at: now) { return }
        pausedRemaining = remaining(at: now)
        deadline = nil
        phase = .paused
    }

    public mutating func resume(at now: Date) {
        guard phase == .paused else { return }
        deadline = now.addingTimeInterval(pausedRemaining)
        phase = .running
    }

    /// Returns true exactly once for each completed countdown.
    @discardableResult public mutating func tick(at now: Date) -> Bool {
        guard phase == .running, remaining(at: now) <= 0 else { return false }
        phase = .finished
        deadline = nil
        return true
    }

    public mutating func reset() {
        phase = .idle
        deadline = nil
        pausedRemaining = 0
    }

    public static func formatted(_ seconds: TimeInterval) -> String {
        let value = Int(ceil(max(0, seconds.isFinite ? seconds : 0)))
        if value >= 3600 { return String(format: "%d:%02d:%02d", value / 3600, value / 60 % 60, value % 60) }
        return String(format: "%02d:%02d", value / 60, value % 60)
    }
}

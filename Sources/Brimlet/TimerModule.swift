import Foundation
import Combine
import BrimletCore

@MainActor final class TimerModule: IslandModule {
    let id: ModuleID = .timer
    @Published private(set) var countdown = Countdown()
    @Published var now = Date()
    @Published var selectedMinutes = 25
    var onFinish: (() -> Void)?
    private var ticker: Timer?
    private var enabled = true

    var activity: Activity {
        Activity(module: id, title: countdown.phase == .finished ? String(localized: "Time’s up") : Countdown.formatted(countdown.remaining(at: now)),
                 subtitle: String(localized: "Timer"), progress: countdown.progress(at: now),
                 isActive: countdown.phase == .running || countdown.phase == .paused)
    }

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        if !enabled { reset() }
    }

    func start(seconds: TimeInterval? = nil) {
        guard enabled else { return }
        now = Date()
        countdown.start(seconds: seconds ?? Double(selectedMinutes * 60), at: now)
        beginTicks()
    }

    func togglePause() {
        now = Date()
        if countdown.phase == .running {
            countdown.pause(at: now)
            ticker?.invalidate()
            ticker = nil
            if countdown.phase == .finished { onFinish?() }
        } else if countdown.phase == .paused {
            countdown.resume(at: now)
            beginTicks()
        }
    }

    func reset() {
        ticker?.invalidate()
        ticker = nil
        countdown.reset()
        now = Date()
    }

    func refreshAfterWake() { tick() }

    private func beginTicks() {
        ticker?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func tick() {
        now = Date()
        if countdown.tick(at: now) {
            ticker?.invalidate()
            ticker = nil
            onFinish?()
        }
    }
}

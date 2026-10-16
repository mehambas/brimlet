import XCTest
@testable import BrimletCore

final class BrimletCoreTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1000)

    func testCountdownFinishesOnceAfterSleep() {
        var timer = Countdown()
        timer.start(seconds: 60, at: now)
        XCTAssertTrue(timer.tick(at: now.addingTimeInterval(3600)))
        XCTAssertFalse(timer.tick(at: now.addingTimeInterval(3601)))
        XCTAssertEqual(timer.phase, .finished)
        XCTAssertEqual(timer.remaining(at: now.addingTimeInterval(3601)), 0)
    }

    func testPauseResumePreservesRemainingTime() {
        var timer = Countdown()
        timer.start(seconds: 60, at: now)
        timer.pause(at: now.addingTimeInterval(20))
        XCTAssertEqual(timer.remaining(at: now.addingTimeInterval(500)), 40)
        timer.resume(at: now.addingTimeInterval(500))
        XCTAssertEqual(timer.remaining(at: now.addingTimeInterval(510)), 30)
        XCTAssertEqual(timer.progress(at: now.addingTimeInterval(510)), 0.5, accuracy: 0.001)
        timer.reset()
        XCTAssertEqual(timer.phase, .idle)
        XCTAssertNil(timer.deadline)
    }

    func testPauseAfterDeadlineFinishesInsteadOfCreatingZeroSecondPause() {
        var timer = Countdown()
        timer.start(seconds: 10, at: now)
        timer.pause(at: now.addingTimeInterval(20))
        XCTAssertEqual(timer.phase, .finished)
    }

    func testInvalidDurationsAreBounded() {
        var timer = Countdown()
        timer.start(seconds: .nan, at: now)
        XCTAssertEqual(timer.duration, 1)
        timer.start(seconds: 1000000, at: now)
        XCTAssertEqual(timer.duration, 86400)
        XCTAssertEqual(Countdown.formatted(59.2), "01:00")
        XCTAssertEqual(Countdown.formatted(3601), "1:00:01")
    }

    func testTemporaryActivityReturnsToPinnedMusic() {
        var router = ActivityRouter()
        router.pinned = .music
        router.showTemporarily(.timer, at: now, duration: 5)
        XCTAssertEqual(router.visible(activities: [], at: now, expanded: false), .timer)
        XCTAssertEqual(router.visible(activities: [], at: now.addingTimeInterval(5), expanded: false), .music)
    }

    func testManualNavigationDoesNotInterruptMusic() {
        var router = ActivityRouter()
        router.selected = .timer
        let music = Activity(module: .music, title: "Track", subtitle: "Artist", isActive: true)
        XCTAssertEqual(router.visible(activities: [music], at: now, expanded: true), .timer)
        XCTAssertEqual(router.visible(activities: [music], at: now, expanded: false), .music)
    }

    func testDisabledModulesCannotTakeOver() {
        var router = ActivityRouter()
        router.enabled = [.timer]
        router.pinned = .music
        router.selected = .music
        router.showTemporarily(.music, at: now, duration: 5)
        XCTAssertEqual(router.visible(activities: [], at: now, expanded: true), .timer)
        router.enabled = []
        XCTAssertNil(router.visible(activities: [], at: now, expanded: false))
    }

    func testOrderMigrationKeepsNewModulesAndRemovesDuplicates() {
        XCTAssertEqual(ActivityRouter.normalizedOrder(["timer", "removed", "timer"]), [.timer, .music, .calendar, .todos])
    }

    func testNotchGeometryLeavesCameraSpaceAndFitsScreen() {
        let geometry = IslandGeometry(notchWidth: 184, topInset: 38, screenWidth: 1512)
        XCTAssertTrue(geometry.hasNotch)
        XCTAssertEqual(geometry.compactWidth, 292)
        XCTAssertEqual(geometry.headerHeight, 38)
        XCTAssertGreaterThanOrEqual(geometry.expandedWidth, geometry.compactWidth)
        let external = IslandGeometry(notchWidth: 0, topInset: 0, screenWidth: 1920)
        XCTAssertFalse(external.hasNotch)
        XCTAssertEqual(external.topMargin, 8)
    }

    func testExternalNotificationRoundTripsAndRejectsUnsafeValues() throws {
        let value = ExternalNotification(sourceBundleID: "com.example.reminders",
                                          title: "Time to stretch", body: "One hour at the desk", duration: 6)
        let decoded = try ExternalNotification.decode(try value.encoded())
        XCTAssertEqual(decoded, value)
        XCTAssertFalse(ExternalNotification(sourceBundleID: "example", title: "", body: "").isValid)
        XCTAssertFalse(ExternalNotification(sourceBundleID: "de.example.app", title: "x", body: "", duration: 31).isValid)
    }
}

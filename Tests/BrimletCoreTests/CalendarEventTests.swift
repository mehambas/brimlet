import XCTest
@testable import BrimletCore

final class CalendarEventTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 100_000)

    func event(_ id: String, start: TimeInterval, end: TimeInterval, allDay: Bool = false) -> CalendarEvent {
        CalendarEvent(id: id, title: id, calendarTitle: "Test", start: now.addingTimeInterval(start),
                      end: now.addingTimeInterval(end), isAllDay: allDay)
    }

    func testOngoingAndTimedEventsPrecedeAllDayEvents() {
        let events = [event("all-day", start: -3600, end: 3600, allDay: true),
                      event("next", start: 60, end: 600), event("ongoing", start: -60, end: 60)]
        XCTAssertEqual(CalendarEvent.upcoming(events, at: now).map(\.id), ["ongoing", "next", "all-day"])
    }

    func testEndedAndBeyondHorizonEventsAreExcludedIncludingAfterSleep() {
        let events = [event("ended", start: -60, end: 0), event("next", start: 60, end: 600),
                      event("tomorrow", start: 86400, end: 87000)]
        XCTAssertEqual(CalendarEvent.upcoming(events, at: now).map(\.id), ["next"])
        XCTAssertEqual(CalendarEvent.upcoming(events, at: now.addingTimeInterval(700)).map(\.id), ["tomorrow"])
    }

    func testCountdownRoundsUpAndHandlesBoundaries() {
        XCTAssertEqual(event("a", start: 1, end: 600).status(at: now), "in 1 min")
        XCTAssertEqual(event("a", start: 3600, end: 7200).status(at: now), "in 1 h")
        XCTAssertEqual(event("a", start: 3601, end: 7200).status(at: now), "in 1 h 1 min")
        XCTAssertEqual(event("a", start: 0, end: 600).status(at: now), "In progress")
        XCTAssertEqual(event("a", start: -600, end: 0).status(at: now), "Ended")
        XCTAssertEqual(event("a", start: -600, end: 600, allDay: true).status(at: now), "All day")
    }

    func testMeetingLinksAreDetectedInNotesAndRegionalHosts() {
        XCTAssertEqual(CalendarEvent.meetingLink(in: ["Office", "Join: https://meet.google.com/abc-defg-hij"])?.host, "meet.google.com")
        XCTAssertEqual(CalendarEvent.meetingLink(in: ["https://us02web.zoom.us/j/123?pwd=abc"])?.query, "pwd=abc")
        XCTAssertEqual(CalendarEvent.meetingLink(in: ["https://teams.microsoft.com/l/meetup-join/123"])?.host, "teams.microsoft.com")
    }

    func testUnrelatedUnsafeAndLookalikeLinksAreNotJoinActions() {
        for link in ["https://example.com", "https://zoom.us.example.com/j/1", "https://evilzoom.us/j/1",
                     "http://zoom.us/j/1", "file:///tmp/example", "https://user:password@zoom.us/j/1"] {
            XCTAssertNil(CalendarEvent.meetingLink(in: [link]), link)
        }
    }

    func testCalendarSelectionAndDisableRespectRouterRules() {
        var router = ActivityRouter()
        router.selected = .calendar
        router.pinned = .music
        XCTAssertEqual(router.visible(activities: [], at: now, expanded: true), .calendar)
        router.enabled.remove(.calendar)
        XCTAssertEqual(router.visible(activities: [], at: now, expanded: true), .music)
    }

    func testAgendaUsesLocalDaysAcrossDaylightSavingTime() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 29, hour: 12))!
        let today = AgendaRange.today.interval(at: date, calendar: calendar)
        XCTAssertEqual(today.duration, 23 * 3600)
        let tomorrow = AgendaRange.tomorrow.interval(at: date, calendar: calendar)
        XCTAssertEqual(today.end, tomorrow.start)
        let week = AgendaRange.week.interval(at: date, calendar: calendar)
        XCTAssertEqual(calendar.dateComponents([.day], from: week.start, to: week.end).day, 7)
    }

    func testAgendaIncludesOvernightEventsButNotBoundaryTouchingEvents() {
        let interval = AgendaRange.tomorrow.interval(at: now)
        let overnight = CalendarEvent(id: "overnight", title: "", calendarTitle: "", start: interval.start.addingTimeInterval(-60), end: interval.start.addingTimeInterval(60))
        let ended = CalendarEvent(id: "ended", title: "", calendarTitle: "", start: interval.start.addingTimeInterval(-60), end: interval.start)
        let later = CalendarEvent(id: "later", title: "", calendarTitle: "", start: interval.end, end: interval.end.addingTimeInterval(60))
        XCTAssertEqual(CalendarEvent.agenda([later, ended, overnight], range: .tomorrow, at: now).map(\.id), ["overnight"])
    }

    func testRemindersOnlyFireOnceWithinLeadWindow() {
        var tracker = CalendarReminderTracker()
        let meeting = event("one", start: 300, end: 600)
        XCTAssertTrue(tracker.due(in: [meeting], at: now.addingTimeInterval(-1), minutes: 5).isEmpty)
        XCTAssertEqual(tracker.due(in: [meeting], at: now, minutes: 5).map(\.id), ["one"])
        XCTAssertTrue(tracker.due(in: [meeting], at: now.addingTimeInterval(15), minutes: 5).isEmpty)
        XCTAssertTrue(tracker.due(in: [meeting], at: now.addingTimeInterval(301), minutes: 5).isEmpty)
    }

    func testRemindersSkipAllDayOngoingDisabledAndExpiredAfterWake() {
        var tracker = CalendarReminderTracker()
        let events = [event("day", start: 60, end: 3600, allDay: true), event("ongoing", start: 0, end: 600), event("future", start: 600, end: 1200)]
        XCTAssertTrue(tracker.due(in: events, at: now, minutes: 0).isEmpty)
        XCTAssertEqual(tracker.due(in: events, at: now, minutes: 10).map(\.id), ["future"])
        var afterWake = CalendarReminderTracker()
        XCTAssertTrue(afterWake.due(in: events, at: now.addingTimeInterval(601), minutes: 10).isEmpty)
    }

    func testSimultaneousAndRecurringOccurrencesRemainDistinct() {
        var tracker = CalendarReminderTracker()
        let events = [event("series:1", start: 120, end: 600), event("other", start: 120, end: 600), event("series:2", start: 86400, end: 87000)]
        XCTAssertEqual(tracker.due(in: events, at: now, minutes: 5).count, 2)
        XCTAssertEqual(tracker.due(in: events, at: now.addingTimeInterval(86100), minutes: 5).map(\.id), ["series:2"])
    }

    func testEventLinkUsesOccurrenceDateUTCAndEscapesIdentifier() {
        let occurrence = Date(timeIntervalSince1970: 0)
        let item = CalendarEvent(id: "instance", title: "", calendarTitle: "", start: now, end: now,
                                 itemIdentifier: "id/with?#", occurrenceDate: occurrence)
        let url = item.calendarURL!
        XCTAssertEqual(url.scheme, "ical")
        XCTAssertEqual(url.host, "ekevent")
        XCTAssertTrue(url.absoluteString.contains("/19700101T000000Z/id%2Fwith%3F%23"))
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.count, 2)
        XCTAssertNil(event("demo", start: 0, end: 10).calendarURL)
    }
}

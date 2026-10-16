import XCTest
@testable import Brimlet

final class CmuxSessionWatcherTests: XCTestCase {
    private let workspaceID = "0B81C722-0000-4000-8000-000000000001"
    private let surfaceID = "CBE4752D-0000-4000-8000-000000000002"
    private let notificationID = "EDE190BA-0000-4000-8000-000000000003"

    private func workspace(_ description: String?, selected: Bool = false) -> [String: Any] {
        var item: [String: Any] = ["id": workspaceID, "title": "Garden planner", "selected": selected,
                                   "current_directory": "/Users/example/Projects/garden"]
        item["description"] = description
        return item
    }

    private func record(live: Bool = true, updatedAt: String = "2026-10-07T11:50:34.000Z") -> [String: Any] {
        ["session_id": "a7495465", "workspace_id": workspaceID.lowercased(), "surface_id": surfaceID,
         "stored_pid_exists": live, "active_for_surface": true, "agent_display_name": "Claude Code",
         "agent_lifecycle": "idle", "cwd": "/Users/example/Projects/garden/app", "updated_at": updatedAt]
    }

    private func waiting(_ workspaces: [[String: Any]], records: [[String: Any]]? = nil,
                         notifications: [[String: Any]] = [], skipSelected: Bool = false) -> [WaitingCmuxSession] {
        CmuxSessionWatcher.waitingSessions(workspaces: workspaces, records: records ?? [record()],
                                           notifications: notifications, skipSelected: skipSelected)
    }

    func testBridgeStatusShowsReplyEvenWhenSessionUpdatedLongAfterNotification() throws {
        let notification: [String: Any] = ["id": notificationID, "workspace_id": workspaceID, "surface_id": surfaceID,
                                           "is_read": false, "created_at": "2026-10-07T11:47:30.460Z",
                                           "tab_title": "Garden planner"]
        let session = try XCTUnwrap(waiting([workspace("Ready|Waiting on review")], notifications: [notification]).first)
        XCTAssertEqual(session.status, "Ready")
        XCTAssertEqual(session.title, "Garden planner")
        XCTAssertEqual(session.agent, "Claude Code")
        XCTAssertEqual(session.surfaceID, surfaceID)
        XCTAssertEqual(session.notificationID, notificationID)
        XCTAssertEqual(session.turnKey, "\(workspaceID)|Ready")
    }

    func testOnlyReadyAndNeedsInputFromLiveSessionsAreWaiting() {
        XCTAssertEqual(waiting([workspace("Needs input")]).first?.status, "Needs input")
        for description in ["Running", "Background", "Idle", "Parked", "Parked 3", "Readyish", "Waiting on review", nil] {
            XCTAssertTrue(waiting([workspace(description)]).isEmpty, description ?? "nil")
        }
        XCTAssertTrue(waiting([workspace("Ready")], records: [record(live: false)]).isEmpty)
    }

    func testReadNotificationIsNotOpenedButReplyStillShows() {
        let read: [String: Any] = ["id": notificationID, "workspace_id": workspaceID, "surface_id": surfaceID,
                                   "is_read": true, "created_at": "2026-10-07T11:47:30.460Z"]
        let session = waiting([workspace("Ready")], notifications: [read]).first
        XCTAssertNotNil(session)
        XCTAssertNil(session?.notificationID)
    }

    func testSelectedWorkspaceIsSkippedOnlyWhileCmuxIsInFront() {
        XCTAssertTrue(waiting([workspace("Ready", selected: true)], skipSelected: true).isEmpty)
        XCTAssertEqual(waiting([workspace("Ready", selected: true)], skipSelected: false).count, 1)
    }

    func testNewestLiveSurfaceIsUsed() {
        var older = record(updatedAt: "2026-10-07T10:00:00.000Z")
        older["surface_id"] = "11111111-0000-4000-8000-000000000000"
        let session = waiting([workspace("Ready")], records: [older, record()]).first
        XCTAssertEqual(session?.surfaceID, surfaceID)
    }
}

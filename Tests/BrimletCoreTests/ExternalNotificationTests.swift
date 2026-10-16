import XCTest
import Security
import Darwin
@testable import BrimletIPC

final class ExternalNotificationTests: XCTestCase {
    func testInvalidWirePayloads() throws {
        let value = ExternalNotification(sourceBundleID: "test.sender", title: "Reminder", body: "Stand up")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: value.encoded()) as? [String: Any])
        json["version"] = 99
        XCTAssertThrowsError(try ExternalNotification.decode(JSONSerialization.data(withJSONObject: json)))
        XCTAssertThrowsError(try ExternalNotification.decode(Data(repeating: 32, count: 8193)))
        XCTAssertFalse(ExternalNotification(sourceBundleID: "test.sender", title: " ", body: "").isValid)
        XCTAssertFalse(ExternalNotification(sourceBundleID: "test.sender", title: "x", body: "", duration: .nan).isValid)
    }

    private func ownRequirement() throws -> String {
        var code: SecCode?
        var staticCode: SecStaticCode?
        var rule: SecRequirement?
        var text: CFString?
        XCTAssertEqual(SecCodeCopySelf([], &code), errSecSuccess)
        XCTAssertEqual(SecCodeCopyStaticCode(try XCTUnwrap(code), [], &staticCode), errSecSuccess)
        XCTAssertEqual(SecCodeCopyDesignatedRequirement(try XCTUnwrap(staticCode), [], &rule), errSecSuccess)
        XCTAssertEqual(SecRequirementCopyString(try XCTUnwrap(rule), [], &text), errSecSuccess)
        return try XCTUnwrap(text) as String
    }

    func testAuthenticatedDeliveryAndBothIdentityFailures() async throws {
        let directory = "/private/tmp/brimlet-ipc-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: false,
                                               attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let path = directory + "/test.sock"
        let rule = try ownRequirement()
        let server = LocalNotificationServer(path: path)
        try server.start(requirements: { ["test.sender": rule] }, receive: { _, _ in .displayed })
        defer { server.stop() }
        let value = ExternalNotification(sourceBundleID: "test.sender", title: "Test", body: "")
        let success = await LocalNotificationChannel.send(value, receiverRequirement: rule, path: path)
        XCTAssertEqual(success, .displayed)
        let wrongServer = await LocalNotificationChannel.send(value, receiverRequirement: "identifier \"no.such.app\"", path: path)
        XCTAssertEqual(wrongServer, .unauthorized)
        let unknown = ExternalNotification(sourceBundleID: "fake.sender", title: "Fake", body: "")
        let wrongSender = await LocalNotificationChannel.send(unknown, receiverRequirement: rule, path: path)
        XCTAssertEqual(wrongSender, .unauthorized)
        let missing = await LocalNotificationChannel.send(value, receiverRequirement: rule, path: directory + "/absent.sock")
        XCTAssertEqual(missing, .unavailable)
    }

    func testDoesNotOverwriteNonSocketOrUnsafeDirectory() throws {
        let directory = "/private/tmp/brimlet-ipc-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: false,
                                               attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let path = directory + "/test.sock"
        try Data("keep".utf8).write(to: URL(fileURLWithPath: path))
        XCTAssertThrowsError(try LocalNotificationServer(path: path).start(requirements: { [:] }, receive: { _, _ in .displayed }))
        XCTAssertEqual(try String(contentsOfFile: path), "keep")
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory)
        XCTAssertThrowsError(try LocalNotificationServer(path: directory + "/other.sock").start(requirements: { [:] }, receive: { _, _ in .displayed }))
    }
}

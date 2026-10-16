import XCTest
import BrimletIPC
@testable import Brimlet

final class MigrationTests: XCTestCase {
    private var defaults: UserDefaults!
    private var folder: URL!

    override func setUpWithError() throws {
        defaults = MemoryDefaults()
        // Socket paths must fit in 104 bytes, which the per-user temporary folder does not leave room for.
        folder = URL(fileURLWithPath: "/private/tmp/brimlet-migration-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: folder)
    }

    func testKnownSettingsMoveAndTokensStayBehind() {
        let legacy: [String: Any] = ["savedQuotes": Data([1, 2, 3]), "moduleOrder": ["timer", "music"], "pinMusic": true,
                                     "spotifyWebAccessToken": "secret", "spotifyWebRefreshToken": "secret",
                                     "NSNavPanelExpandedSizeForOpenMode": "{800, 448}"]
        defaults.set(false, forKey: "pinMusic")
        Migration.copySettings(from: legacy, to: defaults)
        XCTAssertEqual(defaults.data(forKey: "savedQuotes"), Data([1, 2, 3]))
        XCTAssertEqual(defaults.stringArray(forKey: "moduleOrder"), ["timer", "music"])
        XCTAssertFalse(defaults.bool(forKey: "pinMusic"), "A value Brimlet already has wins")
        XCTAssertNil(defaults.object(forKey: "spotifyWebAccessToken"))
        XCTAssertNil(defaults.object(forKey: "spotifyWebRefreshToken"))
        XCTAssertNil(defaults.object(forKey: "NSNavPanelExpandedSizeForOpenMode"))
    }

    func testCmuxStaysAsAdaShowedIt() {
        Migration.copySettings(from: ["musicEnabled": true], to: defaults)
        XCTAssertTrue(defaults.bool(forKey: "cmuxEnabled"), "Ada showed cmux sessions unless they were turned off")
        let other = MemoryDefaults()
        Migration.copySettings(from: ["cmuxEnabled": false], to: other)
        XCTAssertFalse(other.bool(forKey: "cmuxEnabled"))
    }

    func testRunsOnceWithoutAda() {
        Migration.run(defaults: defaults, legacyDomain: "com.example.missing.\(UUID().uuidString)", supportDirectory: folder)
        XCTAssertTrue(defaults.bool(forKey: "migratedFromAda"))
        XCTAssertNil(defaults.object(forKey: "cmuxEnabled"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Brimlet").path))
    }

    func testFolderCopiesFilesButNotTheSocket() throws {
        let old = folder.appendingPathComponent("Ada"), new = folder.appendingPathComponent("Brimlet")
        try FileManager.default.createDirectory(at: old, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let server = LocalNotificationServer(path: old.appendingPathComponent("notification.sock").path)
        try server.start(requirements: { [:] }, receive: { _, _ in .displayed })
        server.stop()
        Migration.copyFolder(from: old, to: new)
        XCTAssertFalse(FileManager.default.fileExists(atPath: new.path), "Only a socket is not worth a folder")

        try Data("{}".utf8).write(to: old.appendingPathComponent("notes.json"))
        Migration.copyFolder(from: old, to: new)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: new.path), ["notes.json"])
        let permissions = try FileManager.default.attributesOfItem(atPath: new.path)[.posixPermissions] as? Int
        XCTAssertEqual(permissions, 0o700)
        XCTAssertTrue(FileManager.default.fileExists(atPath: old.appendingPathComponent("notes.json").path))
    }
}

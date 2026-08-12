import XCTest
@testable import IOSRPGPlayer

final class GameFileRulesTests: XCTestCase {
    func testDetectsMVProject() {
        XCTAssertEqual(
            GameFileRules.detectEngine(paths: [
                "index.html", "js/rpg_core.js", "js/rpg_managers.js", "data/System.json"
            ]),
            .mv
        )
    }

    func testDetectsMZProject() {
        XCTAssertEqual(
            GameFileRules.detectEngine(paths: [
                "index.html", "js/rmmz_core.js", "js/rmmz_managers.js", "data/System.json"
            ]),
            .mz
        )
    }

    func testRejectsIncompleteProject() {
        XCTAssertNil(GameFileRules.detectEngine(paths: ["index.html", "data/System.json"]))
    }

    func testNormalizesSafeResourcePath() throws {
        XCTAssertEqual(try GameFileRules.safeRelativePath("./img/characters/Actor1.png"), "img/characters/Actor1.png")
    }

    func testRejectsPathTraversal() {
        XCTAssertThrowsError(try GameFileRules.safeRelativePath("../secret.txt"))
        XCTAssertThrowsError(try GameFileRules.safeRelativePath("img/../../secret.txt"))
        XCTAssertThrowsError(try GameFileRules.safeRelativePath("C:\\Windows\\win.ini"))
        XCTAssertThrowsError(try GameFileRules.safeRelativePath("/etc/passwd"))
    }

    func testReturnsExpectedMIMETypes() {
        XCTAssertEqual(GameFileRules.mimeType(for: "index.html"), "text/html; charset=utf-8")
        XCTAssertEqual(GameFileRules.mimeType(for: "js/rmmz_core.js"), "text/javascript; charset=utf-8")
        XCTAssertEqual(GameFileRules.mimeType(for: "audio/bgm/theme.ogg"), "audio/ogg")
        XCTAssertEqual(GameFileRules.mimeType(for: "unknown.bin"), "application/octet-stream")
    }

    func testFindsNestedMZGameRoot() throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("wrapper/index.html")
        try fixture.write("wrapper/data/System.json")
        try fixture.write("wrapper/js/rmmz_core.js")
        try fixture.write("wrapper/js/rmmz_managers.js")

        let project = try GameProjectInspector.inspect(folder: fixture.root)

        XCTAssertEqual(project.engine, .mz)
        XCTAssertEqual(project.root.lastPathComponent, "wrapper")
    }

    func testRejectsFolderWithoutSupportedGame() throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("notes/readme.txt")

        XCTAssertThrowsError(try GameProjectInspector.inspect(folder: fixture.root)) { error in
            XCTAssertEqual(error as? GameImportError, .unsupportedProject)
        }
    }
}

private struct TemporaryGameFixture {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func write(_ relativePath: String) throws {
        let url = root.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("fixture".utf8).write(to: url)
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }
}

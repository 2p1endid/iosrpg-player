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
}

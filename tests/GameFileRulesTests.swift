import XCTest
import ZIPFoundation
@testable import IOSRPGPlayer

@MainActor
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

    func testResourceResolverReturnsHTTPStyleSuccessResponse() throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("index.html")

        let resource = try GameResourceResolver.resolve(
            requestURL: URL(string: "rpg-game://fixture/index.html")!,
            gameRoot: fixture.root
        )

        XCTAssertEqual(resource.statusCode, 200)
        XCTAssertEqual(resource.mimeType, "text/html")
        XCTAssertEqual(resource.textEncodingName, "utf-8")
    }

    func testResourceResolverHandlesQueryStringsAndPercentEncodedNames() throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("data/系统.json")

        let resource = try GameResourceResolver.resolve(
            requestURL: URL(string: "rpg-game://fixture/data/%E7%B3%BB%E7%BB%9F.json?v=1")!,
            gameRoot: fixture.root
        )

        XCTAssertEqual(resource.statusCode, 200)
        XCTAssertEqual(resource.mimeType, "application/json")
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

    func testLibraryImportsProjectAndPersistsMetadata() async throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("game/index.html")
        try fixture.write("game/data/System.json")
        try fixture.write("game/js/rpg_core.js")
        try fixture.write("game/js/rpg_managers.js")

        let storage = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: storage) }
        let library = GameLibraryStore(storageRoot: storage)

        let game = try await library.importFolder(fixture.root)
        let reloaded = GameLibraryStore(storageRoot: storage)

        XCTAssertEqual(game.engine, .mv)
        XCTAssertTrue(FileManager.default.fileExists(atPath: game.gameRootURL.path))
        XCTAssertEqual(reloaded.games.count, 1)
        XCTAssertEqual(reloaded.games.first?.id, game.id)
        XCTAssertEqual(reloaded.games.first?.name, game.name)
        XCTAssertEqual(reloaded.games.first?.engine, game.engine)
        XCTAssertEqual(reloaded.games.first?.relativeGameRoot, game.relativeGameRoot)
        XCTAssertEqual(
            reloaded.games.first?.importedAt.timeIntervalSince1970 ?? 0,
            game.importedAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testLibraryDeletesImportedGameFiles() async throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("index.html")
        try fixture.write("data/System.json")
        try fixture.write("js/rmmz_core.js")
        try fixture.write("js/rmmz_managers.js")

        let storage = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: storage) }
        let library = GameLibraryStore(storageRoot: storage)
        let game = try await library.importFolder(fixture.root)

        try library.delete(game)

        XCTAssertTrue(library.games.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: game.containerURL.path))
    }

    func testLibraryImportsNestedMVProjectFromZIP() async throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("archive/Game/index.html")
        try fixture.write("archive/Game/data/System.json")
        try fixture.write("archive/Game/js/rpg_core.js")
        try fixture.write("archive/Game/js/rpg_managers.js")
        let archive = try fixture.makeZIP(from: "archive", named: "mv-game.zip")

        let storage = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: storage) }
        let library = GameLibraryStore(storageRoot: storage)

        let game = try await library.importZIP(archive)

        XCTAssertEqual(game.engine, .mv)
        XCTAssertTrue(FileManager.default.fileExists(atPath: game.gameRootURL.appendingPathComponent("index.html").path))
    }

    func testZIPExtractorRejectsPathTraversalEntry() throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        let archive = try fixture.makeZIPWithTraversalEntry()
        let destination = fixture.root.appendingPathComponent("extract", isDirectory: true)

        XCTAssertThrowsError(try SafeZIPExtractor.extract(archive: archive, to: destination)) { error in
            XCTAssertEqual(error as? GameImportError, .unsafeArchive)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.root.appendingPathComponent("escape.txt").path))
    }

    func testFolderCopierReportsMonotonicProgress() throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("source/a.txt")
        try fixture.write("source/nested/b.txt")
        let destination = fixture.root.appendingPathComponent("copied", isDirectory: true)
        var progressValues: [Double] = []

        try ProgressFileCopier.copyDirectory(
            from: fixture.root.appendingPathComponent("source", isDirectory: true),
            to: destination,
            progress: { progressValues.append($0) }
        )

        XCTAssertEqual(progressValues.last, 1, accuracy: 0.0001)
        XCTAssertEqual(progressValues, progressValues.sorted())
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.appendingPathComponent("nested/b.txt").path))
    }

    func testZIPExtractorReportsCompletionProgress() throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("archive/a.txt")
        try fixture.write("archive/b.txt")
        let archive = try fixture.makeZIP(from: "archive", named: "progress.zip")
        let destination = fixture.root.appendingPathComponent("unzipped", isDirectory: true)
        var progressValues: [Double] = []

        try SafeZIPExtractor.extract(
            archive: archive,
            to: destination,
            progress: { progressValues.append($0) }
        )

        XCTAssertEqual(progressValues.last, 1, accuracy: 0.0001)
        XCTAssertEqual(progressValues, progressValues.sorted())
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

    func makeZIP(from relativeDirectory: String, named name: String) throws -> URL {
        let source = root.appendingPathComponent(relativeDirectory, isDirectory: true)
        let archive = root.appendingPathComponent(name)
        try FileManager.default.zipItem(at: source, to: archive, shouldKeepParent: true)
        return archive
    }

    func makeZIPWithTraversalEntry() throws -> URL {
        let archive = root.appendingPathComponent("unsafe.zip")
        guard let zip = Archive(url: archive, accessMode: .create) else {
            throw GameImportError.invalidArchive
        }
        try zip.addEntry(
            with: "../escape.txt",
            type: .file,
            uncompressedSize: Int64(6),
            compressionMethod: .none,
            provider: { position, size in
            let data = Data("escape".utf8)
            return data.subdata(in: Int(position)..<min(Int(position) + size, data.count))
            }
        )
        return archive
    }
}

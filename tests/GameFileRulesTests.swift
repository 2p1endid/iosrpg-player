import XCTest
import ZIPFoundation
@testable import IOSRPGPlayer

@MainActor
final class GameFileRulesTests: XCTestCase {
    func testRuntimeDiagnosticFormatsCompleteJavaScriptReport() {
        let diagnostic = GameRuntimeDiagnostic(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            severity: .error,
            category: .javascript,
            gameName: "Karryn's Prison",
            gameID: "game-id",
            pageURL: "http://127.0.0.1:1234/games/game-id/index.html",
            message: "TypeError: PluginManager.setup is not a function",
            sourceURL: "http://127.0.0.1:1234/games/game-id/js/main.js",
            line: 5,
            column: 15,
            stack: "main.js:5:15\nbootstrap.js:1:1",
            details: nil
        )

        let report = GameRuntimeDiagnosticFormatter.report(
            diagnostics: [diagnostic],
            engineLabel: "MZ"
        )

        XCTAssertTrue(report.contains("Karryn's Prison"))
        XCTAssertTrue(report.contains("TypeError: PluginManager.setup is not a function"))
        XCTAssertTrue(report.contains("js/main.js:5:15"))
        XCTAssertTrue(report.contains("main.js:5:15\nbootstrap.js:1:1"))
    }

    func testRuntimeDiagnosticDecodesStructuredBridgeMessage() throws {
        let body: [String: Any] = [
            "category": "javascript",
            "severity": "error",
            "message": "boom",
            "pageURL": "http://127.0.0.1/index.html",
            "sourceURL": "http://127.0.0.1/js/main.js",
            "line": 5,
            "column": 2,
            "stack": "stack"
        ]

        let diagnostic = try GameRuntimeDiagnostic.bridgeMessage(
            body,
            gameName: "Game",
            gameID: "id"
        )

        XCTAssertEqual(diagnostic.category, .javascript)
        XCTAssertEqual(diagnostic.message, "boom")
        XCTAssertEqual(diagnostic.line, 5)
        XCTAssertEqual(diagnostic.stack, "stack")
    }

    func testVirtualInputMappingsMatchRPGMakerKeys() {
        XCTAssertEqual(VirtualInputMapping.up.keyCode, 38)
        XCTAssertEqual(VirtualInputMapping.up.rpgAction, "up")
        XCTAssertEqual(VirtualInputMapping.confirm.key, "Enter")
        XCTAssertEqual(VirtualInputMapping.confirm.rpgAction, "ok")
        XCTAssertEqual(VirtualInputMapping.cancel.keyCode, 27)
        XCTAssertEqual(VirtualInputMapping.cancel.rpgAction, "escape")
    }

    func testVirtualInputScriptUpdatesDOMAndRPGMakerState() {
        let script = VirtualInputScriptBuilder.script(for: .up, pressed: true)

        XCTAssertTrue(script.contains("Input._currentState"))
        XCTAssertTrue(script.contains("'up'"))
        XCTAssertTrue(script.contains("keyCode"))
        XCTAssertTrue(script.contains("which"))
        XCTAssertTrue(script.contains("window.dispatchEvent"))
        XCTAssertTrue(script.contains("document.dispatchEvent"))
    }

    func testReleaseAllVirtualInputsClearsEveryRPGMakerAction() {
        let script = VirtualInputScriptBuilder.releaseAllScript()

        for action in ["up", "down", "left", "right", "ok", "escape"] {
            XCTAssertTrue(script.contains("'\(action)'"))
        }
    }

    func testImportPickerSelectionKeepsSourceUntilCompletion() {
        var state = GameImportPickerState()
        state.present(.zip)

        state.presentationChanged(isPresented: false)

        XCTAssertEqual(state.source, .zip)
        XCTAssertFalse(state.isPresented)
        XCTAssertEqual(state.consumeSource(), .zip)
        XCTAssertNil(state.source)
    }

    func testImportPickerCancellationClearsSource() {
        var state = GameImportPickerState()
        state.present(.folder)

        state.cancel()

        XCTAssertNil(state.source)
        XCTAssertFalse(state.isPresented)
    }

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

    func testResourceResolverMapsGameRootRequestToIndexHTML() throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("index.html")

        let resource = try GameResourceResolver.resolve(
            requestURL: URL(string: "rpg-game://fixture/")!,
            gameRoot: fixture.root
        )

        XCTAssertEqual(resource.statusCode, 200)
        XCTAssertEqual(resource.mimeType, "text/html")
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

    func testResourceResolverMatchesCaseInsensitiveGamePaths() throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("data/System.json")

        let resource = try GameResourceResolver.resolve(
            requestURL: URL(string: "rpg-game://fixture/data/system.json")!,
            gameRoot: fixture.root
        )

        XCTAssertEqual(resource.mimeType, "application/json")
    }

    func testResourceResolverReportsMissingRelativePath() throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }

        XCTAssertThrowsError(try GameResourceResolver.resolve(
            requestURL: URL(string: "rpg-game://fixture/js/plugins.js")!,
            gameRoot: fixture.root
        )) { error in
            XCTAssertEqual(error as? GameFileError, .missingResource("js/plugins.js"))
        }
    }

    func testLocalHTTPRouteMapsRootToIndexHTML() throws {
        let route = try LocalGameHTTPRoute.parse(path: "/", expectedGameID: "fixture")

        XCTAssertEqual(route.relativePath, "index.html")
    }

    func testLocalHTTPRouteAcceptsGamePrefixedPath() throws {
        let route = try LocalGameHTTPRoute.parse(
            path: "/games/fixture/data/System.json",
            expectedGameID: "fixture"
        )

        XCTAssertEqual(route.relativePath, "data/System.json")
    }

    func testLocalHTTPRouteRejectsWrongGameAndTraversal() {
        XCTAssertThrowsError(try LocalGameHTTPRoute.parse(
            path: "/games/other/index.html",
            expectedGameID: "fixture"
        ))
        XCTAssertThrowsError(try LocalGameHTTPRoute.parse(
            path: "/games/fixture/../../secret.txt",
            expectedGameID: "fixture"
        ))
    }

    func testLocalHTTPServerServesIndexFromLoopback() async throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("index.html")
        let server = LocalGameHTTPServer(
            gameRoot: fixture.root,
            gameID: "fixture",
            preferredPort: nil
        )
        defer { server.stop() }

        let baseURL = try await server.start()
        let (data, response) = try await URLSession.shared.data(
            from: baseURL.appendingPathComponent("index.html")
        )

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(baseURL.host, "127.0.0.1")
    }

    func testHTTPNavigationDiagnosticTreatsMainDocument404AsLoadFailure() {
        let diagnostic = GameHTTPNavigationDiagnostic.evaluate(
            statusCode: 404,
            path: "/games/fixture/index.html"
        )

        XCTAssertEqual(diagnostic?.status, "加载失败")
        XCTAssertEqual(
            diagnostic?.message,
            "资源加载失败：HTTP 404 /games/fixture/index.html"
        )
    }

    func testHTTPNavigationDiagnosticAllowsSuccessfulResponse() {
        XCTAssertNil(GameHTTPNavigationDiagnostic.evaluate(statusCode: 200, path: "/index.html"))
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

    func testImportedGameRepairsStaleRootMetadataByFindingNestedWWW() throws {
        let fixture = try TemporaryGameFixture()
        defer { fixture.remove() }
        try fixture.write("Games/11111111-1111-1111-1111-111111111111/Game/www/index.html")
        try fixture.write("Games/11111111-1111-1111-1111-111111111111/Game/www/data/System.json")
        try fixture.write("Games/11111111-1111-1111-1111-111111111111/Game/www/js/rpg_core.js")
        try fixture.write("Games/11111111-1111-1111-1111-111111111111/Game/www/js/rpg_managers.js")
        let game = ImportedGame(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "www",
            engine: .mv,
            importedAt: Date(),
            relativeGameRoot: "Game",
            storageRoot: fixture.root
        )

        let repairedRoot = try game.resolvedGameRootURL()

        XCTAssertEqual(repairedRoot.lastPathComponent.lowercased(), "www")
        XCTAssertTrue(FileManager.default.fileExists(atPath: repairedRoot.appendingPathComponent("index.html").path))
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

        XCTAssertEqual(progressValues.last ?? 0, 1, accuracy: 0.0001)
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

        XCTAssertEqual(progressValues.last ?? 0, 1, accuracy: 0.0001)
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

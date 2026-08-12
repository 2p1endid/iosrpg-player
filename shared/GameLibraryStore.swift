import Foundation

struct ImportedGame: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    var name: String
    let engine: RPGMakerWebEngine
    let importedAt: Date
    let relativeGameRoot: String

    var engineLabel: String { engine.rawValue.uppercased() }

    private var storageRoot: URL?

    enum CodingKeys: String, CodingKey {
        case id, name, engine, importedAt, relativeGameRoot
    }

    init(
        id: UUID,
        name: String,
        engine: RPGMakerWebEngine,
        importedAt: Date,
        relativeGameRoot: String,
        storageRoot: URL?
    ) {
        self.id = id
        self.name = name
        self.engine = engine
        self.importedAt = importedAt
        self.relativeGameRoot = relativeGameRoot
        self.storageRoot = storageRoot
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        engine = try container.decode(RPGMakerWebEngine.self, forKey: .engine)
        importedAt = try container.decode(Date.self, forKey: .importedAt)
        relativeGameRoot = try container.decode(String.self, forKey: .relativeGameRoot)
        storageRoot = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(engine, forKey: .engine)
        try container.encode(importedAt, forKey: .importedAt)
        try container.encode(relativeGameRoot, forKey: .relativeGameRoot)
    }

    var containerURL: URL {
        guard let storageRoot else { return URL(fileURLWithPath: "/missing") }
        return storageRoot.appendingPathComponent("Games/\(id.uuidString)", isDirectory: true)
    }

    var gameRootURL: URL {
        containerURL.appendingPathComponent(relativeGameRoot, isDirectory: true)
    }

    func attached(to storageRoot: URL) -> ImportedGame {
        var copy = self
        copy.storageRoot = storageRoot
        return copy
    }

    static func == (lhs: ImportedGame, rhs: ImportedGame) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.engine == rhs.engine &&
        lhs.importedAt == rhs.importedAt &&
        lhs.relativeGameRoot == rhs.relativeGameRoot
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension RPGMakerWebEngine: Codable {}

@MainActor
final class GameLibraryStore: ObservableObject {
    @Published private(set) var games: [ImportedGame] = []
    @Published var operationMessage: String?

    let storageRoot: URL
    private let fileManager: FileManager
    private var metadataURL: URL { storageRoot.appendingPathComponent("library.json") }
    private var gamesRoot: URL { storageRoot.appendingPathComponent("Games", isDirectory: true) }

    init(storageRoot: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let storageRoot {
            self.storageRoot = storageRoot.standardizedFileURL
        } else {
            let support = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.storageRoot = support
        }
        try? fileManager.createDirectory(at: self.storageRoot, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: gamesRoot, withIntermediateDirectories: true)
        load()
    }

    func importFolder(_ selectedFolder: URL) async throws -> ImportedGame {
        let hasSecurityScope = selectedFolder.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope { selectedFolder.stopAccessingSecurityScopedResource() }
        }

        return try await copyImportedProject(GameProjectInspector.inspect(folder: selectedFolder))
    }

    func importZIP(_ selectedArchive: URL) async throws -> ImportedGame {
        let hasSecurityScope = selectedArchive.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope { selectedArchive.stopAccessingSecurityScopedResource() }
        }

        let workspace = fileManager.temporaryDirectory
            .appendingPathComponent("IOSRPGImport-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: workspace) }
        try SafeZIPExtractor.extract(archive: selectedArchive, to: workspace)
        let inspected = try GameProjectInspector.inspect(folder: workspace)
        return try await copyImportedProject(
            inspected,
            preferredName: selectedArchive.deletingPathExtension().lastPathComponent
        )
    }

    func delete(_ game: ImportedGame) throws {
        if fileManager.fileExists(atPath: game.containerURL.path) {
            try fileManager.removeItem(at: game.containerURL)
        }
        games.removeAll { $0.id == game.id }
        try persist()
        operationMessage = "已删除 \(game.name)"
    }

    func rename(_ game: ImportedGame, to newName: String) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = games.firstIndex(where: { $0.id == game.id }) else { return }
        games[index].name = trimmed
        try persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: metadataURL),
              let decoded = try? JSONDecoder.libraryDecoder.decode([ImportedGame].self, from: data) else {
            games = []
            return
        }
        games = decoded
            .map { $0.attached(to: storageRoot) }
            .filter { fileManager.fileExists(atPath: $0.gameRootURL.path) }
            .sorted { $0.importedAt > $1.importedAt }
    }

    private func copyImportedProject(
        _ inspected: InspectedGameProject,
        preferredName: String? = nil
    ) async throws -> ImportedGame {
        let id = UUID()
        let container = gamesRoot.appendingPathComponent(id.uuidString, isDirectory: true)
        let destination = container.appendingPathComponent("Game", isDirectory: true)
        do {
            try fileManager.createDirectory(at: container, withIntermediateDirectories: true)
            try fileManager.copyItem(at: inspected.root, to: destination)
        } catch {
            try? fileManager.removeItem(at: container)
            throw GameImportError.copyFailed
        }

        let detectedName = inspected.root.deletingPathExtension().lastPathComponent
        let requestedName = preferredName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = requestedName?.isEmpty == false ? requestedName! : detectedName
        let game = ImportedGame(
            id: id,
            name: displayName.isEmpty ? "Imported Game" : displayName,
            engine: inspected.engine,
            importedAt: Date(),
            relativeGameRoot: "Game",
            storageRoot: storageRoot
        )
        games.append(game)
        games.sort { $0.importedAt > $1.importedAt }
        try persist()
        operationMessage = "已导入 \(game.name)（\(game.engineLabel)）"
        return game
    }

    private func persist() throws {
        let data = try JSONEncoder.libraryEncoder.encode(games)
        try data.write(to: metadataURL, options: .atomic)
    }
}

private extension JSONEncoder {
    static var libraryEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }
}

private extension JSONDecoder {
    static var libraryDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}

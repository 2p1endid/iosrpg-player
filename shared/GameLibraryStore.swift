import Foundation

struct ImportedGame: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    var name: String
    let engine: RPGMakerWebEngine
    let importedAt: Date
    let relativeGameRoot: String

    var engineLabel: String { engine.rawValue.uppercased() }
    private var storageRoot: URL?

    enum CodingKeys: String, CodingKey { case id, name, engine, importedAt, relativeGameRoot }

    init(id: UUID, name: String, engine: RPGMakerWebEngine, importedAt: Date, relativeGameRoot: String, storageRoot: URL?) {
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

    var gameRootURL: URL { containerURL.appendingPathComponent(relativeGameRoot, isDirectory: true) }

    func resolvedGameRootURL() throws -> URL {
        if GameProjectInspector.engine(at: gameRootURL) != nil {
            return gameRootURL
        }
        return try GameProjectInspector.inspect(folder: containerURL).root
    }

    func attached(to storageRoot: URL) -> ImportedGame {
        var copy = self
        copy.storageRoot = storageRoot
        return copy
    }

    static func == (lhs: ImportedGame, rhs: ImportedGame) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.engine == rhs.engine &&
        lhs.importedAt == rhs.importedAt && lhs.relativeGameRoot == rhs.relativeGameRoot
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension RPGMakerWebEngine: Codable {}

struct GameImportProgress: Equatable {
    enum Phase: String {
        case preparing = "准备导入"
        case extracting = "正在解压"
        case scanning = "正在识别游戏"
        case copying = "正在复制游戏"
        case saving = "正在保存游戏库"
    }

    let phase: Phase
    let fraction: Double
    var percentage: Int { Int((min(max(fraction, 0), 1) * 100).rounded()) }
}

@MainActor
final class GameLibraryStore: ObservableObject {
    @Published private(set) var games: [ImportedGame] = []
    @Published var operationMessage: String?
    @Published private(set) var importProgress: GameImportProgress?

    let storageRoot: URL
    private let fileManager: FileManager
    private var metadataURL: URL { storageRoot.appendingPathComponent("library.json") }
    private var gamesRoot: URL { storageRoot.appendingPathComponent("Games", isDirectory: true) }

    init(storageRoot: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let storageRoot {
            self.storageRoot = storageRoot.standardizedFileURL
        } else {
            self.storageRoot = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
        }
        try? fileManager.createDirectory(at: self.storageRoot, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: gamesRoot, withIntermediateDirectories: true)
        load()
    }

    func importFolder(_ selectedFolder: URL) async throws -> ImportedGame {
        guard importProgress == nil else { throw GameImportError.importInProgress }
        importProgress = GameImportProgress(phase: .preparing, fraction: 0)
        operationMessage = nil
        let scoped = selectedFolder.startAccessingSecurityScopedResource()
        defer {
            if scoped { selectedFolder.stopAccessingSecurityScopedResource() }
            importProgress = nil
        }
        importProgress = GameImportProgress(phase: .scanning, fraction: 0.05)
        let inspected = try await Task.detached(priority: .userInitiated) {
            try GameProjectInspector.inspect(folder: selectedFolder)
        }.value
        return try await copyImportedProject(inspected, preferredName: nil)
    }

    func importZIP(_ selectedArchive: URL) async throws -> ImportedGame {
        guard importProgress == nil else { throw GameImportError.importInProgress }
        importProgress = GameImportProgress(phase: .preparing, fraction: 0)
        operationMessage = nil
        let scoped = selectedArchive.startAccessingSecurityScopedResource()
        defer {
            if scoped { selectedArchive.stopAccessingSecurityScopedResource() }
            importProgress = nil
        }
        let workspace = fileManager.temporaryDirectory
            .appendingPathComponent("IOSRPGImport-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: workspace) }

        importProgress = GameImportProgress(phase: .extracting, fraction: 0)
        try await Task.detached(priority: .userInitiated) {
            try SafeZIPExtractor.extract(archive: selectedArchive, to: workspace) { value in
                Task { @MainActor [weak self] in
                    self?.importProgress = GameImportProgress(phase: .extracting, fraction: value * 0.65)
                }
            }
        }.value
        importProgress = GameImportProgress(phase: .scanning, fraction: 0.67)
        let inspected = try await Task.detached(priority: .userInitiated) {
            try GameProjectInspector.inspect(folder: workspace)
        }.value
        return try await copyImportedProject(
            inspected,
            preferredName: selectedArchive.deletingPathExtension().lastPathComponent
        )
    }

    func delete(_ game: ImportedGame) throws {
        if fileManager.fileExists(atPath: game.containerURL.path) { try fileManager.removeItem(at: game.containerURL) }
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
        games = decoded.map { $0.attached(to: storageRoot) }
            .filter { fileManager.fileExists(atPath: $0.gameRootURL.path) }
            .sorted { $0.importedAt > $1.importedAt }
    }

    private func copyImportedProject(_ inspected: InspectedGameProject, preferredName: String?) async throws -> ImportedGame {
        let id = UUID()
        let container = gamesRoot.appendingPathComponent(id.uuidString, isDirectory: true)
        let destination = container.appendingPathComponent("Game", isDirectory: true)
        importProgress = GameImportProgress(phase: .copying, fraction: 0.7)
        do {
            try await Task.detached(priority: .userInitiated) {
                try ProgressFileCopier.copyDirectory(from: inspected.root, to: destination) { value in
                    Task { @MainActor [weak self] in
                        self?.importProgress = GameImportProgress(phase: .copying, fraction: 0.7 + value * 0.25)
                    }
                }
            }.value
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
        importProgress = GameImportProgress(phase: .saving, fraction: 0.97)
        games.append(game)
        games.sort { $0.importedAt > $1.importedAt }
        try persist()
        importProgress = GameImportProgress(phase: .saving, fraction: 1)
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

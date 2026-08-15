import Foundation

struct GameSaveSnapshot: Codable, Equatable {
    var localStorage: [String: String]
    var capturedAt: Date
}

struct GameSaveBackup: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let createdAt: Date
    let snapshot: GameSaveSnapshot
}

struct GameSaveVault {
    let baseURL: URL
    private let fileManager: FileManager

    init(baseURL: URL? = nil, fileManager: FileManager = .default) {
        self.baseURL = baseURL ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RRPPGo/SaveVaults", isDirectory: true)
        self.fileManager = fileManager
    }

    func loadCurrent(gameID: String) throws -> GameSaveSnapshot? {
        let url = gameFolder(gameID: gameID).appendingPathComponent("current.json")
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try decoded(GameSaveSnapshot.self, from: Data(contentsOf: url))
    }

    func saveCurrent(_ snapshot: GameSaveSnapshot, gameID: String) throws {
        let folder = gameFolder(gameID: gameID)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        try encoded(snapshot).write(to: folder.appendingPathComponent("current.json"), options: .atomic)
    }

    func createBackup(gameID: String, name: String) throws -> GameSaveBackup {
        guard let snapshot = try loadCurrent(gameID: gameID) else { throw GameSaveVaultError.noCurrentSave }
        let backup = GameSaveBackup(id: UUID(), name: normalizedName(name), createdAt: Date(), snapshot: snapshot)
        let folder = backupFolder(gameID: gameID)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        try encoded(backup).write(to: folder.appendingPathComponent("\(backup.id.uuidString).json"), options: .atomic)
        return backup
    }

    func listBackups(gameID: String) throws -> [GameSaveBackup] {
        let folder = backupFolder(gameID: gameID)
        guard fileManager.fileExists(atPath: folder.path) else { return [] }
        return try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "json" }
            .compactMap { try? decoded(GameSaveBackup.self, from: Data(contentsOf: $0)) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func restoreBackup(_ backupID: UUID, gameID: String) throws {
        guard let backup = try listBackups(gameID: gameID).first(where: { $0.id == backupID }) else {
            throw GameSaveVaultError.backupNotFound
        }
        try saveCurrent(backup.snapshot, gameID: gameID)
    }

    func deleteBackup(_ backupID: UUID, gameID: String) throws {
        let url = backupFolder(gameID: gameID).appendingPathComponent("\(backupID.uuidString).json")
        guard fileManager.fileExists(atPath: url.path) else { throw GameSaveVaultError.backupNotFound }
        try fileManager.removeItem(at: url)
    }

    private func gameFolder(gameID: String) -> URL {
        baseURL.appendingPathComponent(safeID(gameID), isDirectory: true)
    }

    private func backupFolder(gameID: String) -> URL {
        gameFolder(gameID: gameID).appendingPathComponent("Backups", isDirectory: true)
    }

    private func safeID(_ gameID: String) -> String {
        gameID.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "_", options: .regularExpression)
    }

    private func encoded<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }

    private func decoded<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }

    private func normalizedName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return String((trimmed.isEmpty ? "Backup" : trimmed).prefix(80))
    }
}

enum GameSaveVaultError: LocalizedError {
    case noCurrentSave
    case backupNotFound

    var errorDescription: String? {
        switch self {
        case .noCurrentSave: "No current save snapshot is available."
        case .backupNotFound: "The selected save backup could not be found."
        }
    }
}

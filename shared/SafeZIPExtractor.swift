import Foundation
import ZIPFoundation

enum SafeZIPExtractor {
    static let maximumEntryCount = 100_000
    static let maximumUncompressedSize: Int64 = 8 * 1_024 * 1_024 * 1_024

    static func extract(archive archiveURL: URL, to destination: URL) throws {
        guard let archive = Archive(url: archiveURL, accessMode: .read) else {
            throw GameImportError.invalidArchive
        }
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let root = destination.standardizedFileURL
        var entryCount = 0
        var totalSize: Int64 = 0

        for entry in archive {
            entryCount += 1
            totalSize += Int64(entry.uncompressedSize)
            guard entryCount <= maximumEntryCount, totalSize <= maximumUncompressedSize else {
                throw GameImportError.archiveTooLarge
            }
            let safePath: String
            do {
                safePath = try GameFileRules.safeRelativePath(entry.path)
            } catch {
                throw GameImportError.unsafeArchive
            }
            let output = root.appendingPathComponent(safePath).standardizedFileURL
            let rootPrefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
            guard output.path.hasPrefix(rootPrefix) else {
                throw GameImportError.unsafeArchive
            }
            guard entry.type != .symlink else {
                throw GameImportError.unsafeArchive
            }
            do {
                _ = try archive.extract(entry, to: output, skipCRC32: false)
            } catch let error as GameImportError {
                throw error
            } catch {
                throw GameImportError.invalidArchive
            }
        }
    }
}

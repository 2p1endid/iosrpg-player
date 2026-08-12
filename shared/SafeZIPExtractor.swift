import Foundation
import ZIPFoundation

enum SafeZIPExtractor {
    static let maximumEntryCount = 100_000
    static let maximumUncompressedSize: Int64 = 8 * 1_024 * 1_024 * 1_024

    static func extract(
        archive archiveURL: URL,
        to destination: URL,
        progress: @escaping (Double) -> Void = { _ in }
    ) throws {
        guard let archive = Archive(url: archiveURL, accessMode: .read) else {
            throw GameImportError.invalidArchive
        }
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let root = destination.standardizedFileURL
        var entryCount = 0
        var totalSize: Int64 = 0
        let entries = Array(archive)
        let expectedSize = max(entries.reduce(Int64(0)) { $0 + Int64($1.uncompressedSize) }, 1)
        var extractedSize: Int64 = 0
        progress(0)

        for entry in entries {
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
                extractedSize += Int64(entry.uncompressedSize)
                progress(min(Double(extractedSize) / Double(expectedSize), 1))
            } catch let error as GameImportError {
                throw error
            } catch {
                throw GameImportError.invalidArchive
            }
        }
        progress(1)
    }
}

import Foundation

enum ProgressFileCopier {
    static func copyDirectory(
        from source: URL,
        to destination: URL,
        progress: @escaping (Double) -> Void = { _ in }
    ) throws {
        let fileManager = FileManager.default
        let sourceRoot = source.standardizedFileURL
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]
        guard let enumerator = fileManager.enumerator(
            at: sourceRoot,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            throw GameImportError.inaccessibleFolder
        }

        var entries: [(source: URL, relative: String, isDirectory: Bool, size: Int64)] = []
        var totalBytes: Int64 = 0
        for case let item as URL in enumerator {
            let values = try item.resourceValues(forKeys: Set(keys))
            guard values.isSymbolicLink != true else { throw GameImportError.copyFailed }
            let relative = String(item.path.dropFirst(sourceRoot.path.count))
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !relative.isEmpty else { continue }
            let isDirectory = values.isDirectory == true
            let size = isDirectory ? 0 : Int64(values.fileSize ?? 0)
            entries.append((item, relative, isDirectory, size))
            totalBytes += size
        }

        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        progress(0)
        var completedBytes: Int64 = 0
        let fallbackTotal = max(entries.filter { !$0.isDirectory }.count, 1)
        var completedFiles = 0
        for entry in entries {
            let target = destination.appendingPathComponent(entry.relative, isDirectory: entry.isDirectory)
            if entry.isDirectory {
                try fileManager.createDirectory(at: target, withIntermediateDirectories: true)
            } else {
                try fileManager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fileManager.copyItem(at: entry.source, to: target)
                completedBytes += entry.size
                completedFiles += 1
                let value = totalBytes > 0
                    ? Double(completedBytes) / Double(totalBytes)
                    : Double(completedFiles) / Double(fallbackTotal)
                progress(min(max(value, 0), 1))
            }
        }
        progress(1)
    }
}

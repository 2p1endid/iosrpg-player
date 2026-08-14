import Foundation

struct InspectedGameProject: Equatable {
    let root: URL
    let engine: RPGMakerWebEngine
}

enum GameImportError: LocalizedError, Equatable {
    case unsupportedProject
    case inaccessibleFolder
    case copyFailed
    case invalidArchive
    case unsafeArchive
    case archiveTooLarge
    case importInProgress

    var errorDescription: String? {
        description(language: AppLanguage.current)
    }

    func description(language: AppLanguage) -> String {
        switch self {
        case .unsupportedProject: language.text(.unsupportedProject)
        case .inaccessibleFolder: language.text(.inaccessibleFolder)
        case .copyFailed: language.text(.copyFailed)
        case .invalidArchive: language.text(.invalidArchive)
        case .unsafeArchive: language.text(.unsafeArchive)
        case .archiveTooLarge: language.text(.archiveTooLarge)
        case .importInProgress: language.text(.importInProgress)
        }
    }
}

enum GameProjectInspector {
    static func inspect(folder: URL, maximumDepth: Int = 4) throws -> InspectedGameProject {
        let root = folder.standardizedFileURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw GameImportError.inaccessibleFolder
        }

        var queue: [(url: URL, depth: Int)] = [(root, 0)]
        while !queue.isEmpty {
            let item = queue.removeFirst()
            if let engine = engine(at: item.url) {
                return InspectedGameProject(root: item.url, engine: engine)
            }
            guard item.depth < maximumDepth else { continue }
            let children = try FileManager.default.contentsOfDirectory(
                at: item.url,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
            )
            for child in children.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let values = try child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                if values.isDirectory == true, values.isSymbolicLink != true {
                    queue.append((child.standardizedFileURL, item.depth + 1))
                }
            }
        }
        throw GameImportError.unsupportedProject
    }

    static func engine(at folder: URL) -> RPGMakerWebEngine? {
        let requiredPaths = [
            "index.html",
            "data/System.json",
            "js/rpg_core.js",
            "js/rpg_managers.js",
            "js/rmmz_core.js",
            "js/rmmz_managers.js"
        ]
        let existing = requiredPaths.filter {
            FileManager.default.fileExists(atPath: folder.appendingPathComponent($0).path)
        }
        return GameFileRules.detectEngine(paths: existing)
    }
}

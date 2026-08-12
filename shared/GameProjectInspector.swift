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
        switch self {
        case .unsupportedProject:
            return "所选文件夹中没有找到受支持的 RPG Maker MV/MZ 游戏。"
        case .inaccessibleFolder:
            return "无法读取所选文件夹。"
        case .copyFailed:
            return "复制游戏文件失败。"
        case .invalidArchive:
            return "ZIP 文件损坏或格式不受支持。"
        case .unsafeArchive:
            return "ZIP 包含不安全的路径或符号链接。"
        case .archiveTooLarge:
            return "ZIP 内容过大，已停止导入。"
        case .importInProgress:
            return "已有游戏正在导入，请稍候。"
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
            if let engine = detectEngine(at: item.url) {
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

    private static func detectEngine(at folder: URL) -> RPGMakerWebEngine? {
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

import Foundation

enum RPGMakerWebEngine: String, Equatable {
    case mv
    case mz
}

enum GameFileRules {
    static func detectEngine(paths: [String]) -> RPGMakerWebEngine? {
        let files = Set(paths.map(normalizeForComparison))
        guard files.contains("index.html"), files.contains("data/system.json") else {
            return nil
        }
        if files.contains("js/rmmz_core.js"), files.contains("js/rmmz_managers.js") {
            return .mz
        }
        if files.contains("js/rpg_core.js"), files.contains("js/rpg_managers.js") {
            return .mv
        }
        return nil
    }

    static func safeRelativePath(_ candidate: String) throws -> String {
        guard !candidate.isEmpty, !candidate.contains("\0") else {
            throw GameFileError.invalidPath
        }

        let slashPath = candidate.replacingOccurrences(of: "\\", with: "/")
        guard !slashPath.hasPrefix("/"), !slashPath.range(of: #"^[A-Za-z]:/"#, options: .regularExpression).isPresent else {
            throw GameFileError.absolutePath
        }

        var parts: [String] = []
        for part in slashPath.split(separator: "/", omittingEmptySubsequences: true).map(String.init) {
            if part == "." { continue }
            if part == ".." {
                guard !parts.isEmpty else { throw GameFileError.pathTraversal }
                parts.removeLast()
                continue
            }
            parts.append(part)
        }

        guard !parts.isEmpty else { throw GameFileError.invalidPath }
        return parts.joined(separator: "/")
    }

    static func mimeType(for path: String) -> String {
        switch URL(fileURLWithPath: path).pathExtension.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "js", "mjs": return "text/javascript; charset=utf-8"
        case "json": return "application/json; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "webp": return "image/webp"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "ogg", "oga": return "audio/ogg"
        case "m4a": return "audio/mp4"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        case "mp4": return "video/mp4"
        case "webm": return "video/webm"
        case "woff": return "font/woff"
        case "woff2": return "font/woff2"
        case "ttf": return "font/ttf"
        case "otf": return "font/otf"
        default: return "application/octet-stream"
        }
    }

    private static func normalizeForComparison(_ path: String) -> String {
        var normalized = path.replacingOccurrences(of: "\\", with: "/")
        while normalized.hasPrefix("./") {
            normalized.removeFirst(2)
        }
        return normalized.lowercased()
    }
}

enum GameFileError: LocalizedError, Equatable {
    case invalidPath
    case absolutePath
    case pathTraversal
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case .invalidPath: return "资源路径无效。"
        case .absolutePath: return "不允许访问绝对路径。"
        case .pathTraversal: return "资源路径超出了游戏目录。"
        case .missingResource(let path): return "找不到游戏资源：\(path)"
        }
    }
}

private extension Optional {
    var isPresent: Bool { self != nil }
}

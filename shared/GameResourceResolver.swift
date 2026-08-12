import Foundation

struct ResolvedGameResource {
    let data: Data
    let statusCode: Int
    let mimeType: String
    let textEncodingName: String?
}

enum GameResourceResolver {
    static func resolve(requestURL: URL, gameRoot: URL) throws -> ResolvedGameResource {
        let decodedPath = requestURL.path.removingPercentEncoding ?? requestURL.path
        let requestedPath = decodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let relativePath = try GameFileRules.safeRelativePath(
            requestedPath.isEmpty ? "index.html" : requestedPath
        )
        let standardizedRoot = gameRoot.standardizedFileURL
        let resourceURL = try resolveCaseInsensitive(relativePath: relativePath, root: standardizedRoot)
        let type = GameFileRules.mimeType(for: resourceURL.path)
        return ResolvedGameResource(
            data: try Data(contentsOf: resourceURL, options: [.mappedIfSafe]),
            statusCode: 200,
            mimeType: type.components(separatedBy: ";").first ?? "application/octet-stream",
            textEncodingName: type.contains("charset=utf-8") ? "utf-8" : nil
        )
    }

    private static func resolveCaseInsensitive(relativePath: String, root: URL) throws -> URL {
        var current = root
        for component in relativePath.split(separator: "/").map(String.init) {
            let exact = current.appendingPathComponent(component)
            if FileManager.default.fileExists(atPath: exact.path) {
                current = exact
                continue
            }
            let children: [URL]
            do {
                children = try FileManager.default.contentsOfDirectory(
                    at: current,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: []
                )
            } catch {
                throw GameFileError.missingResource(relativePath)
            }
            guard let match = children.first(where: {
                $0.lastPathComponent.compare(component, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }) else {
                throw GameFileError.missingResource(relativePath)
            }
            current = match
        }

        let standardized = current.standardizedFileURL
        let rootPrefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
        guard standardized.path.hasPrefix(rootPrefix) else { throw GameFileError.pathTraversal }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: standardized.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            throw GameFileError.missingResource(relativePath)
        }
        return standardized
    }
}

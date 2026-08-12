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
        let relativePath = try GameFileRules.safeRelativePath(
            decodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        )
        let standardizedRoot = gameRoot.standardizedFileURL
        let resourceURL = standardizedRoot.appendingPathComponent(relativePath).standardizedFileURL
        let rootPrefix = standardizedRoot.path.hasSuffix("/") ? standardizedRoot.path : standardizedRoot.path + "/"
        guard resourceURL.path.hasPrefix(rootPrefix) else {
            throw GameFileError.pathTraversal
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: resourceURL.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            throw GameFileError.missingResource
        }
        let type = GameFileRules.mimeType(for: resourceURL.path)
        return ResolvedGameResource(
            data: try Data(contentsOf: resourceURL, options: [.mappedIfSafe]),
            statusCode: 200,
            mimeType: type.components(separatedBy: ";").first ?? "application/octet-stream",
            textEncodingName: type.contains("charset=utf-8") ? "utf-8" : nil
        )
    }
}

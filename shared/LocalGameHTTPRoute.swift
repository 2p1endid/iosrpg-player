import Foundation

struct LocalGameHTTPRoute: Equatable {
    let relativePath: String

    static func parse(path: String, expectedGameID: String) throws -> LocalGameHTTPRoute {
        let decoded = path.removingPercentEncoding ?? path
        let trimmed = decoded.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.isEmpty {
            return LocalGameHTTPRoute(relativePath: "index.html")
        }

        let components = trimmed.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        let candidate: String
        if components.first == "games" {
            guard components.count >= 2, components[1] == expectedGameID else {
                throw GameFileError.invalidPath
            }
            candidate = components.dropFirst(2).joined(separator: "/")
        } else {
            candidate = components.joined(separator: "/")
        }
        let relativePath = try GameFileRules.safeRelativePath(candidate.isEmpty ? "index.html" : candidate)
        return LocalGameHTTPRoute(relativePath: relativePath)
    }
}

import Foundation

enum GameRuntimeCompatibilityPatcher {
    static func patch(_ data: Data, relativePath: String) -> Data {
        guard var source = String(data: data, encoding: .utf8) else {
            return data
        }

        if relativePath.caseInsensitiveCompare("js/libs/logger.js") == .orderedSame {
            source = source.replacingOccurrences(
                of: "const f = new Function('p', 'return new URL(p, import.meta.url).pathname');",
                with: "const f = function(p) { return new URL(p, (document.currentScript && document.currentScript.src) || document.baseURI).pathname; };"
            )
        }
        return Data(source.utf8)
    }
}

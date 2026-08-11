import Foundation
import WebKit

final class GameResourceSchemeHandler: NSObject, WKURLSchemeHandler {
    let gameRoot: URL?

    init(gameRoot: URL?) {
        self.gameRoot = gameRoot?.standardizedFileURL
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        do {
            guard let gameRoot, let requestURL = urlSchemeTask.request.url else {
                throw GameFileError.missingResource
            }

            let requestPath = requestURL.path.removingPercentEncoding ?? requestURL.path
            let relativePath = try GameFileRules.safeRelativePath(requestPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
            let resourceURL = gameRoot.appendingPathComponent(relativePath).standardizedFileURL

            let rootPrefix = gameRoot.path.hasSuffix("/") ? gameRoot.path : gameRoot.path + "/"
            guard resourceURL.path.hasPrefix(rootPrefix) || resourceURL == gameRoot else {
                throw GameFileError.pathTraversal
            }
            guard FileManager.default.fileExists(atPath: resourceURL.path) else {
                throw GameFileError.missingResource
            }

            let data = try Data(contentsOf: resourceURL, options: [.mappedIfSafe])
            let response = URLResponse(
                url: requestURL,
                mimeType: GameFileRules.mimeType(for: resourceURL.path).components(separatedBy: ";").first,
                expectedContentLength: data.count,
                textEncodingName: GameFileRules.mimeType(for: resourceURL.path).contains("charset=utf-8") ? "utf-8" : nil
            )
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } catch {
            urlSchemeTask.didFailWithError(error)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

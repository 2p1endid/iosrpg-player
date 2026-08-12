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
                throw GameFileError.missingResource("入口请求")
            }
            let resource = try GameResourceResolver.resolve(requestURL: requestURL, gameRoot: gameRoot)
            guard let response = HTTPURLResponse(
                url: requestURL,
                statusCode: resource.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Type": resource.textEncodingName.map { "\(resource.mimeType); charset=\($0)" } ?? resource.mimeType,
                    "Content-Length": String(resource.data.count),
                    "Cache-Control": "no-cache"
                ]
            ) else {
                throw GameFileError.missingResource(requestURL.path)
            }
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(resource.data)
            urlSchemeTask.didFinish()
        } catch {
            urlSchemeTask.didFailWithError(error)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

import Foundation

struct GameHTTPNavigationDiagnostic: Equatable {
    let status: String
    let message: String

    static func evaluate(statusCode: Int, path: String) -> GameHTTPNavigationDiagnostic? {
        guard statusCode >= 400 else { return nil }
        return GameHTTPNavigationDiagnostic(
            status: "加载失败",
            message: "资源加载失败：HTTP \(statusCode) \(path)"
        )
    }
}

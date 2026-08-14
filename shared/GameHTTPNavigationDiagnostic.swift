import Foundation

struct GameHTTPNavigationDiagnostic: Equatable {
    let status: String
    let message: String

    static func evaluate(statusCode: Int, path: String) -> GameHTTPNavigationDiagnostic? {
        guard statusCode >= 400 else { return nil }
        let language = AppLanguage.current
        return GameHTTPNavigationDiagnostic(
            status: language.text(.loadFailed),
            message: "\(language.text(.resourceLoadFailed)): HTTP \(statusCode) \(path)"
        )
    }
}

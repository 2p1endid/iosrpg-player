import Foundation

enum GameRuntimeDiagnosticSeverity: String, Codable, CaseIterable {
    case error
    case warning
    case info
}

enum GameRuntimeDiagnosticCategory: String, Codable, CaseIterable {
    case javascript
    case promise
    case console
    case http
    case navigation
    case server
    case bridge
}

enum GameRuntimeDiagnosticError: Error {
    case invalidBridgeMessage
}

struct GameRuntimeDiagnostic: Codable, Equatable, Identifiable {
    let id: UUID
    let timestamp: Date
    let severity: GameRuntimeDiagnosticSeverity
    let category: GameRuntimeDiagnosticCategory
    let gameName: String
    let gameID: String?
    let pageURL: String?
    let message: String
    let sourceURL: String?
    let line: Int?
    let column: Int?
    let stack: String?
    let details: String?

    static func bridgeMessage(
        _ body: Any,
        gameName: String,
        gameID: String?
    ) throws -> GameRuntimeDiagnostic {
        guard let dictionary = body as? [String: Any],
              let message = dictionary["message"] as? String else {
            throw GameRuntimeDiagnosticError.invalidBridgeMessage
        }
        let category = GameRuntimeDiagnosticCategory(
            rawValue: dictionary["category"] as? String ?? "bridge"
        ) ?? .bridge
        let severity = GameRuntimeDiagnosticSeverity(
            rawValue: dictionary["severity"] as? String ?? "info"
        ) ?? .info
        return GameRuntimeDiagnostic(
            id: UUID(),
            timestamp: Date(),
            severity: severity,
            category: category,
            gameName: gameName,
            gameID: gameID,
            pageURL: dictionary["pageURL"] as? String,
            message: message,
            sourceURL: dictionary["sourceURL"] as? String,
            line: integerValue(dictionary["line"]),
            column: integerValue(dictionary["column"]),
            stack: dictionary["stack"] as? String,
            details: dictionary["details"] as? String
        )
    }

    static func legacyMessage(_ message: String, gameName: String, gameID: String?) -> GameRuntimeDiagnostic {
        let category: GameRuntimeDiagnosticCategory
        let severity: GameRuntimeDiagnosticSeverity
        if message.hasPrefix("JS错误:") || message.hasPrefix("JS Error:") {
            category = .javascript
            severity = .error
        } else if message.hasPrefix("Promise错误:") || message.hasPrefix("Promise Error:") {
            category = .promise
            severity = .error
        } else if message.hasPrefix("控制台错误:") || message.hasPrefix("Console Error:") {
            category = .console
            severity = .error
        } else {
            category = .bridge
            severity = .info
        }
        return GameRuntimeDiagnostic(
            id: UUID(),
            timestamp: Date(),
            severity: severity,
            category: category,
            gameName: gameName,
            gameID: gameID,
            pageURL: nil,
            message: message,
            sourceURL: nil,
            line: nil,
            column: nil,
            stack: nil,
            details: nil
        )
    }

    private static func integerValue(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        if let value = value as? String { return Int(value) }
        return nil
    }
}

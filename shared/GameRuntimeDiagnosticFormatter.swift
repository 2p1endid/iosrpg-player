import Foundation

enum GameRuntimeDiagnosticFormatter {
    static func report(
        diagnostics: [GameRuntimeDiagnostic],
        engineLabel: String?
    ) -> String {
        var lines = ["RRPPGo Runtime Diagnostic"]
        if let diagnostic = diagnostics.last {
            lines.append("Game: \(diagnostic.gameName)")
            if let gameID = diagnostic.gameID { lines.append("Game ID: \(gameID)") }
        }
        if let engineLabel { lines.append("Engine: RPG Maker \(engineLabel)") }
        lines.append("Records: \(diagnostics.count)")
        lines.append("")

        let formatter = ISO8601DateFormatter()
        for (index, diagnostic) in diagnostics.enumerated() {
            lines.append("--- Diagnostic \(index + 1) ---")
            lines.append("Time: \(formatter.string(from: diagnostic.timestamp))")
            lines.append("Severity: \(diagnostic.severity.rawValue)")
            lines.append("Category: \(diagnostic.category.rawValue)")
            if let pageURL = diagnostic.pageURL { lines.append("Page: \(pageURL)") }
            lines.append("Message: \(diagnostic.message)")
            if let sourceURL = diagnostic.sourceURL {
                var source = sourceURL
                if let line = diagnostic.line { source += ":\(line)" }
                if let column = diagnostic.column { source += ":\(column)" }
                lines.append("Source: \(source)")
            } else if let line = diagnostic.line {
                lines.append("Location: \(line):\(diagnostic.column ?? 0)")
            }
            if let stack = diagnostic.stack, !stack.isEmpty {
                lines.append("Stack:")
                lines.append(stack)
            }
            if let details = diagnostic.details, !details.isEmpty {
                lines.append("Details:")
                lines.append(details)
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    static func single(_ diagnostic: GameRuntimeDiagnostic, engineLabel: String?) -> String {
        report(diagnostics: [diagnostic], engineLabel: engineLabel)
    }
}

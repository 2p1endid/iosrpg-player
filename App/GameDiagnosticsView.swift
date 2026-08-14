import SwiftUI
import UIKit

struct GameDiagnosticsView: View {
    @AppLanguageStorage private var language
    @ObservedObject var model: PlayerModel
    @Environment(\.dismiss) private var dismiss
    @State private var copiedMessage: String?

    var body: some View {
        NavigationStack {
            List {
                currentStatusSection

                if model.diagnostics.isEmpty {
                    ContentUnavailableView(
                        language.text(.noDiagnostics),
                        systemImage: model.errorMessage == nil ? "checkmark.circle" : "exclamationmark.triangle.fill",
                        description: Text(model.errorMessage ?? language.text(.diagnosticsDescription))
                    )
                } else {
                    Section(language.text(.actions)) {
                        Button(language.text(.copyCurrentError)) { copyLatest() }
                        Button(language.text(.copyFullDiagnostics)) { copyFullReport() }
                        ShareLink(item: model.copyableDiagnosticReport) {
                            Label(language.text(.shareFullDiagnostics), systemImage: "square.and.arrow.up")
                        }
                        Button(language.text(.clearDiagnostics), role: .destructive) { model.clearDiagnostics() }
                    }

                    ForEach(model.diagnostics.reversed()) { diagnostic in
                        Section {
                            Text(GameRuntimeDiagnosticFormatter.single(
                                diagnostic,
                                engineLabel: model.game?.engineLabel
                            ))
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                        } header: {
                            HStack {
                                Label(
                                    diagnostic.category.rawValue,
                                    systemImage: diagnostic.severity == .error ? "exclamationmark.triangle.fill" : "info.circle"
                                )
                                Spacer()
                                Text(diagnostic.timestamp, style: .time)
                            }
                        }
                    }
                }
            }
            .navigationTitle(language.text(.runtimeDiagnostics))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.text(.done)) { dismiss() }
                }
            }
            .alert(language.text(.copied), isPresented: Binding(
                get: { copiedMessage != nil },
                set: { if !$0 { copiedMessage = nil } }
            )) {
                Button(language.text(.ok), role: .cancel) { copiedMessage = nil }
            } message: {
                Text(copiedMessage ?? "")
            }
        }
    }

    private var currentStatusSection: some View {
        Section(language.text(.currentStatus)) {
            LabeledContent(language.text(.game), value: model.gameName)
            LabeledContent(language.text(.status), value: model.status)
            if let error = model.errorMessage {
                Text(error).foregroundStyle(.red).textSelection(.enabled)
            }
            Text(model.lastGameMessage)
                .font(.caption.monospaced())
                .textSelection(.enabled)
        }
    }

    private func copyLatest() {
        guard let diagnostic = model.latestDiagnostic else { return }
        UIPasteboard.general.string = GameRuntimeDiagnosticFormatter.single(
            diagnostic,
            engineLabel: model.game?.engineLabel
        )
        copiedMessage = language.text(.currentErrorCopied)
    }

    private func copyFullReport() {
        UIPasteboard.general.string = model.copyableDiagnosticReport
        copiedMessage = language.text(.fullDiagnosticsCopied)
    }
}

import SwiftUI
import UIKit

struct GameDiagnosticsView: View {
    @ObservedObject var model: PlayerModel
    @Environment(\.dismiss) private var dismiss
    @State private var copiedMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if model.diagnostics.isEmpty {
                    ContentUnavailableView(
                        "暂无诊断",
                        systemImage: "checkmark.circle",
                        description: Text("运行错误、HTTP 错误和控制台信息会显示在这里。")
                    )
                } else {
                    List {
                        Section("当前状态") {
                            LabeledContent("游戏", value: model.gameName)
                            LabeledContent("状态", value: model.status)
                            Text(model.lastGameMessage)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        }
                        Section("操作") {
                            Button("复制当前错误") { copyLatest() }
                            Button("复制完整诊断") { copyFullReport() }
                            ShareLink(item: model.copyableDiagnosticReport) {
                                Label("分享完整诊断", systemImage: "square.and.arrow.up")
                            }
                            Button("清除诊断", role: .destructive) { model.clearDiagnostics() }
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
            }
            .navigationTitle("运行诊断")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("已复制", isPresented: Binding(
                get: { copiedMessage != nil },
                set: { if !$0 { copiedMessage = nil } }
            )) {
                Button("好", role: .cancel) { copiedMessage = nil }
            } message: {
                Text(copiedMessage ?? "")
            }
        }
    }

    private func copyLatest() {
        guard let diagnostic = model.latestDiagnostic else { return }
        UIPasteboard.general.string = GameRuntimeDiagnosticFormatter.single(
            diagnostic,
            engineLabel: model.game?.engineLabel
        )
        copiedMessage = "当前错误已复制到剪贴板。"
    }

    private func copyFullReport() {
        UIPasteboard.general.string = model.copyableDiagnosticReport
        copiedMessage = "完整诊断已复制到剪贴板。"
    }
}

import Foundation
import WebKit
import CoreGraphics

@MainActor
final class PlayerModel: ObservableObject {
    @Published var status: String
    @Published var errorMessage: String?
    @Published var lastGameMessage = "尚未收到游戏消息"
    @Published private(set) var diagnostics: [GameRuntimeDiagnostic] = []
    @Published var gameCanvasSize: CGSize = .zero

    let game: ImportedGame?
    let gameName: String
    weak var webView: WKWebView?

    private let gameRoot: URL?
    private var httpServer: LocalGameHTTPServer?
    private var isLoading = false
    private let maximumDiagnosticCount = 100

    var latestDiagnostic: GameRuntimeDiagnostic? { diagnostics.last }
    var hasDiagnosticErrors: Bool { diagnostics.contains { $0.severity == .error } }
    var copyableDiagnosticReport: String {
        GameRuntimeDiagnosticFormatter.report(
            diagnostics: diagnostics,
            engineLabel: game?.engineLabel
        )
    }

    init(game: ImportedGame? = nil) {
        self.game = game
        if let game {
            gameName = game.name
            status = "正在准备 \(game.name)…"
            gameRoot = try? game.resolvedGameRootURL()
        } else {
            gameName = "内置测试游戏"
            status = "正在准备内置 MZ 兼容测试游戏…"
            gameRoot = Bundle.main.resourceURL?.appendingPathComponent("TestGame", isDirectory: true)
        }
    }

    func attach(webView: WKWebView) {
        self.webView = webView
    }

    func loadGame() {
        guard !isLoading else { return }
        guard let gameRoot else {
            errorMessage = "找不到游戏目录。"
            status = "无法启动"
            return
        }
        isLoading = true
        errorMessage = nil
        status = "正在启动本地游戏服务器…"
        let gameID = game?.id.uuidString.lowercased() ?? "builtin"
        let server = LocalGameHTTPServer(gameRoot: gameRoot, gameID: gameID)
        httpServer?.stop()
        httpServer = server

        Task {
            do {
                let baseURL = try await server.start()
                guard self.httpServer === server else { return }
                self.status = "正在加载 \(self.gameName)…"
                self.webView?.load(URLRequest(url: baseURL.appendingPathComponent("index.html")))
            } catch {
                guard self.httpServer === server else { return }
                self.errorMessage = "本地游戏服务器启动失败：\(error.localizedDescription)"
                self.appendDiagnostic(GameRuntimeDiagnostic(
                    id: UUID(), timestamp: Date(), severity: .error, category: .server,
                    gameName: self.gameName, gameID: self.game?.id.uuidString,
                    pageURL: nil, message: error.localizedDescription,
                    sourceURL: nil, line: nil, column: nil, stack: nil, details: nil
                ))
                self.status = "无法启动"
                self.isLoading = false
            }
        }
    }

    func didFinishLoading() {
        isLoading = false
    }

    func reloadGame() {
        guard let webView, let currentURL = webView.url else {
            loadGame()
            return
        }
        errorMessage = nil
        status = "正在重新加载 \(gameName)…"
        webView.load(URLRequest(url: currentURL))
    }

    func stop() {
        releaseAllKeys()
        httpServer?.stop()
        httpServer = nil
        isLoading = false
    }

    func sendKey(_ key: VirtualGameKey, pressed: Bool) {
        let script = VirtualInputScriptBuilder.script(for: key.mapping, pressed: pressed)
        webView?.evaluateJavaScript(script) { [weak self] _, error in
            if let error {
                Task { @MainActor in self?.errorMessage = "发送按键失败：\(error.localizedDescription)" }
            }
        }
    }

    func releaseAllKeys() {
        webView?.evaluateJavaScript(VirtualInputScriptBuilder.releaseAllScript())
    }

    func receiveGameMessage(_ message: String) {
        lastGameMessage = message
        let diagnostic = GameRuntimeDiagnostic.legacyMessage(
            message,
            gameName: gameName,
            gameID: game?.id.uuidString
        )
        appendDiagnostic(diagnostic)
        if diagnostic.severity == .error {
            errorMessage = message
        }
    }

    func receiveBridgeMessage(_ body: Any) {
        if let dictionary = body as? [String: Any],
           dictionary["category"] as? String == "viewport" {
            let width = (dictionary["width"] as? NSNumber)?.doubleValue ?? 0
            let height = (dictionary["height"] as? NSNumber)?.doubleValue ?? 0
            if width > 0, height > 0 { gameCanvasSize = CGSize(width: width, height: height) }
            return
        }
        do {
            let diagnostic = try GameRuntimeDiagnostic.bridgeMessage(
                body,
                gameName: gameName,
                gameID: game?.id.uuidString
            )
            appendDiagnostic(diagnostic)
            lastGameMessage = diagnostic.message
            if diagnostic.severity == .error { errorMessage = diagnostic.message }
        } catch {
            receiveGameMessage(String(describing: body))
        }
    }

    func recordHTTPDiagnostic(statusCode: Int, path: String) {
        let message = "资源加载失败：HTTP \(statusCode) \(path)"
        appendDiagnostic(GameRuntimeDiagnostic(
            id: UUID(), timestamp: Date(), severity: .error, category: .http,
            gameName: gameName, gameID: game?.id.uuidString,
            pageURL: webView?.url?.absoluteString, message: message,
            sourceURL: nil, line: nil, column: nil, stack: nil,
            details: "status=\(statusCode) path=\(path)"
        ))
    }

    func clearDiagnostics() {
        diagnostics.removeAll()
        errorMessage = nil
        lastGameMessage = "尚未收到游戏消息"
    }

    private func appendDiagnostic(_ diagnostic: GameRuntimeDiagnostic) {
        diagnostics.append(diagnostic)
        if diagnostics.count > maximumDiagnosticCount {
            diagnostics.removeFirst(diagnostics.count - maximumDiagnosticCount)
        }
    }
}

enum VirtualGameKey: String, CaseIterable, Identifiable {
    case up, down, left, right, confirm, cancel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .up: return "↑"
        case .down: return "↓"
        case .left: return "←"
        case .right: return "→"
        case .confirm: return "A"
        case .cancel: return "B"
        }
    }

    var javascriptKey: String {
        mapping.key
    }

    var mapping: VirtualInputMapping {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .confirm: return .confirm
        case .cancel: return .cancel
        }
    }
}

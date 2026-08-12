import Foundation
import WebKit

@MainActor
final class PlayerModel: ObservableObject {
    @Published var status: String
    @Published var errorMessage: String?
    @Published var lastGameMessage = "尚未收到游戏消息"

    let game: ImportedGame?
    let gameName: String
    weak var webView: WKWebView?

    private let gameRoot: URL?
    private var httpServer: LocalGameHTTPServer?
    private var isLoading = false

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
        httpServer?.stop()
        httpServer = nil
        isLoading = false
    }

    func sendKey(_ key: VirtualGameKey, pressed: Bool) {
        let type = pressed ? "keydown" : "keyup"
        let escapedKey = key.javascriptKey.replacingOccurrences(of: "'", with: "\\'")
        let script = "window.dispatchEvent(new KeyboardEvent('\(type)', {key:'\(escapedKey)', code:'\(escapedKey)', bubbles:true}));"
        webView?.evaluateJavaScript(script) { [weak self] _, error in
            if let error {
                Task { @MainActor in self?.errorMessage = "发送按键失败：\(error.localizedDescription)" }
            }
        }
    }

    func receiveGameMessage(_ message: String) {
        lastGameMessage = message
        if message.hasPrefix("JS错误:") || message.hasPrefix("Promise错误:") || message.hasPrefix("控制台错误:") {
            errorMessage = message
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
        switch self {
        case .up: return "ArrowUp"
        case .down: return "ArrowDown"
        case .left: return "ArrowLeft"
        case .right: return "ArrowRight"
        case .confirm: return "Enter"
        case .cancel: return "Escape"
        }
    }
}

import Foundation
import WebKit

@MainActor
final class PlayerModel: ObservableObject {
    @Published var status: String
    @Published var errorMessage: String?
    @Published var lastGameMessage = "尚未收到游戏消息"

    let game: ImportedGame?
    let gameName: String
    let resourceHandler: GameResourceSchemeHandler
    weak var webView: WKWebView?

    init(game: ImportedGame? = nil) {
        self.game = game
        if let game {
            gameName = game.name
            status = "正在准备 \(game.name)…"
            resourceHandler = GameResourceSchemeHandler(gameRoot: game.gameRootURL)
        } else {
            gameName = "内置测试游戏"
            status = "正在准备内置 MZ 兼容测试游戏…"
            let root = Bundle.main.resourceURL?.appendingPathComponent("TestGame", isDirectory: true)
            resourceHandler = GameResourceSchemeHandler(gameRoot: root)
        }
    }

    func attach(webView: WKWebView) {
        self.webView = webView
    }

    func loadGame() {
        guard resourceHandler.gameRoot != nil else {
            errorMessage = "找不到游戏目录。"
            status = "无法启动"
            return
        }
        let host = game?.id.uuidString.lowercased() ?? "builtin"
        status = "正在加载 \(gameName)…"
        webView?.load(URLRequest(url: URL(string: "rpg-game://\(host)/index.html")!))
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

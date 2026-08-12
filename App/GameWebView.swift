import SwiftUI
import WebKit

struct GameWebView: UIViewRepresentable {
    @ObservedObject var model: PlayerModel

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeUIView(context: Context) -> WKWebView {
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "gameBridge")
        userContentController.addUserScript(WKUserScript(
            source: """
            window.addEventListener('error', function(event) {
              window.webkit.messageHandlers.gameBridge.postMessage('JS错误: ' + (event.message || '未知错误'));
            });
            window.addEventListener('unhandledrejection', function(event) {
              window.webkit.messageHandlers.gameBridge.postMessage('Promise错误: ' + String(event.reason || '未知错误'));
            });
            (function() {
              var originalError = console.error;
              console.error = function() {
                var text = Array.prototype.map.call(arguments, String).join(' ');
                window.webkit.messageHandlers.gameBridge.postMessage('控制台错误: ' + text);
                return originalError.apply(console, arguments);
              };
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        ))

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.websiteDataStore = .default()
        configuration.preferences.isElementFullscreenEnabled = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.allowsBackForwardNavigationGestures = false
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []

        model.attach(webView: webView)
        DispatchQueue.main.async { model.loadGame() }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        private weak var model: PlayerModel?

        init(model: PlayerModel) {
            self.model = model
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            let text: String
            if let value = message.body as? String {
                text = value
            } else {
                text = String(describing: message.body)
            }
            Task { @MainActor in self.model?.receiveGameMessage(text) }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                guard let model = self.model else { return }
                if model.game == nil {
                    model.status = "测试游戏已加载。请使用屏幕按键移动方块。"
                } else {
                    model.status = "\(model.gameName) 已加载。"
                }
                model.didFinishLoading()
                self.model?.errorMessage = nil
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
            guard let response = navigationResponse.response as? HTTPURLResponse else { return .allow }
            if response.statusCode >= 400 {
                Task { @MainActor in
                    self.model?.errorMessage = "资源加载失败：HTTP \(response.statusCode) \(response.url?.path ?? "")"
                }
            }
            return .allow
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            Task { @MainActor in
                self.model?.errorMessage = "WebKit 游戏进程意外终止。"
                self.model?.status = "运行失败"
            }
        }

        private func report(_ error: Error) {
            Task { @MainActor in
                self.model?.errorMessage = error.localizedDescription
                self.model?.status = "加载失败"
            }
        }
    }
}

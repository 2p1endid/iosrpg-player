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
            source: GameBrowserCapabilityScript.source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        userContentController.addUserScript(WKUserScript(
            source: GameVirtualInputBridgeScript.source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        userContentController.addUserScript(WKUserScript(
            source: GameViewportBridgeScript.source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        userContentController.addUserScript(WKUserScript(
            source: Self.diagnosticScript,
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
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = false
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []

        model.attach(webView: webView)
        DispatchQueue.main.async { model.loadGame() }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private static let diagnosticScript = #"""
    (function() {
      function safeString(value) {
        try {
          if (value instanceof Error) return value.name + ': ' + value.message;
          if (typeof value === 'string') return value;
          if (value === null || typeof value === 'number' || typeof value === 'boolean') return String(value);
          var seen = [];
          return JSON.stringify(value, function(key, item) {
            if (typeof item === 'object' && item !== null) {
              if (seen.indexOf(item) >= 0) return '[Circular]';
              seen.push(item);
            }
            return item;
          }).slice(0, 12000);
        } catch (_) { return String(value); }
      }
      function post(payload) {
        try { window.webkit.messageHandlers.gameBridge.postMessage(payload); } catch (_) {}
      }
      window.addEventListener('error', function(event) {
        post({
          category: 'javascript', severity: 'error',
          message: event.message || (event.error && event.error.message) || '未知错误',
          pageURL: location.href,
          sourceURL: event.filename || null,
          line: event.lineno || null,
          column: event.colno || null,
          stack: event.error && event.error.stack ? String(event.error.stack) : null,
          details: event.error && event.error.name ? String(event.error.name) : null
        });
      });
      window.addEventListener('unhandledrejection', function(event) {
        var reason = event.reason;
        post({
          category: 'promise', severity: 'error',
          message: reason && reason.message ? String(reason.message) : safeString(reason || '未知错误'),
          pageURL: location.href, sourceURL: null, line: null, column: null,
          stack: reason && reason.stack ? String(reason.stack) : null,
          details: safeString(reason)
        });
      });
      ['error', 'warn'].forEach(function(level) {
        var original = console[level];
        console[level] = function() {
          var args = Array.prototype.slice.call(arguments);
          var firstError = args.find(function(item) { return item instanceof Error; });
          post({
            category: 'console', severity: level === 'error' ? 'error' : 'warning',
            message: args.map(safeString).join(' '), pageURL: location.href,
            sourceURL: null, line: null, column: null,
            stack: firstError && firstError.stack ? String(firstError.stack) : null,
            details: null
          });
          return original.apply(console, arguments);
        };
      });
    })();
    """#

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        private weak var model: PlayerModel?

        init(model: PlayerModel) {
            self.model = model
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            Task { @MainActor in self.model?.receiveBridgeMessage(message.body) }
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
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in self.model?.releaseAllKeys() }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
            guard let response = navigationResponse.response as? HTTPURLResponse else { return .allow }
            if let diagnostic = GameHTTPNavigationDiagnostic.evaluate(
                statusCode: response.statusCode,
                path: response.url?.path ?? ""
            ) {
                Task { @MainActor in
                    self.model?.errorMessage = diagnostic.message
                    self.model?.status = diagnostic.status
                    self.model?.recordHTTPDiagnostic(
                        statusCode: response.statusCode,
                        path: response.url?.path ?? ""
                    )
                }
                return .cancel
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
                self.model?.receiveBridgeMessage([
                    "category": "navigation", "severity": "error",
                    "message": "WebKit 游戏进程意外终止。",
                    "pageURL": webView.url?.absoluteString ?? ""
                ])
                self.model?.status = "运行失败"
            }
        }

        private func report(_ error: Error) {
            Task { @MainActor in
                self.model?.receiveBridgeMessage([
                    "category": "navigation", "severity": "error",
                    "message": error.localizedDescription,
                    "pageURL": self.model?.webView?.url?.absoluteString ?? ""
                ])
                self.model?.status = "加载失败"
            }
        }
    }
}

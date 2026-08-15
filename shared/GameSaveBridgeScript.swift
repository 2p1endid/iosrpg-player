import Foundation

enum GameSaveBridgeScript {
    static func source(snapshot: [String: String]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys])) ?? Data("{}".utf8)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        return #"""
        (function() {
          var restored = \#(json);
          Object.keys(restored).forEach(function(key) {
            try { localStorage.setItem(key, restored[key]); } catch (_) {}
          });
          if (window.__rrppgoSaveBridgeInstalled) return;
          window.__rrppgoSaveBridgeInstalled = true;
          var __rrppgoOriginalSetItem = Storage.prototype.setItem;
          var __rrppgoOriginalRemoveItem = Storage.prototype.removeItem;
          var __rrppgoOriginalClear = Storage.prototype.clear;
          function snapshot() {
            var values = {};
            try {
              for (var i = 0; i < localStorage.length; i++) {
                var key = localStorage.key(i);
                if (key !== null) values[key] = localStorage.getItem(key) || '';
              }
              window.webkit.messageHandlers.saveBridge.postMessage({type:'snapshot', values:values});
            } catch (_) {}
          }
          Storage.prototype.setItem = function(key, value) {
            var result = __rrppgoOriginalSetItem.apply(this, arguments);
            if (this === localStorage) snapshot();
            return result;
          };
          Storage.prototype.removeItem = function(key) {
            var result = __rrppgoOriginalRemoveItem.apply(this, arguments);
            if (this === localStorage) snapshot();
            return result;
          };
          Storage.prototype.clear = function() {
            var result = __rrppgoOriginalClear.apply(this, arguments);
            if (this === localStorage) snapshot();
            return result;
          };
          window.__rrppgoCaptureSave = snapshot;
          window.addEventListener('pagehide', snapshot);
          window.addEventListener('beforeunload', snapshot);
          document.addEventListener('visibilitychange', function() {
            if (document.visibilityState === 'hidden') snapshot();
          });
        })();
        """#
    }
}

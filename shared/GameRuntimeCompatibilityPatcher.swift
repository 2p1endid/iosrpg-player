import Foundation

enum GameRuntimeCompatibilityPatcher {
    static func patch(_ data: Data, relativePath: String) -> Data {
        if relativePath.caseInsensitiveCompare("js/libs/logger.js") == .orderedSame {
            return Data(browserLoggerScript.utf8)
        }
        if relativePath.caseInsensitiveCompare("js/modManager.js") == .orderedSame {
            return Data(browserModManagerScript.utf8)
        }
        return data
    }

    private static let browserLoggerScript = #"""
    (function(root) {
      function stringify(value) {
        if (typeof value === 'string') return value;
        try { return JSON.stringify(value); } catch (_) { return String(value); }
      }
      function createLogger(label, debugEnabled) {
        function output(method, args) {
          var values = Array.prototype.slice.call(args).map(stringify);
          (console[method] || console.log).apply(console, ['[' + label + ']'].concat(values));
        }
        var logger = {
          level: debugEnabled ? 'debug' : 'info',
          silent: function() { return logger; },
          trace: function() { if (debugEnabled) output('log', arguments); return logger; },
          debug: function() { if (debugEnabled) output('log', arguments); return logger; },
          info: function() { output('log', arguments); return logger; },
          warn: function() { output('warn', arguments); return logger; },
          error: function() { output('error', arguments); return logger; },
          fatal: function() { output('error', arguments); return logger; },
          child: function(bindings) {
            var suffix = bindings && (bindings.label || bindings.name);
            return createLogger(suffix ? label + ':' + suffix : label, debugEnabled);
          }
        };
        return logger;
      }
      root.Logger = {
        defaultLogPath: '',
        createDefaultLogger: function(name, isDebug) {
          return createLogger(name || 'game', !!isDebug);
        }
      };
    })(globalThis);
    """#

    private static let browserModManagerScript = #"""
    (function(root) {
      root.ModManager = {
        getModsList: function() { return Promise.resolve([]); },
        loadMods: function() { return Promise.resolve(); },
        pathResolver: {}
      };
    })(globalThis);
    """#
}

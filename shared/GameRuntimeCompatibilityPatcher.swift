import Foundation

enum GameRuntimeCompatibilityPatcher {
    static func patch(_ data: Data, relativePath: String) -> Data {
        if relativePath.caseInsensitiveCompare("js/libs/logger.js") == .orderedSame {
            return Data(browserLoggerScript.utf8)
        }
        if relativePath.caseInsensitiveCompare("js/modManager.js") == .orderedSame {
            return Data(browserModManagerScript.utf8)
        }
        guard var source = String(data: data, encoding: .utf8) else { return data }

        if relativePath.caseInsensitiveCompare("js/plugins/OrangeGreenworks.js") == .orderedSame {
            source = source.replacingOccurrences(of: "if (Utils.isNwjs())", with: "if (false)")
        }
        if relativePath.caseInsensitiveCompare("js/plugins/DefaultSvgCursor.js") == .orderedSame {
            source = source.replacingOccurrences(of: "logger.warn({err},", with: "globalThis.logger.warn({err},")
        }
        if relativePath.caseInsensitiveCompare("js/plugins/RemtairyMisc.js") == .orderedSame,
           let start = source.range(of: "DKTools.PreloadManager.checkForDLCs = function() {") {
            let bodyStart = start.upperBound
            if let closingBrace = matchingFunctionClosingBrace(in: source, startingAt: bodyStart),
               let semicolon = source[closingBrace...].firstIndex(of: ";") {
                let replacement = "DKTools.PreloadManager.checkForDLCs = function() { DLC_GYM = false; DLC_HAIR = false; DLC_PCUP = false;\n};"
                source.replaceSubrange(start.lowerBound...semicolon, with: replacement)
            }
        }
        return Data(source.utf8)
    }

    private static func matchingFunctionClosingBrace(in source: String, startingAt index: String.Index) -> String.Index? {
        var depth = 1
        var cursor = index
        var quote: Character?
        var escaped = false
        while cursor < source.endIndex {
            let character = source[cursor]
            if let activeQuote = quote {
                if escaped { escaped = false }
                else if character == "\\" { escaped = true }
                else if character == activeQuote { quote = nil }
            } else if character == "\"" || character == "'" || character == "`" {
                quote = character
            } else if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0 { return cursor }
            }
            cursor = source.index(after: cursor)
        }
        return nil
    }

    private static let browserLoggerScript = #"""
    (function(root) {
      function stringify(value) { if (typeof value === 'string') return value; try { return JSON.stringify(value); } catch (_) { return String(value); } }
      function createLogger(label, debugEnabled) {
        function output(method, args) { var values = Array.prototype.slice.call(args).map(stringify); (console[method] || console.log).apply(console, ['[' + label + ']'].concat(values)); }
        var logger = {
          level: debugEnabled ? 'debug' : 'info', silent:function(){return logger;},
          trace:function(){if(debugEnabled)output('log',arguments);return logger;}, debug:function(){if(debugEnabled)output('log',arguments);return logger;},
          info:function(){output('log',arguments);return logger;}, warn:function(){output('warn',arguments);return logger;},
          error:function(){output('error',arguments);return logger;}, fatal:function(){output('error',arguments);return logger;},
          child:function(bindings){var suffix=bindings&&(bindings.label||bindings.name);return createLogger(suffix?label+':'+suffix:label,debugEnabled);}
        }; return logger;
      }
      globalThis.Logger = { defaultLogPath:'', createDefaultLogger:function(name,isDebug){return createLogger(name||'game',!!isDebug);} };
    })(globalThis);
    """#

    private static let browserModManagerScript = #"""
    (function(root) { globalThis.ModManager = { getModsList:function(){return Promise.resolve([]);}, loadMods:function(){return Promise.resolve();}, pathResolver:{} }; })(globalThis);
    """#
}

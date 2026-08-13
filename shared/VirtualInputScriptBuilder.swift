import Foundation

enum VirtualInputScriptBuilder {
    static func script(for mapping: VirtualInputMapping, pressed: Bool) -> String {
        """
        (function() {
          if (window.__iosRPGInputBridge) {
            window.__iosRPGInputBridge.setState('\(mapping.rpgAction)', \(pressed ? "true" : "false"));
          }
        })();
        """
    }

    static func releaseAllScript() -> String {
        let actions = VirtualInputMapping.allCases.map { "'\($0.rpgAction)'" }.joined(separator: ",")
        return """
        (function() {
          var actions = [\(actions)];
          if (window.__iosRPGInputBridge) {
            window.__iosRPGInputBridge.releaseAll();
          } else if (typeof Input !== 'undefined' && Input && Input._currentState) {
            actions.forEach(function(action) { Input._currentState[action] = false; });
          }
        })();
        """
    }
}

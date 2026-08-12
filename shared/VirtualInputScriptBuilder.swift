import Foundation

enum VirtualInputScriptBuilder {
    static func script(for mapping: VirtualInputMapping, pressed: Bool) -> String {
        let eventType = pressed ? "keydown" : "keyup"
        let boolean = pressed ? "true" : "false"
        return """
        (function() {
          var action = '\(mapping.rpgAction)';
          var pressed = \(boolean);
          if (typeof Input !== 'undefined' && Input && Input._currentState) {
            Input._currentState[action] = pressed;
            if (!pressed && Input._latestButton === action) {
              Input._pressedTime = 0;
            }
          }
          var event = new KeyboardEvent('\(eventType)', {
            key: '\(mapping.key)', code: '\(mapping.code)',
            bubbles: true, cancelable: true
          });
          try {
            Object.defineProperty(event, 'keyCode', {get: function(){return \(mapping.keyCode);}});
            Object.defineProperty(event, 'which', {get: function(){return \(mapping.keyCode);}});
          } catch (_) {}
          window.dispatchEvent(event);
          document.dispatchEvent(new KeyboardEvent('\(eventType)', {
            key: '\(mapping.key)', code: '\(mapping.code)', bubbles: true, cancelable: true
          }));
        })();
        """
    }

    static func releaseAllScript() -> String {
        let actions = VirtualInputMapping.allCases.map { "'\($0.rpgAction)'" }.joined(separator: ",")
        return """
        (function() {
          var actions = [\(actions)];
          if (typeof Input !== 'undefined' && Input && Input._currentState) {
            actions.forEach(function(action) { Input._currentState[action] = false; });
            Input._pressedTime = 0;
          }
          window.dispatchEvent(new Event('blur'));
        })();
        """
    }
}

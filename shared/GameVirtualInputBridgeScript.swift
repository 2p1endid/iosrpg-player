import Foundation

enum GameVirtualInputBridgeScript {
    static let source = #"""
    (function(root) {
      if (root.__iosRPGInputBridge && root.__iosRPGInputBridge.version === 2) return;
      var held = Object.create(null);
      var metadata = {
        up:{key:'ArrowUp',code:'ArrowUp',keyCode:38}, down:{key:'ArrowDown',code:'ArrowDown',keyCode:40},
        left:{key:'ArrowLeft',code:'ArrowLeft',keyCode:37}, right:{key:'ArrowRight',code:'ArrowRight',keyCode:39},
        ok:{key:'Enter',code:'Enter',keyCode:13}, escape:{key:'Escape',code:'Escape',keyCode:27}
      };
      function sync() {
        if (root.Input && root.Input._currentState) {
          Object.keys(metadata).forEach(function(action) { root.Input._currentState[action] = !!held[action]; });
        }
      }
      function dispatch(action, pressed) {
        var item = metadata[action]; if (!item) return;
        var type = pressed ? 'keydown' : 'keyup';
        function event() {
          var result = new KeyboardEvent(type, {key:item.key, code:item.code, bubbles:true, cancelable:true, repeat:false});
          try {
            Object.defineProperty(result, 'keyCode', {get:function(){return item.keyCode;}});
            Object.defineProperty(result, 'which', {get:function(){return item.keyCode;}});
          } catch (_) {}
          return result;
        }
        document.dispatchEvent(event());
        root.dispatchEvent(event());
      }
      var bridge = {
        version: 2, held: held,
        setState: function(action, pressed) {
          pressed = !!pressed;
          if (!!held[action] === pressed) { sync(); return; }
          held[action] = pressed; sync(); dispatch(action, pressed);
        },
        releaseAll: function() {
          Object.keys(metadata).forEach(function(action) {
            if (held[action]) dispatch(action, false);
            held[action] = false;
          });
          sync();
        }
      };
      root.__iosRPGInputBridge = bridge;
      function tick() { sync(); root.requestAnimationFrame(tick); }
      root.requestAnimationFrame(tick);
      root.addEventListener('blur', bridge.releaseAll);
      root.addEventListener('pagehide', bridge.releaseAll);
      document.addEventListener('visibilitychange', function() { if (document.hidden) bridge.releaseAll(); });
    })(globalThis);
    """#
}

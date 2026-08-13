import Foundation

enum GameViewportBridgeScript {
    static let source = #"""
    (function(root) {
      if (root.__iosRPGViewportBridgeInstalled) return;
      root.__iosRPGViewportBridgeInstalled = true;
      var lastSignature = '';
      var observedCanvas = null;
      var resizeObserver = null;

      function finite(value) {
        value = Number(value || 0);
        return Number.isFinite(value) && value > 0 ? value : 0;
      }

      function report() {
        var canvas = document.querySelector('canvas');
        var graphics = typeof Graphics !== 'undefined' ? Graphics : null;
        var logicalWidth = finite(graphics && (graphics.width || graphics.boxWidth)) || finite(canvas && canvas.width);
        var logicalHeight = finite(graphics && (graphics.height || graphics.boxHeight)) || finite(canvas && canvas.height);
        var viewportWidth = finite(root.innerWidth) || finite(document.documentElement.clientWidth);
        var viewportHeight = finite(root.innerHeight) || finite(document.documentElement.clientHeight);
        var cssWidth = finite(canvas && canvas.getBoundingClientRect().width);
        var cssHeight = finite(canvas && canvas.getBoundingClientRect().height);
        var scale = logicalWidth && logicalHeight && viewportWidth && viewportHeight
          ? Math.min(viewportWidth / logicalWidth, viewportHeight / logicalHeight) : 0;

        if (graphics && graphics._stretchEnabled !== true) {
          graphics._stretchEnabled = true;
          if (typeof graphics._updateAllElements === 'function') graphics._updateAllElements();
        }

        var signature = [logicalWidth, logicalHeight, viewportWidth, viewportHeight, cssWidth, cssHeight, scale].join(':');
        if (logicalWidth && logicalHeight && viewportWidth && viewportHeight && signature !== lastSignature) {
          lastSignature = signature;
          try {
            root.webkit.messageHandlers.gameBridge.postMessage({
              category:'viewport', severity:'info', message:'viewport',
              width:logicalWidth, height:logicalHeight,
              logicalWidth:logicalWidth, logicalHeight:logicalHeight,
              viewportWidth:viewportWidth, viewportHeight:viewportHeight,
              cssWidth:cssWidth, cssHeight:cssHeight,
              scale:scale, devicePixelRatio:root.devicePixelRatio || 1,
              pageURL:location.href
            });
          } catch (_) {}
        }

        if (canvas !== observedCanvas) {
          if (resizeObserver) resizeObserver.disconnect();
          observedCanvas = canvas;
          if (canvas && typeof ResizeObserver !== 'undefined') {
            resizeObserver = new ResizeObserver(report);
            resizeObserver.observe(canvas);
          }
        }
        root.requestAnimationFrame(report);
      }

      root.addEventListener('resize', report);
      root.addEventListener('orientationchange', report);
      document.addEventListener('DOMContentLoaded', report);
      root.addEventListener('load', report);
      report();
    })(globalThis);
    """#
}

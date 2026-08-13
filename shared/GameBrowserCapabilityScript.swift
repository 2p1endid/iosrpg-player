import Foundation

enum GameBrowserCapabilityScript {
    static let source = #"""
    (function(root) {
      function noopLogger() {
        var logger = {};
        ['silent','trace','debug','info','warn','error','fatal'].forEach(function(name) {
          logger[name] = function() { return logger; };
        });
        logger.child = function() { return noopLogger(); };
        return logger;
      }
      globalThis.logger = globalThis.logger || (root.Logger && root.Logger.createDefaultLogger
        ? root.Logger.createDefaultLogger('browser-compat') : noopLogger());

      var processModule = { env: {}, platform: 'browser', arch: 'unknown', version: '', mainModule: { filename: location.pathname } };
      var pathModule = {
        sep: '/', posix: { sep: '/' },
        dirname: function(value) { value = String(value || '').replace(/\\/g, '/'); return value.slice(0, value.lastIndexOf('/')) || '/'; },
        join: function() { return Array.prototype.slice.call(arguments).filter(Boolean).join('/').replace(/\/+/g, '/'); },
        resolve: function() { return pathModule.join.apply(null, arguments); },
        relative: function(from, to) { return String(to || ''); },
        extname: function(value) { var match = /(?:^|\/)[^/]*(\.[^./]+)$/.exec(String(value || '')); return match ? match[1] : ''; }
      };
      var fsModule = {
        promises: null,
        existsSync: function() { return false; },
        readFileSync: function() { throw new Error('Node fs API is unavailable in browser mode'); },
        writeFileSync: function() {}, mkdirSync: function() {}, readdirSync: function() { return []; }
      };
      var utilModule = { promisify: function(fn) { return function() { return Promise.reject(new Error('Node API unavailable')); }; } };
      globalThis.__iosRPGBrowserRequire = function(name) {
        if (name === 'path' || name === 'node:path') return pathModule;
        if (name === 'fs' || name === 'node:fs') return fsModule;
        if (name === 'process') return processModule;
        if (name === 'util') return utilModule;
        if (name === 'Logger') return root.Logger;
        if (name === 'Alert') return root.swal || root.Swal;
        return {};
      };
    })(globalThis);
    """#
}

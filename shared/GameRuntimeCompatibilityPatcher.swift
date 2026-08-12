import Foundation

enum GameRuntimeCompatibilityPatcher {
    static func patch(_ data: Data, relativePath: String) -> Data {
        guard relativePath.caseInsensitiveCompare("js/libs/rpgmaker.js") == .orderedSame,
              var source = String(data: data, encoding: .utf8),
              let declarationRange = source.range(of: "var PluginManager=") else {
            return data
        }
        source.replaceSubrange(declarationRange, with: "var TilemapPluginManager=")
        source = source.replacingOccurrences(
            of: "PluginManager.parameters",
            with: "TilemapPluginManager.parameters"
        )
        return Data(source.utf8)
    }
}

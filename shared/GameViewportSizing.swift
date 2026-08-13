import CoreGraphics

enum GameViewportSizing {
    static func webViewSize(container: CGSize) -> CGSize {
        container
    }

    static func rpgMakerScale(logical: CGSize, viewport: CGSize) -> CGFloat {
        guard logical.width > 0, logical.height > 0,
              viewport.width > 0, viewport.height > 0 else { return 1 }
        return min(viewport.width / logical.width, viewport.height / logical.height)
    }

    static func fit(content: CGSize, container: CGSize) -> CGSize {
        guard content.width > 0, content.height > 0,
              container.width > 0, container.height > 0 else {
            return container
        }
        let scale = min(container.width / content.width, container.height / content.height)
        return CGSize(width: content.width * scale, height: content.height * scale)
    }
}

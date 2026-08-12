import CoreGraphics

enum GameViewportSizing {
    static func fit(content: CGSize, container: CGSize) -> CGSize {
        guard content.width > 0, content.height > 0,
              container.width > 0, container.height > 0 else {
            return container
        }
        let scale = min(container.width / content.width, container.height / content.height)
        return CGSize(width: content.width * scale, height: content.height * scale)
    }
}

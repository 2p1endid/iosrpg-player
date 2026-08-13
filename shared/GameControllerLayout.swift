import CoreGraphics

struct FaceButtonLayout: Equatable {
    let buttonDiameter: CGFloat
    let a: CGPoint
    let b: CGPoint
    let x: CGPoint
    let y: CGPoint
}

enum GameControllerLayout {
    static func buttonDiameter(
        in size: CGSize,
        horizontalInsets: CGFloat,
        minimumGap: CGFloat
    ) -> CGFloat {
        let heightBased = min(max(size.height * 0.13, 36), 72)
        let availableWidth = max(0, size.width - horizontalInsets - minimumGap)
        let widthBased = availableWidth / 6.15
        return max(36, min(heightBased, widthBased))
    }

    static func combinedControllerWidth(buttonDiameter: CGFloat, minimumGap: CGFloat) -> CGFloat {
        (buttonDiameter * 3 + 6) + minimumGap + (buttonDiameter * 3.15)
    }

    static func faceButtons(in size: CGSize) -> FaceButtonLayout {
        let minimumSide = max(0, min(size.width, size.height))
        let diameter = min(max(minimumSide * 0.28, 48), 72)
        let radius = diameter / 2
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let availableRadius = max(0, min(center.x - radius, center.y - radius))
        let offset = min(diameter * 0.82, availableRadius)
        return FaceButtonLayout(
            buttonDiameter: diameter,
            a: CGPoint(x: center.x, y: center.y + offset),
            b: CGPoint(x: center.x + offset, y: center.y),
            x: CGPoint(x: center.x - offset, y: center.y),
            y: CGPoint(x: center.x, y: center.y - offset)
        )
    }
}

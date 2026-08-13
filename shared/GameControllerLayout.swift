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
        let edgeSpacing: CGFloat = 3
        let availableWidth = max(0, size.width - horizontalInsets - minimumGap - edgeSpacing * 4)
        let widthBased = availableWidth / 6
        return max(36, min(heightBased, widthBased))
    }

    static func combinedControllerWidth(buttonDiameter: CGFloat, minimumGap: CGFloat) -> CGFloat {
        let edgeSpacing: CGFloat = 3
        return (buttonDiameter * 3 + edgeSpacing * 2) + minimumGap +
            faceButtonCanvasSize(buttonDiameter: buttonDiameter, edgeSpacing: edgeSpacing).width
    }

    static func faceButtonCanvasSize(buttonDiameter: CGFloat, edgeSpacing: CGFloat) -> CGSize {
        let side = buttonDiameter * 3 + edgeSpacing * 2
        return CGSize(width: side, height: side)
    }

    static func faceButtons(
        in size: CGSize,
        buttonDiameter: CGFloat,
        edgeSpacing: CGFloat
    ) -> FaceButtonLayout {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let offset = buttonDiameter + edgeSpacing
        return FaceButtonLayout(
            buttonDiameter: buttonDiameter,
            a: CGPoint(x: center.x, y: center.y + offset),
            b: CGPoint(x: center.x + offset, y: center.y),
            x: CGPoint(x: center.x - offset, y: center.y),
            y: CGPoint(x: center.x, y: center.y - offset)
        )
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

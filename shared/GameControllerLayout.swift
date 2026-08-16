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

    static func defaultButtons(
        in size: CGSize,
        leadingInset: CGFloat = 18,
        trailingInset: CGFloat = 18,
        bottomInset: CGFloat = 16
    ) -> [VirtualControllerButton] {
        let minimumGap: CGFloat = 12
        let edgeSpacing: CGFloat = 3
        let button = buttonDiameter(
            in: size,
            horizontalInsets: leadingInset + trailingInset,
            minimumGap: minimumGap
        )
        let side = button * 3 + edgeSpacing * 2
        let originY = max(0, size.height - max(bottomInset, 16) - side)
        let dpadX = leadingInset
        let faceX = max(dpadX + side + minimumGap, size.width - trailingInset - side)
        let left = button / 2
        let middle = button * 1.5 + edgeSpacing
        let right = button * 2.5 + edgeSpacing * 2
        let center = side / 2

        func point(_ x: CGFloat, _ y: CGFloat) -> (Double, Double) {
            (Double(x / max(size.width, 1)), Double((originY + y) / max(size.height, 1)))
        }
        let up = point(dpadX + middle, left)
        let down = point(dpadX + middle, right)
        let leftPoint = point(dpadX + left, middle)
        let rightPoint = point(dpadX + right, middle)
        let a = point(faceX + center, right)
        let b = point(faceX + right, center)
        let x = point(faceX + left, center)
        let y = point(faceX + center, left)

        return [
            .init(label: "↑", mapping: .up, x: up.0, y: up.1, size: button, colorHex: "#808080", isBuiltIn: true),
            .init(label: "↓", mapping: .down, x: down.0, y: down.1, size: button, colorHex: "#808080", isBuiltIn: true),
            .init(label: "←", mapping: .left, x: leftPoint.0, y: leftPoint.1, size: button, colorHex: "#808080", isBuiltIn: true),
            .init(label: "→", mapping: .right, x: rightPoint.0, y: rightPoint.1, size: button, colorHex: "#808080", isBuiltIn: true),
            .init(label: "A", mapping: .confirm, x: a.0, y: a.1, size: button, colorHex: "#007AFF", isBuiltIn: true),
            .init(label: "B", mapping: .cancel, x: b.0, y: b.1, size: button, colorHex: "#FF3B30", isBuiltIn: true),
            .init(label: "X", mapping: .x, x: x.0, y: x.1, size: button, colorHex: "#34C759", isBuiltIn: true),
            .init(label: "Y", mapping: .y, x: y.0, y: y.1, size: button, colorHex: "#FFCC00", isBuiltIn: true)
        ]
    }
}

import Foundation

struct KeyboardInputDescriptor: Codable, Equatable, Hashable {
    let displayName: String
    let key: String
    let code: String
    let keyCode: Int

    static func parse(_ input: String) -> KeyboardInputDescriptor? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let upper = trimmed.uppercased()

        if upper.count == 1, let scalar = upper.unicodeScalars.first {
            let value = Int(scalar.value)
            if value >= 65 && value <= 90 {
                return KeyboardInputDescriptor(
                    displayName: upper,
                    key: upper.lowercased(),
                    code: "Key\(upper)",
                    keyCode: value
                )
            }
            if value >= 48 && value <= 57 {
                return KeyboardInputDescriptor(
                    displayName: upper,
                    key: upper,
                    code: "Digit\(upper)",
                    keyCode: value
                )
            }
        }

        if upper.hasPrefix("F"),
           let number = Int(upper.dropFirst()),
           (1...12).contains(number) {
            return KeyboardInputDescriptor(
                displayName: "F\(number)",
                key: "F\(number)",
                code: "F\(number)",
                keyCode: 111 + number
            )
        }

        let named: [String: KeyboardInputDescriptor] = [
            "ENTER": .init(displayName: "Enter", key: "Enter", code: "Enter", keyCode: 13),
            "RETURN": .init(displayName: "Enter", key: "Enter", code: "Enter", keyCode: 13),
            "SPACE": .init(displayName: "Space", key: " ", code: "Space", keyCode: 32),
            "ESC": .init(displayName: "Esc", key: "Escape", code: "Escape", keyCode: 27),
            "ESCAPE": .init(displayName: "Esc", key: "Escape", code: "Escape", keyCode: 27),
            "TAB": .init(displayName: "Tab", key: "Tab", code: "Tab", keyCode: 9),
            "SHIFT": .init(displayName: "Shift", key: "Shift", code: "ShiftLeft", keyCode: 16),
            "CTRL": .init(displayName: "Ctrl", key: "Control", code: "ControlLeft", keyCode: 17),
            "CONTROL": .init(displayName: "Ctrl", key: "Control", code: "ControlLeft", keyCode: 17),
            "ALT": .init(displayName: "Alt", key: "Alt", code: "AltLeft", keyCode: 18),
            "BACKSPACE": .init(displayName: "⌫", key: "Backspace", code: "Backspace", keyCode: 8),
            "DELETE": .init(displayName: "Del", key: "Delete", code: "Delete", keyCode: 46),
            "HOME": .init(displayName: "Home", key: "Home", code: "Home", keyCode: 36),
            "END": .init(displayName: "End", key: "End", code: "End", keyCode: 35),
            "PAGEUP": .init(displayName: "PgUp", key: "PageUp", code: "PageUp", keyCode: 33),
            "PAGEDOWN": .init(displayName: "PgDn", key: "PageDown", code: "PageDown", keyCode: 34),
            "UP": .init(displayName: "↑", key: "ArrowUp", code: "ArrowUp", keyCode: 38),
            "DOWN": .init(displayName: "↓", key: "ArrowDown", code: "ArrowDown", keyCode: 40),
            "LEFT": .init(displayName: "←", key: "ArrowLeft", code: "ArrowLeft", keyCode: 37),
            "RIGHT": .init(displayName: "→", key: "ArrowRight", code: "ArrowRight", keyCode: 39)
        ]
        return named[upper.replacingOccurrences(of: " ", with: "")]
    }
}

struct VirtualInputMapping: Equatable, CaseIterable {
    enum Kind: String, CaseIterable, Codable {
        case up, down, left, right, confirm, cancel, x, y, pageup, pagedown
    }

    let kind: Kind
    let key: String
    let code: String
    let keyCode: Int
    let rpgAction: String

    static let up = VirtualInputMapping(kind: .up, key: "ArrowUp", code: "ArrowUp", keyCode: 38, rpgAction: "up")
    static let down = VirtualInputMapping(kind: .down, key: "ArrowDown", code: "ArrowDown", keyCode: 40, rpgAction: "down")
    static let left = VirtualInputMapping(kind: .left, key: "ArrowLeft", code: "ArrowLeft", keyCode: 37, rpgAction: "left")
    static let right = VirtualInputMapping(kind: .right, key: "ArrowRight", code: "ArrowRight", keyCode: 39, rpgAction: "right")
    static let confirm = VirtualInputMapping(kind: .confirm, key: "Enter", code: "Enter", keyCode: 13, rpgAction: "ok")
    static let cancel = VirtualInputMapping(kind: .cancel, key: "Escape", code: "Escape", keyCode: 27, rpgAction: "escape")
    static let x = VirtualInputMapping(kind: .x, key: "x", code: "KeyX", keyCode: 88, rpgAction: "menu")
    static let y = VirtualInputMapping(kind: .y, key: "Shift", code: "ShiftLeft", keyCode: 16, rpgAction: "shift")
    static let pageup = VirtualInputMapping(kind: .pageup, key: "PageUp", code: "PageUp", keyCode: 33, rpgAction: "pageup")
    static let pagedown = VirtualInputMapping(kind: .pagedown, key: "PageDown", code: "PageDown", keyCode: 34, rpgAction: "pagedown")

    static let allCases: [VirtualInputMapping] = [.up, .down, .left, .right, .confirm, .cancel, .x, .y, .pageup, .pagedown]

    static func mapping(for kind: Kind) -> VirtualInputMapping {
        allCases.first { $0.kind == kind } ?? .confirm
    }
}

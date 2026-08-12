import Foundation

struct VirtualInputMapping: Equatable, CaseIterable {
    enum Kind: String, CaseIterable {
        case up, down, left, right, confirm, cancel
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

    static let allCases: [VirtualInputMapping] = [.up, .down, .left, .right, .confirm, .cancel]

    static func mapping(for kind: Kind) -> VirtualInputMapping {
        allCases.first { $0.kind == kind } ?? .confirm
    }
}

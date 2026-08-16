import Foundation
import CoreGraphics

struct VirtualControllerButton: Codable, Equatable, Identifiable {
    let id: UUID
    var label: String
    var mapping: VirtualInputMapping.Kind
    var x: Double
    var y: Double
    var size: Double
    var colorHex: String
    var isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        label: String,
        mapping: VirtualInputMapping.Kind,
        x: Double,
        y: Double,
        size: Double,
        colorHex: String,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.label = label
        self.mapping = mapping
        self.x = x
        self.y = y
        self.size = size
        self.colorHex = colorHex
        self.isBuiltIn = isBuiltIn
        normalize()
    }

    mutating func normalize() {
        x = min(max(x, 0), 1)
        y = min(max(y, 0), 1)
        size = min(max(size, 36), 120)
        if !Self.isValidColor(colorHex) { colorHex = "#808080" }
    }

    private static func isValidColor(_ value: String) -> Bool {
        guard value.count == 7, value.first == "#" else { return false }
        return value.dropFirst().allSatisfy { $0.isHexDigit }
    }
}

struct VirtualControllerProfile: Codable, Equatable {
    var schemaVersion = 1
    var buttons: [VirtualControllerButton]

    static let defaultProfile = VirtualControllerProfile(
        buttons: GameControllerLayout.defaultButtons(in: CGSize(width: 375, height: 852))
    )

    static func adaptiveDefault(in size: CGSize) -> VirtualControllerProfile {
        VirtualControllerProfile(buttons: GameControllerLayout.defaultButtons(in: size))
    }

    @discardableResult
    mutating func addButton(mapping: VirtualInputMapping.Kind) -> VirtualControllerButton {
        guard buttons.count < 24 else { return buttons.last ?? Self.defaultProfile.buttons[0] }
        let button = VirtualControllerButton(
            label: Self.defaultLabel(for: mapping),
            mapping: mapping,
            x: 0.5,
            y: 0.5,
            size: 60,
            colorHex: "#8E8E93"
        )
        buttons.append(button)
        return button
    }

    static func defaultLabel(for mapping: VirtualInputMapping.Kind) -> String {
        switch mapping {
        case .up: "↑"
        case .down: "↓"
        case .left: "←"
        case .right: "→"
        case .confirm: "A"
        case .cancel: "B"
        case .x: "X"
        case .y: "Y"
        case .pageup: "L"
        case .pagedown: "R"
        }
    }
}

struct VirtualControllerProfileStore {
    let baseURL: URL

    init(baseURL: URL? = nil) {
        self.baseURL = baseURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RRPPGo/ControllerProfiles", isDirectory: true)
    }

    func load(gameID: String) throws -> VirtualControllerProfile {
        let url = fileURL(gameID: gameID)
        guard FileManager.default.fileExists(atPath: url.path) else { return .defaultProfile }
        do {
            var profile = try JSONDecoder().decode(VirtualControllerProfile.self, from: Data(contentsOf: url))
            guard profile.schemaVersion == 1 else { return .defaultProfile }
            profile.buttons = Array(profile.buttons.prefix(24))
            for index in profile.buttons.indices { profile.buttons[index].normalize() }
            return profile.buttons.isEmpty ? .defaultProfile : profile
        } catch {
            return .defaultProfile
        }
    }

    func save(_ profile: VirtualControllerProfile, gameID: String) throws {
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(profile)
        try data.write(to: fileURL(gameID: gameID), options: .atomic)
    }

    func hasProfile(gameID: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(gameID: gameID).path)
    }

    private func fileURL(gameID: String) -> URL {
        let safeID = gameID.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "_", options: .regularExpression)
        return baseURL.appendingPathComponent("\(safeID).json")
    }
}
import Foundation

struct VirtualControllerButton: Codable, Equatable, Identifiable {
    let id: UUID
    var label: String
    var mapping: VirtualInputMapping.Kind
    var x: Double
    var y: Double
    var size: Double
    var colorHex: String

    init(
        id: UUID = UUID(),
        label: String,
        mapping: VirtualInputMapping.Kind,
        x: Double,
        y: Double,
        size: Double,
        colorHex: String
    ) {
        self.id = id
        self.label = label
        self.mapping = mapping
        self.x = x
        self.y = y
        self.size = size
        self.colorHex = colorHex
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
    var buttons: [VirtualControllerButton]

    static let defaultProfile = VirtualControllerProfile(buttons: [
        .init(label: "↑", mapping: .up, x: 0.20, y: 0.70, size: 60, colorHex: "#808080"),
        .init(label: "↓", mapping: .down, x: 0.20, y: 0.90, size: 60, colorHex: "#808080"),
        .init(label: "←", mapping: .left, x: 0.10, y: 0.80, size: 60, colorHex: "#808080"),
        .init(label: "→", mapping: .right, x: 0.30, y: 0.80, size: 60, colorHex: "#808080"),
        .init(label: "A", mapping: .confirm, x: 0.80, y: 0.86, size: 60, colorHex: "#007AFF"),
        .init(label: "B", mapping: .cancel, x: 0.90, y: 0.76, size: 60, colorHex: "#FF3B30"),
        .init(label: "X", mapping: .x, x: 0.70, y: 0.76, size: 60, colorHex: "#34C759"),
        .init(label: "Y", mapping: .y, x: 0.80, y: 0.66, size: 60, colorHex: "#FFCC00")
    ])

    @discardableResult
    mutating func addButton(mapping: VirtualInputMapping.Kind) -> VirtualControllerButton {
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
        return try JSONDecoder().decode(VirtualControllerProfile.self, from: Data(contentsOf: url))
    }

    func save(_ profile: VirtualControllerProfile, gameID: String) throws {
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(profile)
        try data.write(to: fileURL(gameID: gameID), options: .atomic)
    }

    private func fileURL(gameID: String) -> URL {
        let safeID = gameID.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "_", options: .regularExpression)
        return baseURL.appendingPathComponent("\(safeID).json")
    }
}
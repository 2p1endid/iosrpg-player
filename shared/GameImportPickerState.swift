import Foundation

enum GameImportSource: String, Equatable, Identifiable {
    case zip
    case folder
    var id: String { rawValue }
}

struct GameImportPickerState: Equatable {
    private(set) var source: GameImportSource?
    private(set) var isPresented = false

    mutating func present(_ source: GameImportSource) {
        self.source = source
        isPresented = true
    }

    mutating func presentationChanged(isPresented: Bool) {
        self.isPresented = isPresented
    }

    mutating func consumeSource() -> GameImportSource? {
        defer { source = nil }
        return source
    }

    mutating func cancel() {
        isPresented = false
        source = nil
    }
}

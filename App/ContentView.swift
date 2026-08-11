import SwiftUI

struct ContentView: View {
    @StateObject private var model = PlayerModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                GameWebView(model: model)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                controller
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("MV/MZ Web Runtime Spike")
                    .font(.headline)
                Spacer()
                Button("重新加载") { model.loadGame() }
                    .buttonStyle(.bordered)
            }
            Text(model.status)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("JS: \(model.lastGameMessage)")
                .font(.caption2.monospaced())
                .foregroundStyle(.mint)
                .lineLimit(1)
            if let error = model.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var controller: some View {
        HStack(alignment: .center) {
            directionPad
            Spacer(minLength: 24)
            HStack(spacing: 18) {
                GameButton(key: .cancel, color: .red, model: model)
                GameButton(key: .confirm, color: .blue, model: model)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.black.opacity(0.92))
    }

    private var directionPad: some View {
        VStack(spacing: 4) {
            GameButton(key: .up, color: .gray, model: model)
            HStack(spacing: 4) {
                GameButton(key: .left, color: .gray, model: model)
                Color.clear.frame(width: 58, height: 58)
                GameButton(key: .right, color: .gray, model: model)
            }
            GameButton(key: .down, color: .gray, model: model)
        }
    }
}

private struct GameButton: View {
    let key: VirtualGameKey
    let color: Color
    @ObservedObject var model: PlayerModel
    @State private var isPressed = false

    var body: some View {
        Text(key.title)
            .font(.title2.bold())
            .frame(width: 58, height: 58)
            .background(color.opacity(isPressed ? 0.95 : 0.55), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        model.sendKey(key, pressed: true)
                    }
                    .onEnded { _ in
                        isPressed = false
                        model.sendKey(key, pressed: false)
                    }
            )
            .accessibilityLabel(key.rawValue)
    }
}

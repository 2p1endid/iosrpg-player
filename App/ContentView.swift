import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var library = GameLibraryStore()
    @State private var isImportingFolder = false
    @State private var selectedGame: ImportedGame?
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            Group {
                if library.games.isEmpty {
                    emptyState
                } else {
                    gameList
                }
            }
            .navigationTitle("我的游戏")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        GamePlayerScreen(game: nil)
                    } label: {
                        Label("测试环境", systemImage: "testtube.2")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isImportingFolder = true
                    } label: {
                        Label("导入文件夹", systemImage: "folder.badge.plus")
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isImportingFolder,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let folder = urls.first else {
                if case let .failure(error) = result { importError = error.localizedDescription }
                return
            }
            Task {
                do {
                    selectedGame = try await library.importFolder(folder)
                } catch {
                    importError = error.localizedDescription
                }
            }
        }
        .navigationDestination(item: $selectedGame) { game in
            GamePlayerScreen(game: game)
        }
        .alert("导入失败", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("好", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "未知错误")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有游戏", systemImage: "gamecontroller")
        } description: {
            Text("从“文件”App 选择已经解压的 RPG Maker MV 或 MZ 项目文件夹。")
        } actions: {
            Button("导入游戏文件夹") { isImportingFolder = true }
                .buttonStyle(.borderedProminent)
            NavigationLink("打开内置测试环境") {
                GamePlayerScreen(game: nil)
            }
        }
    }

    private var gameList: some View {
        List {
            if let message = library.operationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(library.games) { game in
                Button {
                    selectedGame = game
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue.gradient)
                            Image(systemName: "gamecontroller.fill")
                                .foregroundStyle(.white)
                                .font(.title2)
                        }
                        .frame(width: 52, height: 52)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("RPG Maker \(game.engineLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(game.importedAt, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        do { try library.delete(game) }
                        catch { importError = error.localizedDescription }
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
    }
}

struct GamePlayerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: PlayerModel

    init(game: ImportedGame?) {
        _model = StateObject(wrappedValue: PlayerModel(game: game))
    }

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
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button { dismiss() } label: {
                    Label("游戏库", systemImage: "chevron.left")
                }
                Text(model.gameName)
                    .font(.headline)
                    .lineLimit(1)
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

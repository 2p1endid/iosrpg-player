import SwiftUI
import UniformTypeIdentifiers

private enum GameImportSource: String, Identifiable {
    case zip
    case folder
    var id: String { rawValue }
    var allowedTypes: [UTType] { self == .zip ? [.zip] : [.folder] }
}

struct ContentView: View {
    @StateObject private var library = GameLibraryStore()
    @State private var importSource: GameImportSource?
    @State private var navigationPath: [ImportedGame] = []
    @State private var importError: String?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if library.games.isEmpty { emptyState } else { gameList }
            }
            .navigationTitle("我的游戏")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { GamePlayerScreen(game: nil) } label: {
                        Label("测试环境", systemImage: "testtube.2")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { importSource = .zip } label: {
                            Label("导入 ZIP", systemImage: "doc.zipper")
                        }
                        Button { importSource = .folder } label: {
                            Label("导入文件夹", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Label("导入游戏", systemImage: "plus")
                    }
                    .disabled(library.importProgress != nil)
                }
            }
            .navigationDestination(for: ImportedGame.self) { game in
                GamePlayerScreen(game: game)
            }
        }
        .fileImporter(
            isPresented: Binding(
                get: { importSource != nil },
                set: { if !$0 { importSource = nil } }
            ),
            allowedContentTypes: importSource?.allowedTypes ?? [.data],
            allowsMultipleSelection: false
        ) { result in
            let source = importSource
            importSource = nil
            guard case let .success(urls) = result, let url = urls.first, let source else {
                if case let .failure(error) = result { importError = error.localizedDescription }
                return
            }
            Task {
                do {
                    let game = source == .zip
                        ? try await library.importZIP(url)
                        : try await library.importFolder(url)
                    navigationPath.append(game)
                } catch {
                    importError = error.localizedDescription
                }
            }
        }
        .overlay { if let progress = library.importProgress { ImportProgressOverlay(progress: progress) } }
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
            Text("导入 RPG Maker MV/MZ ZIP，或选择已经解压的项目文件夹。")
        } actions: {
            Button("导入 ZIP") { importSource = .zip }
                .buttonStyle(.borderedProminent)
            Button("导入文件夹") { importSource = .folder }
            NavigationLink("打开内置测试环境") { GamePlayerScreen(game: nil) }
        }
    }

    private var gameList: some View {
        List {
            if let message = library.operationMessage {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            ForEach(library.games) { game in
                NavigationLink(value: game) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(.blue.gradient)
                            Image(systemName: "gamecontroller.fill")
                                .foregroundStyle(.white).font(.title2)
                        }
                        .frame(width: 52, height: 52)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.name).font(.headline).foregroundStyle(.primary)
                            Text("RPG Maker \(game.engineLabel)").font(.caption).foregroundStyle(.secondary)
                            Text(game.importedAt, style: .date).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        do { try library.delete(game) }
                        catch { importError = error.localizedDescription }
                    } label: { Label("删除", systemImage: "trash") }
                }
            }
        }
    }
}

private struct ImportProgressOverlay: View {
    let progress: GameImportProgress

    var body: some View {
        ZStack {
            Color.black.opacity(0.48).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView(value: progress.fraction, total: 1)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                HStack {
                    Text(progress.phase.rawValue).font(.headline)
                    Spacer()
                    Text("\(progress.percentage)%").monospacedDigit().font(.headline)
                }
                Text("请保持 App 在前台，导入完成后会自动打开游戏。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: 380)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding()
        }
        .allowsHitTesting(true)
    }
}

struct GamePlayerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: PlayerModel

    init(game: ImportedGame?) { _model = StateObject(wrappedValue: PlayerModel(game: game)) }

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
                Button { dismiss() } label: { Label("游戏库", systemImage: "chevron.left") }
                Text(model.gameName).font(.headline).lineLimit(1)
                Spacer()
                Button("重新加载") { model.loadGame() }.buttonStyle(.bordered)
            }
            Text(model.status).font(.caption).foregroundStyle(.secondary)
            Text("JS: \(model.lastGameMessage)")
                .font(.caption2.monospaced()).foregroundStyle(.mint).lineLimit(1)
            if let error = model.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
        }
        .padding(.horizontal).padding(.vertical, 8).background(.ultraThinMaterial)
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
        .padding(.horizontal, 24).padding(.vertical, 14).background(.black.opacity(0.92))
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
        Text(key.title).font(.title2.bold()).frame(width: 58, height: 58)
            .background(color.opacity(isPressed ? 0.95 : 0.55), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    model.sendKey(key, pressed: true)
                }
                .onEnded { _ in
                    isPressed = false
                    model.sendKey(key, pressed: false)
                })
            .accessibilityLabel(key.rawValue)
    }
}

import SwiftUI
import UniformTypeIdentifiers

private extension GameImportSource {
    var allowedTypes: [UTType] { self == .zip ? [.zip] : [.folder] }
}

struct ContentView: View {
    @StateObject private var library = GameLibraryStore()
    @State private var importPicker = GameImportPickerState()
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
                        Button { importPicker.present(.zip) } label: {
                            Label("导入 ZIP", systemImage: "doc.zipper")
                        }
                        Button { importPicker.present(.folder) } label: {
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
                get: { importPicker.isPresented },
                set: { importPicker.presentationChanged(isPresented: $0) }
            ),
            allowedContentTypes: importPicker.source?.allowedTypes ?? [.data],
            allowsMultipleSelection: false
        ) { result in
            let source = importPicker.consumeSource()
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
            Button("导入 ZIP") { importPicker.present(.zip) }
                .buttonStyle(.borderedProminent)
            Button("导入文件夹") { importPicker.present(.folder) }
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
    @State private var showsDiagnostics = false
    @State private var showsController = true

    init(game: ImportedGame?) { _model = StateObject(wrappedValue: PlayerModel(game: game)) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                GeometryReader { proxy in
                    let viewport = GameViewportSizing.fit(
                        content: model.gameCanvasSize,
                        container: proxy.size
                    )
                    ZStack {
                        GameWebView(model: model)
                            .frame(width: viewport.width, height: viewport.height)
                            .background(Color.black)
                            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        if showsController { controllerOverlay }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
        .onDisappear { model.stop() }
        .sheet(isPresented: $showsDiagnostics) {
            GameDiagnosticsView(model: model)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button { dismiss() } label: { Label("游戏库", systemImage: "chevron.left") }
                Text(model.gameName).font(.headline).lineLimit(1)
                Spacer()
                if !model.diagnostics.isEmpty {
                    Button {
                        showsDiagnostics = true
                    } label: {
                        Label("错误详情", systemImage: model.hasDiagnosticErrors ? "exclamationmark.triangle.fill" : "doc.text.magnifyingglass")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(model.hasDiagnosticErrors ? .red : .secondary)
                    }
                    .accessibilityLabel("错误详情")
                }
                Button {
                    showsController.toggle()
                } label: {
                    Image(systemName: showsController ? "gamecontroller.fill" : "gamecontroller")
                }
                .accessibilityLabel(showsController ? "隐藏虚拟手柄" : "显示虚拟手柄")
                Button("重新加载") { model.reloadGame() }.buttonStyle(.bordered)
            }
            Text(model.status).font(.caption).foregroundStyle(.secondary)
            Text("JS: \(model.lastGameMessage)")
                .font(.caption2.monospaced()).foregroundStyle(.mint).lineLimit(2)
                .contentShape(Rectangle())
                .onTapGesture { if !model.diagnostics.isEmpty { showsDiagnostics = true } }
            if let error = model.errorMessage {
                Button {
                    showsDiagnostics = true
                } label: {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal).padding(.vertical, 8).background(.ultraThinMaterial)
    }

    private var controllerOverlay: some View {
        GeometryReader { proxy in
            let buttonSize = min(max(proxy.size.height * 0.13, 48), 72)
            HStack(alignment: .bottom) {
                directionPad(buttonSize: buttonSize)
                Spacer(minLength: 24)
                HStack(alignment: .bottom, spacing: buttonSize * 0.25) {
                    GameButton(key: .cancel, color: .red, model: model, size: buttonSize)
                        .offset(y: -buttonSize * 0.1)
                    GameButton(key: .confirm, color: .blue, model: model, size: buttonSize)
                        .offset(y: -buttonSize * 0.45)
                }
            }
            .padding(.horizontal, max(proxy.safeAreaInsets.leading, 18))
            .padding(.bottom, max(proxy.safeAreaInsets.bottom, 16))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func directionPad(buttonSize: CGFloat) -> some View {
        VStack(spacing: 3) {
            GameButton(key: .up, color: .gray, model: model, size: buttonSize)
            HStack(spacing: 3) {
                GameButton(key: .left, color: .gray, model: model, size: buttonSize)
                Color.clear.frame(width: buttonSize, height: buttonSize)
                GameButton(key: .right, color: .gray, model: model, size: buttonSize)
            }
            GameButton(key: .down, color: .gray, model: model, size: buttonSize)
        }
    }
}

private struct GameButton: View {
    let key: VirtualGameKey
    let color: Color
    @ObservedObject var model: PlayerModel
    let size: CGFloat
    @State private var isPressed = false

    var body: some View {
        Text(key.title).font(.title2.bold()).frame(width: size, height: size)
            .background(color.opacity(isPressed ? 0.95 : 0.45), in: Circle())
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

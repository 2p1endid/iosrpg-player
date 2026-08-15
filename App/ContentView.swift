import SwiftUI
import UniformTypeIdentifiers

private extension GameImportSource {
    var allowedTypes: [UTType] { self == .zip ? [.zip] : [.folder] }
}

struct ContentView: View {
    @AppLanguageStorage private var language
    @StateObject private var library = GameLibraryStore()
    @State private var importPicker = GameImportPickerState()
    @State private var navigationPath: [ImportedGame] = []
    @State private var importError: String?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if library.games.isEmpty { emptyState } else { gameList }
            }
            .navigationTitle(language.text(.myGames))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { GamePlayerScreen(game: nil) } label: {
                        Label(language.text(.testEnvironment), systemImage: "testtube.2")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { importPicker.present(.zip) } label: {
                            Label(language.text(.importZIP), systemImage: "doc.zipper")
                        }
                        .disabled(library.importProgress != nil)
                        Button { importPicker.present(.folder) } label: {
                            Label(language.text(.importFolder), systemImage: "folder.badge.plus")
                        }
                        .disabled(library.importProgress != nil)
                        Divider()
                        NavigationLink {
                            LanguageSettingsView()
                        } label: {
                            Label(language.text(.language), systemImage: "globe")
                        }
                        NavigationLink {
                            AboutView()
                        } label: {
                            Label(language.text(.about), systemImage: "info.circle")
                        }
                    } label: {
                        Label(language.text(.more), systemImage: "ellipsis.circle")
                    }
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
                if case let .failure(error) = result { importError = localizedError(error) }
                return
            }
            Task {
                do {
                    let game = source == .zip
                        ? try await library.importZIP(url)
                        : try await library.importFolder(url)
                    navigationPath.append(game)
                } catch {
                    importError = localizedError(error)
                }
            }
        }
        .overlay { if let progress = library.importProgress { ImportProgressOverlay(progress: progress, language: language) } }
        .alert(language.text(.importFailed), isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button(language.text(.ok), role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? language.text(.unknownError))
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(language.text(.noGames), systemImage: "gamecontroller")
        } description: {
            Text(language.text(.noGamesDescription))
        } actions: {
            Button(language.text(.importZIP)) { importPicker.present(.zip) }
                .buttonStyle(.borderedProminent)
            Button(language.text(.importFolder)) { importPicker.present(.folder) }
            NavigationLink(language.text(.openTestEnvironment)) { GamePlayerScreen(game: nil) }
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
                        catch { importError = localizedError(error) }
                    } label: { Label(language.text(.delete), systemImage: "trash") }
                }
            }
        }
    }

    private func localizedError(_ error: Error) -> String {
        if let importError = error as? GameImportError { return importError.description(language: language) }
        if let fileError = error as? GameFileError { return fileError.description(language: language) }
        return error.localizedDescription
    }
}

private struct ImportProgressOverlay: View {
    let progress: GameImportProgress
    let language: AppLanguage

    var body: some View {
        ZStack {
            Color.black.opacity(0.48).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView(value: progress.fraction, total: 1)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                HStack {
                    Text(progress.phase.title(language: language)).font(.headline)
                    Spacer()
                    Text("\(progress.percentage)%").monospacedDigit().font(.headline)
                }
                Text(language.text(.keepAppForeground))
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
    @AppLanguageStorage private var language
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: PlayerModel
    @State private var showsDiagnostics = false
    @State private var showsController = true
    @State private var showsControllerEditor = false
    @State private var showsSaveManager = false
    @State private var controllerProfile: VirtualControllerProfile
    private let controllerStore = VirtualControllerProfileStore()
    @State private var showsToolbar = true
    @State private var toolbarHideTask: Task<Void, Never>?

    init(game: ImportedGame?) {
        let model = PlayerModel(game: game)
        _model = StateObject(wrappedValue: model)
        _controllerProfile = State(initialValue: (try? VirtualControllerProfileStore().load(gameID: model.saveGameID)) ?? .defaultProfile)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { proxy in
                ZStack {
                    GameWebView(model: model)
                        .id(model.saveGeneration)
                        .frame(
                            width: GameViewportSizing.webViewSize(container: proxy.size).width,
                            height: GameViewportSizing.webViewSize(container: proxy.size).height
                        )
                        .background(Color.black)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                if showsController {
                    controllerOverlay
                }

                if showsToolbar {
                    toolbarOverlay(proxy: proxy)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    toolbarHandle(proxy: proxy)
                        .transition(.opacity)
                }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
        }
        .statusBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
        .onAppear { scheduleToolbarHide() }
        .onDisappear {
            toolbarHideTask?.cancel()
            model.captureSaveNow()
            model.stop()
        }
        .onChange(of: hasRuntimeError) { _, hasErrors in
            if hasErrors { showToolbarTemporarily(keepVisible: true) }
        }
        .onChange(of: showsDiagnostics) { _, isPresented in
            if isPresented {
                toolbarHideTask?.cancel()
            } else {
                scheduleToolbarHide()
            }
        }
        .sheet(isPresented: $showsDiagnostics) {
            GameDiagnosticsView(model: model)
        }
        .sheet(isPresented: $showsControllerEditor) {
            let originalProfile = (try? controllerStore.load(gameID: model.saveGameID)) ?? .defaultProfile
            VirtualControllerEditorView(
                profile: $controllerProfile,
                onSave: { try? controllerStore.save(controllerProfile, gameID: model.saveGameID) },
                onCancel: { controllerProfile = originalProfile }
            )
        }
        .sheet(isPresented: $showsSaveManager) {
            SaveManagementView(model: model)
        }
    }

    private func toolbarOverlay(proxy: GeometryProxy) -> some View {
        HStack(spacing: 8) {
            toolbarButton("chevron.left", label: language.text(.gameLibrary)) { dismiss() }

            Button {
                showsDiagnostics = true
            } label: {
                Image(systemName: hasRuntimeError ? "exclamationmark.triangle.fill" : "doc.text.magnifyingglass")
                    .foregroundStyle(hasRuntimeError ? .red : .white)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel(language.text(.runtimeDiagnostics))

            toolbarButton(
                showsController ? "gamecontroller.fill" : "gamecontroller",
                label: language.text(showsController ? .hideController : .showController)
            ) {
                showsController.toggle()
                if !showsController { model.releaseAllKeys() }
                showToolbarTemporarily()
            }

            toolbarButton("slider.horizontal.3", label: language.text(.controllerSettings)) {
                model.releaseAllKeys()
                showsControllerEditor = true
                showToolbarTemporarily(keepVisible: true)
            }

            toolbarButton("externaldrive.fill", label: language.text(.saveManagement)) {
                model.captureSaveNow()
                showsSaveManager = true
                showToolbarTemporarily(keepVisible: true)
            }

            toolbarButton("arrow.clockwise", label: language.text(.reload)) {
                model.reloadGame()
                showToolbarTemporarily()
            }

            toolbarButton("chevron.up", label: language.text(.hideToolbar)) {
                toolbarHideTask?.cancel()
                withAnimation(.easeOut(duration: 0.2)) { showsToolbar = false }
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.top, max(proxy.safeAreaInsets.top, 8))
        .padding(.leading, max(proxy.safeAreaInsets.leading, 10))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func toolbarHandle(proxy: GeometryProxy) -> some View {
        Button {
            showToolbarTemporarily()
        } label: {
            Image(systemName: hasRuntimeError ? "exclamationmark.triangle.fill" : "chevron.down")
                .foregroundStyle(hasRuntimeError ? .red : .white)
                .frame(width: 44, height: 24)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .accessibilityLabel(language.text(.showGameToolbar))
        .padding(.top, max(proxy.safeAreaInsets.top, 4))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func toolbarButton(
        _ systemName: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
        }
        .accessibilityLabel(label)
    }

    private func showToolbarTemporarily(keepVisible: Bool = false) {
        toolbarHideTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { showsToolbar = true }
        if !keepVisible { scheduleToolbarHide() }
    }

    private func scheduleToolbarHide() {
        toolbarHideTask?.cancel()
        guard !showsDiagnostics, !hasRuntimeError else { return }
        toolbarHideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) { showsToolbar = false }
            }
        }
    }

    private var hasRuntimeError: Bool {
        model.hasDiagnosticErrors || model.errorMessage != nil
    }

    private var controllerOverlay: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(controllerProfile.buttons) { button in
                    ConfiguredGameButton(button: button, model: model)
                        .position(
                            x: min(max(button.x * proxy.size.width, button.size / 2), max(button.size / 2, proxy.size.width - button.size / 2)),
                            y: min(max(button.y * proxy.size.height, button.size / 2), max(button.size / 2, proxy.size.height - button.size / 2))
                        )
                }
            }
        }
    }
}

private struct ConfiguredGameButton: View {
    let button: VirtualControllerButton
    @ObservedObject var model: PlayerModel
    @State private var isPressed = false

    var body: some View {
        Text(button.label).font(.title2.bold()).frame(width: button.size, height: button.size)
            .background(Color(hex: button.colorHex).opacity(isPressed ? 0.95 : 0.5), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    model.sendMapping(button.mapping, pressed: true)
                }
                .onEnded { _ in
                    isPressed = false
                    model.sendMapping(button.mapping, pressed: false)
                })
            .onDisappear {
                if isPressed {
                    isPressed = false
                    model.sendMapping(button.mapping, pressed: false)
                }
            }
            .accessibilityLabel(button.label)
    }
}

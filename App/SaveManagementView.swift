import SwiftUI

struct SaveManagementView: View {
    @AppLanguageStorage private var language
    private let gameName: String
    private let gameID: String
    private let allowsCapture: Bool
    private let captureAction: (() -> Void)?
    private let restoreAction: ((UUID) throws -> Void)?
    private let vault: GameSaveVault
    @Environment(\.dismiss) private var dismiss
    @State private var currentSnapshot: GameSaveSnapshot?
    @State private var backups: [GameSaveBackup] = []
    @State private var name = ""
    @State private var errorMessage: String?

    init(model: PlayerModel) {
        gameName = model.gameName
        gameID = model.saveGameID
        allowsCapture = true
        captureAction = { model.captureSaveNow() }
        restoreAction = { try model.restoreSaveBackup($0) }
        vault = GameSaveVault()
    }

    init(game: ImportedGame) {
        gameName = game.name
        gameID = game.saveGameID
        allowsCapture = false
        captureAction = nil
        restoreAction = nil
        vault = GameSaveVault()
    }

    var body: some View {
        NavigationStack {
            List {
                Section(language.text(.game)) {
                    Text(gameName)
                    if !allowsCapture {
                        Text(language.text(.restoreOnNextLaunch))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(language.text(.currentSave)) {
                    if let snapshot = currentSnapshot {
                        LabeledContent(language.text(.capturedAt), value: snapshot.capturedAt.formatted())
                        LabeledContent(language.text(.saveEntries), value: "\(snapshot.localStorage.count)")
                        if allowsCapture {
                            Button(language.text(.captureNow)) {
                                captureAction?()
                                refreshSoon()
                            }
                        }
                        TextField(language.text(.backupName), text: $name)
                        Button(language.text(.createBackup)) { createBackup() }
                    } else {
                        Text(language.text(.noSaveSnapshot))
                        if allowsCapture {
                            Button(language.text(.captureNow)) {
                                captureAction?()
                                refreshSoon()
                            }
                        }
                    }
                }

                Section(language.text(.backups)) {
                    if backups.isEmpty {
                        Text(language.text(.noBackups))
                    } else {
                        ForEach(backups) { backup in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(backup.name).font(.headline)
                                Text(backup.createdAt.formatted()).font(.caption).foregroundStyle(.secondary)
                                Text("\(backup.snapshot.localStorage.count) \(language.text(.saveEntries))")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button(language.text(.restore)) { restore(backup) }.tint(.blue)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(language.text(.delete), role: .destructive) { delete(backup) }
                            }
                        }
                    }
                }
            }
            .navigationTitle(language.text(.saveManagement))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(language.text(.done)) { dismiss() } }
            }
            .onAppear { refresh() }
            .alert(language.text(.saveManagement), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(language.text(.ok), role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func refresh() {
        do {
            currentSnapshot = try vault.loadCurrent(gameID: gameID)
            backups = try vault.listBackups(gameID: gameID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshSoon() {
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            await MainActor.run { refresh() }
        }
    }

    private func createBackup() {
        do {
            _ = try vault.createBackup(gameID: gameID, name: name)
            name = ""
            refresh()
        } catch { errorMessage = error.localizedDescription }
    }

    private func restore(_ backup: GameSaveBackup) {
        do {
            if let restoreAction {
                try restoreAction(backup.id)
            } else {
                try vault.restoreBackup(backup.id, gameID: gameID)
            }
            refresh()
            if allowsCapture { dismiss() }
        } catch { errorMessage = error.localizedDescription }
    }

    private func delete(_ backup: GameSaveBackup) {
        do {
            try vault.deleteBackup(backup.id, gameID: gameID)
            refresh()
        } catch { errorMessage = error.localizedDescription }
    }
}

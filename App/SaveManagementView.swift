import SwiftUI

struct SaveManagementView: View {
    @AppLanguageStorage private var language
    @ObservedObject var model: PlayerModel
    @Environment(\.dismiss) private var dismiss
    @State private var backups: [GameSaveBackup] = []
    @State private var name = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section(language.text(.currentSave)) {
                    if let snapshot = model.currentSaveSnapshot() {
                        LabeledContent(language.text(.capturedAt), value: snapshot.capturedAt.formatted())
                        LabeledContent(language.text(.saveEntries), value: "\(snapshot.localStorage.count)")
                        Button(language.text(.captureNow)) { model.captureSaveNow() }
                        TextField(language.text(.backupName), text: $name)
                        Button(language.text(.createBackup)) { createBackup() }
                    } else {
                        Text(language.text(.noSaveSnapshot))
                        Button(language.text(.captureNow)) { model.captureSaveNow() }
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
        do { backups = try model.saveBackups() }
        catch { errorMessage = error.localizedDescription }
    }

    private func createBackup() {
        do {
            _ = try model.createSaveBackup(name: name)
            name = ""
            refresh()
        } catch { errorMessage = error.localizedDescription }
    }

    private func restore(_ backup: GameSaveBackup) {
        do {
            try model.restoreSaveBackup(backup.id)
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }

    private func delete(_ backup: GameSaveBackup) {
        do {
            try model.deleteSaveBackup(backup.id)
            refresh()
        } catch { errorMessage = error.localizedDescription }
    }
}

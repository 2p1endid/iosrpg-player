import SwiftUI

struct SaveManagementView: View {
    @ObservedObject var model: PlayerModel
    @Environment(\.dismiss) private var dismiss
    @State private var backups: [GameSaveBackup] = []
    @State private var name = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Current Save") {
                    if let snapshot = model.currentSaveSnapshot() {
                        LabeledContent("Captured", value: snapshot.capturedAt.formatted())
                        LabeledContent("Entries", value: "\(snapshot.localStorage.count)")
                        Button("Capture Now") { model.captureSaveNow() }
                        TextField("Backup name", text: $name)
                        Button("Create Backup") { createBackup() }
                    } else {
                        Text("No native save snapshot is available yet.")
                        Button("Capture Now") { model.captureSaveNow() }
                    }
                }

                Section("Backups") {
                    if backups.isEmpty {
                        Text("No backups")
                    } else {
                        ForEach(backups) { backup in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(backup.name).font(.headline)
                                Text(backup.createdAt.formatted()).font(.caption).foregroundStyle(.secondary)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button("Restore") { restore(backup) }.tint(.blue)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) { delete(backup) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Save Management")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .onAppear { refresh() }
            .alert("Save Management", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
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

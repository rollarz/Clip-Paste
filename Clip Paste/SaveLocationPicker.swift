import AppKit
import SwiftUI

struct SaveLocationPicker: View {
    @Binding var selection: SaveLocation
    @State private var customPath = (try? CustomSaveFolder.selectedURL())?.path
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Save files to:", selection: $selection) {
                ForEach(SaveLocation.allCases) { location in
                    Text(location.displayName).tag(location)
                }
            }
            .pickerStyle(.menu)

            if selection == .custom {
                HStack {
                    Text(customPath ?? "Choose a folder to save files in.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Choose Folder…", action: chooseFolder)
                }
            }
        }
        .alert("Cannot choose folder", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Default Save Folder"
        panel.prompt = "Choose"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = try? CustomSaveFolder.selectedURL()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            Preferences.customSaveFolderBookmark = try CustomSaveFolder.bookmark(for: url)
            customPath = url.path
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

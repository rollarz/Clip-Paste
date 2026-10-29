import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

enum SettingsTab: Hashable {
    case general
    case image
    case text
}

struct SettingsView: View {
    @State private var isImageEnabled: Bool = Preferences.isImageBehaviorEnabled
    @State private var isTextEnabled: Bool = Preferences.isTextBehaviorEnabled
    @State private var selectedSaveLocation: SaveLocation = Preferences.saveLocation
    @State private var isDefaultSaveEnabled: Bool = Preferences.isDefaultSaveEnabled
    @State private var imageTemplate: String = Preferences.imageFilenameTemplate
    @State private var textTemplate: String = Preferences.textFilenameTemplate
    @State private var selectedTab: SettingsTab = .general

    @State private var imageCounterValue: Int = Preferences.imageCounter
    @State private var textCounterValue: Int = Preferences.textCounter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Tab", selection: $selectedTab) {
                Text("General").tag(SettingsTab.general)
                Text("Image").tag(SettingsTab.image)
                Text("Text").tag(SettingsTab.text)
            }
            .pickerStyle(.segmented)
            .tint(.blue)

            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsTab(
                        selectedSaveLocation: $selectedSaveLocation,
                        isDefaultSaveEnabled: $isDefaultSaveEnabled
                    )
                case .image:
                    ImageSettingsTab(
                        isImageEnabled: $isImageEnabled,
                        imageTemplate: $imageTemplate,
                        imageCounter: $imageCounterValue
                    )
                case .text:
                    TextSettingsTab(
                        isTextEnabled: $isTextEnabled,
                        textTemplate: $textTemplate,
                        textCounter: $textCounterValue
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(20)
        .onChange(of: isImageEnabled) { _, newValue in
            Preferences.isImageBehaviorEnabled = newValue
        }
        .onChange(of: isTextEnabled) { _, newValue in
            Preferences.isTextBehaviorEnabled = newValue
        }
        .onChange(of: selectedSaveLocation) { _, newValue in
            Preferences.saveLocation = newValue
        }
        .onChange(of: isDefaultSaveEnabled) { _, newValue in
            Preferences.isDefaultSaveEnabled = newValue
        }
        .onChange(of: imageTemplate) { _, newValue in
            Preferences.imageFilenameTemplate = newValue
        }
        .onChange(of: textTemplate) { _, newValue in
            Preferences.textFilenameTemplate = newValue
        }
        .onAppear {
            imageCounterValue = Preferences.imageCounter
            textCounterValue = Preferences.textCounter
        }
    }
}

struct GeneralSettingsTab: View {
    @Binding var selectedSaveLocation: SaveLocation
    @Binding var isDefaultSaveEnabled: Bool
    @AppStorage(BehaviorKey.hideDockIcon.rawValue) private var hideDockIcon = false
    @AppStorage(BehaviorKey.showMenuBarIcon.rawValue) private var showMenuBarIcon = false
    @AppStorage(BehaviorKey.automaticUpdateChecksEnabled.rawValue) private var automaticUpdateChecksEnabled = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Text("Global Shortcut").font(.headline)) {
                    HStack {
                        Text("Shortcut:")
                        KeyboardShortcuts.Recorder(for: .smartPaste)
                    }
                    Text("Use this shortcut in Finder to trigger smart paste.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                GroupBox(label: Text("Default Save Location").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Use a default save folder when Finder is not frontmost", isOn: $isDefaultSaveEnabled)

                        VStack(alignment: .leading, spacing: 4) {
                            SaveLocationPicker(selection: $selectedSaveLocation)

                            Text("Files are saved here when Finder is not frontmost.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .disabled(!isDefaultSaveEnabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                GroupBox(label: Text("General").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        LaunchAtLogin.Toggle("Open at login")
                        Toggle("Hide Dock icon", isOn: $hideDockIcon)
                        Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
                        if hideDockIcon && !showMenuBarIcon {
                            Text("Open Clip Paste from Applications to return to Settings.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                GroupBox(label: Text("Updates").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Check for updates at launch", isOn: $automaticUpdateChecksEnabled)
                        HStack {
                            Text("Check for a new version of Clip Paste on GitHub.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Check for Updates…") {
                                CPUpdateChecker.shared.checkNow()
                            }
                            .controlSize(.small)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}

struct ImageSettingsTab: View {
    @Binding var isImageEnabled: Bool
    @Binding var imageTemplate: String
    @Binding var imageCounter: Int
    @AppStorage(BehaviorKey.imageFileFormat.rawValue) private var imageFormat = ImageFileFormat.png
    @AppStorage(BehaviorKey.imageCompressionQuality.rawValue) private var imageQuality = 0.9

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Text("Image Behaviour").font(.headline)) {
                    Toggle("Create image file when clipboard contains an image", isOn: $isImageEnabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 20) {
                    GroupBox(label: Text("Image Format").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Save images as:", selection: $imageFormat) {
                                ForEach(ImageFileFormat.allCases) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            if imageFormat.isLossy {
                                HStack {
                                    Text("Quality")
                                    Slider(value: $imageQuality, in: 0.1...1)
                                    Text(imageQuality, format: .percent.precision(.fractionLength(0)))
                                        .monospacedDigit()
                                }
                            }
                            if imageFormat == .jpeg {
                                Text("Transparent areas are saved with a white background.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    GroupBox(label: Text("Image Filename Template").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("""
You can use these variables in the image filename:
- {date}      → 2025-12-07
- {time}      → 22.41.05
- {datetime}  → 2025-12-07 22.41.05
- {weekday}   → Sunday
- {counter}   → 1, 2, 3...
- {name}      → image name from the clipboard (if available)

The selected format’s extension is added automatically.
""")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("Example: Image {name} {date} at {time}")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                TextField("Image filename template", text: $imageTemplate)
                                    .frame(maxWidth: .infinity)
                                    .textFieldStyle(.roundedBorder)
                                Text(".\(imageFormat.pathExtension)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }

                            Text("If a filename is already in use, a numbered suffix is added.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    GroupBox(label: Text("Counter").font(.headline)) {
                        HStack {
                            Text("Current value:")
                            Text("\(imageCounter)")
                                .monospacedDigit()
                            Spacer()
                            Button("Reset to zero") {
                                imageCounter = 0
                                Preferences.imageCounter = 0
                            }
                            .controlSize(.small)
                        }
                        .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
                .disabled(!isImageEnabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}

struct TextSettingsTab: View {
    @Binding var isTextEnabled: Bool
    @Binding var textTemplate: String
    @Binding var textCounter: Int
    @AppStorage(BehaviorKey.textFileFormat.rawValue) private var textFormat = TextFileFormat.plainText

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Text("Text Behaviour").font(.headline)) {
                    Toggle("Create text file when clipboard contains text", isOn: $isTextEnabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 20) {
                    GroupBox(label: Text("Text Format").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Save text as:", selection: $textFormat) {
                                ForEach(TextFileFormat.allCases) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            Text("RTF preserves rich text supplied by the source app. HTML preserves clipboard HTML or available rich text. Otherwise, plain text is used.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    GroupBox(label: Text("Text Filename Template").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("""
You can use these variables in the text filename:
- {date}      → 2025-12-07
- {time}      → 22.41.05
- {datetime}  → 2025-12-07 22.41.05
- {weekday}   → Sunday
- {counter}   → 1, 2, 3...
- {firstWords} → first words of the clipboard text

The selected format’s extension is added automatically.
""")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("Example: Note {date} - {firstWords}")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                TextField("Text filename template", text: $textTemplate)
                                    .frame(maxWidth: .infinity)
                                    .textFieldStyle(.roundedBorder)
                                Text(".\(textFormat.pathExtension)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }

                            Text("If a filename is already in use, a numbered suffix is added.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    GroupBox(label: Text("Counter").font(.headline)) {
                        HStack {
                            Text("Current value:")
                            Text("\(textCounter)")
                                .monospacedDigit()
                            Spacer()
                            Button("Reset to zero") {
                                textCounter = 0
                                Preferences.textCounter = 0
                            }
                            .controlSize(.small)
                        }
                        .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
                .disabled(!isTextEnabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}


///#Preview {SettingsView()}

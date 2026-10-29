import AppKit

enum ClipboardHandler {
    private static var lastAutomationNotAuthorized = false

    static func handleSmartPaste() {
        let pasteboard = NSPasteboard.general
        
        if clipboardContainsFiles(pasteboard: pasteboard) {
            return
        }
        
        if Preferences.isImageBehaviorEnabled, let image = clipboardImage(pasteboard: pasteboard) {
            createImageFile(from: image)
            return
        }
        
        if Preferences.isTextBehaviorEnabled, let text = clipboardText(pasteboard: pasteboard) {
            createTextFile(from: text)
            return
        }
    }

    private static var isFinderFrontmost: Bool {
        let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return bundleIdentifier == "com.apple.finder"
    }

    private static func clipboardContainsFiles(pasteboard: NSPasteboard) -> Bool {
        return pasteboard.types?.contains(.fileURL) == true
    }

    private static func clipboardImage(pasteboard: NSPasteboard) -> NSImage? {
        NSImage(pasteboard: pasteboard)
    }
    
    private static func clipboardImageName(pasteboard: NSPasteboard) -> String? {
        // Try to infer a name from file URLs on the pasteboard, if any
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let url = urls.first {
            let base = url.deletingPathExtension().lastPathComponent
            if !base.isEmpty {
                return base
            }
        }
        // Detect screenshots on the pasteboard (e.g. from macOS screenshot shortcuts)
        if let types = pasteboard.types {
            if types.contains(NSPasteboard.PasteboardType("com.apple.screencapture")) {
                return "screenshot"
            }
            if types.contains(NSPasteboard.PasteboardType("com.apple.screencapture.type")) {
                return "screenshot'"
            }

            // Fallback: if there is image data but no explicit name, treat it as a screenshot-like image
            let imageUTIs = [
                "public.png",
                "public.tiff",
                "public.jpeg",
                "public.heic",
                "public.bmp"
            ]
            let hasImageType = types.contains { type in
                imageUTIs.contains(type.rawValue)
            }
            if hasImageType {
                return "screenshot"
            }
        }

        return nil
    }

    private static func clipboardText(pasteboard: NSPasteboard) -> String? {
        pasteboard.string(forType: .string)
    }

    private static func saveDirectoryURL() -> URL? {
        if isFinderFrontmost {
            if let finderURL = finderFrontmostDirectoryURL() {
                return finderURL
            }
            if lastAutomationNotAuthorized {
                return nil
            }
        }

        if !Preferences.isDefaultSaveEnabled {
            return nil
        }
        
        return defaultSaveDirectoryURL()
    }
    
    private static func defaultSaveDirectoryURL() -> URL? {
        let fileManager = FileManager.default
        let domain: FileManager.SearchPathDomainMask = .userDomainMask
        
        let directory: FileManager.SearchPathDirectory
        switch Preferences.saveLocation {
        case .desktop:
            directory = .desktopDirectory
        case .downloads:
            directory = .downloadsDirectory
        case .pictures:
            directory = .picturesDirectory
        }
        
        let url = fileManager.urls(for: directory, in: domain).first
        return url
    }
    
    private static func finderFrontmostDirectoryURL() -> URL? {
        let scriptSource = """
        tell application "Finder"
            if (count of windows) is 0 then
                return POSIX path of (desktop as alias)
            else
                set targetFolder to (target of front window) as alias
                return POSIX path of targetFolder
            end if
        end tell
        """
        
        guard let script = NSAppleScript(source: scriptSource) else {
            return nil
        }
        
        var errorDict: NSDictionary?
        let output = script.executeAndReturnError(&errorDict)
        
        if let errorDict = errorDict {
            if let errorNumber = errorDict[NSAppleScript.errorNumber] as? Int, errorNumber == -1743 {
                lastAutomationNotAuthorized = true
                showAutomationPermissionAlertIfNeeded()
                return nil
            } else {
                lastAutomationNotAuthorized = false
            }
        } else {
            lastAutomationNotAuthorized = false
        }
        
        guard let path = output.stringValue else {
            return nil
        }
        
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let url = URL(fileURLWithPath: trimmedPath)
        return url
    }

    private static func createImageFile(from image: NSImage) {
        guard let folderURL = saveDirectoryURL() else {
            return
        }

        let date = Date()
        let counter = Preferences.nextImageCounter()
        let name = clipboardImageName(pasteboard: NSPasteboard.general)
        let context = FilenameTemplateContext(
            date: date,
            clipboardText: nil,
            clipboardName: name,
            counter: counter
        )

        let baseName = FilenameTemplate.expand(
            template: Preferences.imageFilenameTemplate,
            context: context
        )

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return
        }

        do {
            try ClipboardFileWriter.write(pngData, to: folderURL, baseName: baseName, pathExtension: "png")
        } catch {
            showFileWriteError(in: folderURL, error: error)
        }
    }

    private static func createTextFile(from text: String) {
        guard let folderURL = saveDirectoryURL() else {
            return
        }

        let date = Date()
        let counter = Preferences.nextTextCounter()
        let context = FilenameTemplateContext(
            date: date,
            clipboardText: text,
            clipboardName: nil,
            counter: counter
        )

        let baseName = FilenameTemplate.expand(
            template: Preferences.textFilenameTemplate,
            context: context
        )

        do {
            try ClipboardFileWriter.write(Data(text.utf8), to: folderURL, baseName: baseName, pathExtension: "txt")
        } catch {
            showFileWriteError(in: folderURL, error: error)
        }
    }

    private static func showAutomationPermissionAlertIfNeeded() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Allow Clip Paste to control Finder"
            alert.informativeText = """
            To save files in the current Finder folder, macOS needs permission to let Clip Paste control Finder.

            Click “Open System Settings” and then enable Clip Paste under Finder in:
            System Settings → Privacy & Security → Automation.
            """
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                } else {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                }
            }
        }
    }

    private static func showFileWriteError(in folderURL: URL, error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Cannot save file"
            alert.informativeText = """
            Clip Paste couldn’t save a file in:

            \(folderURL.path)

            \(error.localizedDescription)

            Try another save location or check this folder’s permissions.
            """
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

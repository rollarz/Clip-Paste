import AppKit
import KeyboardShortcuts
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var settingsWindowController: SettingsWindowController?
    private var onboardingWindowController: NSWindowController?
    private var statusItem: NSStatusItem?
    private var preferencesObserver: NSObjectProtocol?
    private var hasFinishedLaunchSetup = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // If a move+relaunch is in progress, stop here.
        if !MoveToApplicationsHelper.moveIfNeeded() {
            return
        }

        hasFinishedLaunchSetup = true
        applyAppearancePreferences()
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.applyAppearancePreferences()
            }
        }

        registerShortcutHandler()
        CPUpdateChecker.shared.checkOnLaunch()

        #if DEBUG
        // In Debug builds (e.g. running from Xcode), always show the welcome window
        // so it appears on every run for testing.
        showOnboarding()
        #else
        // In Release / distributed builds, only show onboarding the first time
        // for this specific installed copy of the app (bundle path–based key),
        // so cached data from other instances (e.g. Debug builds) is ignored.
        let installID = Bundle.main.bundleURL.resolvingSymlinksInPath().path
        let onboardingKey = "hasSeenOnboarding::" + installID
        if !UserDefaults.standard.bool(forKey: onboardingKey) {
            showOnboarding()
        } else {
            showSettings()
        }
        #endif
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running even when settings window is closed
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard hasFinishedLaunchSetup else { return false }
        if let window = onboardingWindowController?.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            showSettings()
        }
        return false
    }

    @objc private func showSettings() {
        if let onboarding = onboardingWindowController?.window {
            onboarding.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(rootView: SettingsView())
        }

        guard let window = settingsWindowController?.window else { return }

        applyAppearancePreferences()
        NSApp.activate(ignoringOtherApps: true)

        window.makeKeyAndOrderFront(nil)
    }

    func hideSettings() {
        applyAppearancePreferences()
    }

    private func applyAppearancePreferences() {
        let policy: NSApplication.ActivationPolicy = Preferences.hideDockIcon ? .accessory : .regular
        if NSApp.activationPolicy() != policy {
            NSApp.setActivationPolicy(policy)
        }
        if Preferences.showMenuBarIcon, statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            item.button?.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clip Paste")
            item.button?.image?.isTemplate = true
            item.button?.toolTip = "Clip Paste"
            let menu = NSMenu()
            let settings = menu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
            settings.target = self
            let updates = menu.addItem(withTitle: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: "")
            updates.target = self
            menu.addItem(.separator())
            let quit = menu.addItem(withTitle: "Quit Clip Paste", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            quit.target = NSApp
            item.menu = menu
            statusItem = item
        } else if !Preferences.showMenuBarIcon, let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    @objc private func checkForUpdates() {
        CPUpdateChecker.shared.checkNow()
    }

    private var onboardingKey: String {
        #if DEBUG
        return "hasSeenOnboardingDebug"
        #else
        return "hasSeenOnboarding::" + Bundle.main.bundleURL.resolvingSymlinksInPath().path
        #endif
    }

    private func finishOnboarding() {
        guard let controller = onboardingWindowController else { return }
        UserDefaults.standard.set(true, forKey: onboardingKey)
        onboardingWindowController = nil
        controller.close()
        showSettings()
    }

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window === onboardingWindowController?.window {
            finishOnboarding()
        }
    }

    private func registerShortcutHandler() {
        KeyboardShortcuts.onKeyDown(for: .smartPaste) {
            ClipboardHandler.handleSmartPaste()
        }
    }
    private func showOnboarding() {
        if onboardingWindowController == nil {
            let contentView = ClipPasteOnboardingView(isPresented: .init(
                get: { self.onboardingWindowController != nil },
                set: { newValue in
                    if !newValue {
                        self.finishOnboarding()
                    }
                }
            ))

            let hosting = NSHostingController(rootView: contentView)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Welcome to Clip Paste"
            window.contentViewController = hosting
            window.delegate = self

            onboardingWindowController = NSWindowController(window: window)
        }

        applyAppearancePreferences()
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindowController?.showWindow(nil)
    }
}

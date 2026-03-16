import AppKit

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private let onToggle: () -> Void
    private let onSettings: () -> Void
    private let onAddRepo: () -> Void
    private let onCheckForUpdates: () -> Void

    init(
        onToggle: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onAddRepo: @escaping () -> Void,
        onCheckForUpdates: @escaping () -> Void
    ) {
        self.onToggle = onToggle
        self.onSettings = onSettings
        self.onAddRepo = onAddRepo
        self.onCheckForUpdates = onCheckForUpdates
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bird.fill", accessibilityDescription: "OpenBird")
            button.image?.size = NSSize(width: 16, height: 16)
            button.image?.isTemplate = true
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()
        let hotkeySettings = AppSettings.shared

        let toggleItem = NSMenuItem(title: "Show/Hide Window", action: #selector(toggleAction), keyEquivalent: "")
        toggleItem.target = self
        if let shortcut = HotkeyService.menuShortcut(
            keyCode: hotkeySettings.hotkeyKeyCode,
            modifiers: hotkeySettings.hotkeyModifiers
        ) {
            toggleItem.keyEquivalent = shortcut.keyEquivalent
            toggleItem.keyEquivalentModifierMask = shortcut.modifierFlags
        }
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let addItem = NSMenuItem(title: "Add Repository...", action: #selector(addAction), keyEquivalent: "")
        addItem.target = self
        menu.addItem(addItem)

        let updatesItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdatesAction), keyEquivalent: "")
        updatesItem.target = self
        menu.addItem(updatesItem)

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(settingsAction), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit OpenBird", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func toggleAction() { onToggle() }
    @objc private func addAction() { onAddRepo() }
    @objc private func checkForUpdatesAction() { onCheckForUpdates() }
    @objc private func settingsAction() { onSettings() }
}

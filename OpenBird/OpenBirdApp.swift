import SwiftUI
import SpriteKit
import AppKit
import Combine
import UserNotifications

// MARK: - App Entry Point

@main
struct OpenBirdApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var tankWindow: TankWindow!
    private var currentScene: GameModeScene?
    private var cancellables = Set<AnyCancellable>()
    private let fishMode = FishMode()
    private let birdMode = BirdMode()
    private var settingsWindow: NSWindow?
    private var commitsWindow: NSWindow?
    private var addRepoWindow: NSWindow?
    private var scheduledRevealWorkItem: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permission for quest completion
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        // Initialize services
        CreatureLifecycleService.shared.start()
        GitMonitorService.shared.loadAndStartWatching()

        // Setup tank window
        tankWindow = TankWindow()
        installScene(modeID: AppSettings.shared.currentGameMode)

        // Setup status bar
        statusBarController = StatusBarController(
            onToggle: { [weak self] in self?.toggleTank() },
            onSettings: { [weak self] in self?.openSettings() },
            onAddRepo: { [weak self] in self?.openAddRepository() }
        )

        // Setup hotkey
        HotkeyService.shared.onToggle = { [weak self] in
            self?.toggleTank()
        }
        HotkeyService.shared.register()

        // REACTIVE: Sync scene creatures with repositories
        GitMonitorService.shared.$repositories
            .receive(on: RunLoop.main)
            .sink { [weak self] repos in
                self?.syncCreaturesWithRepos(repos)
            }
            .store(in: &cancellables)

        // Watch for feed events
        CreatureLifecycleService.shared.$lastFeedEvent
            .compactMap { $0 }
            .sink { [weak self] event in
                self?.handleFeedEvent(repoID: event.repoID, commit: event.commit)
            }
            .store(in: &cancellables)

        // Watch for creature state changes
        CreatureLifecycleService.shared.$creatures
            .sink { [weak self] creatures in
                guard let self = self, let scene = self.currentScene else { return }
                for (repoID, creature) in creatures {
                    scene.updateCreatureState(repoID, creature: creature)
                }
            }
            .store(in: &cancellables)

        // Watch for quest completions
        QuestService.shared.$lastCompletedQuest
            .compactMap { $0 }
            .sink { [weak self] quest in
                self?.handleQuestCompletion(quest)
            }
            .store(in: &cancellables)

        // SETTINGS OBSERVERS: Push changes to window/scene in real-time

        AppSettings.shared.$showCreatureNames
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let scene = self?.currentScene else { return }
                    for (_, node) in scene.creatures {
                        node.updateNameVisibility()
                    }
                }
            }
            .store(in: &cancellables)

        AppSettings.shared.$currentGameMode
            .dropFirst()
            .sink { [weak self] modeID in
                self?.installScene(modeID: modeID)
            }
            .store(in: &cancellables)

        AppSettings.shared.$followAcrossSpaces
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.tankWindow.updateSpacesBehavior()
                }
            }
            .store(in: &cancellables)

        AppSettings.shared.$movementSpeed
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let scene = self?.currentScene else { return }
                    for (_, node) in scene.creatures {
                        node.removeAction(forKey: "swimming")
                        node.removeAction(forKey: "swimLoop")
                        node.removeAction(forKey: "hovering")
                        node.removeAction(forKey: "hoverTimer")
                        node.startIdleBehavior(in: scene.size)
                    }
                }
            }
            .store(in: &cancellables)

        AppSettings.shared.$showAmbientEffects
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.currentScene?.updateAmbientEffects()
                }
            }
            .store(in: &cancellables)

        AppSettings.shared.$sceneBackgroundStyle
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.currentScene?.updateBackground()
                }
            }
            .store(in: &cancellables)

        AppSettings.shared.$showWindowBorder
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.tankWindow.updateChrome()
                }
            }
            .store(in: &cancellables)

        // Show on launch if configured
        if AppSettings.shared.showOnLaunch {
            tankWindow.toggle()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        GitMonitorService.shared.stopAll()
        CreatureLifecycleService.shared.stop()
        HotkeyService.shared.unregister()
    }

    // MARK: - Reactive Scene Sync

    private func syncCreaturesWithRepos(_ repos: [Repository], mode: (any GameMode)? = nil) {
        guard let scene = currentScene else { return }
        let activeMode = mode ?? self.activeMode()

        let repoIDs = Set(repos.map { $0.id })
        let sceneIDs = Set(scene.creatures.keys)

        for repo in repos where !sceneIDs.contains(repo.id) {
            if let creature = CreatureLifecycleService.shared.creatures[repo.id] {
                let color = NSColor.fromHex(repo.color)
                let node = activeMode.createCreatureNode(for: creature, name: repo.creatureName, color: color)
                let sceneSize = scene.size
                node.position = CGPoint(
                    x: CGFloat.random(in: 30...max(31, sceneSize.width - 30)),
                    y: CGFloat.random(in: 30...max(31, sceneSize.height - 30))
                )
                scene.addCreature(node, for: repo.id)
            }
        }

        for id in sceneIDs where !repoIDs.contains(id) {
            scene.removeCreature(for: id)
        }
    }

    private func activeMode() -> any GameMode {
        mode(for: GameModeID(rawValue: AppSettings.shared.currentGameMode) ?? .fish)
    }

    private func mode(for modeID: GameModeID) -> any GameMode {
        switch modeID {
        case .fish:
            return fishMode
        case .bird:
            return birdMode
        }
    }

    private func installScene(modeID: String) {
        let resolvedMode = GameModeID(rawValue: modeID) ?? .fish
        let mode = mode(for: resolvedMode)
        let scene = mode.createScene(size: tankWindow.skView.bounds.size)
        wireSceneCallbacks(scene)
        tankWindow.presentScene(scene)
        currentScene = scene
        syncCreaturesWithRepos(GitMonitorService.shared.repositories, mode: mode)
        scene.updateBackground()
        scene.updateAmbientEffects()

        if !tankWindow.isVisible {
            tankWindow.skView.isPaused = true
        }
    }

    private func wireSceneCallbacks(_ scene: GameModeScene) {
        scene.onRenameCreature = { [weak self] repoID, newName in
            self?.renameCreature(repoID: repoID, newName: newName)
        }
        scene.onViewCommits = { [weak self] repoID in
            self?.showCommitsForRepo(repoID)
        }
        scene.onAddRepository = { [weak self] in
            self?.openAddRepository()
        }
        scene.onOpenSettings = { [weak self] in
            self?.openSettings()
        }
        scene.onHideWindow = { [weak self] in
            self?.toggleTank()
        }
        scene.onHideWindowForHour = { [weak self] in
            self?.hideTank(for: 3600)
        }
        scene.onResetSize = { [weak self] in
            self?.tankWindow.resetToDefaultSize()
        }
    }

    // MARK: - Actions

    private func toggleTank() {
        if tankWindow.isVisible {
            cancelScheduledReveal()
        } else {
            cancelScheduledReveal()
        }
        tankWindow.toggle()
    }

    private func hideTank(for duration: TimeInterval) {
        cancelScheduledReveal()

        if tankWindow.isVisible {
            tankWindow.toggle()
        }

        let reveal = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.scheduledRevealWorkItem = nil
            if !self.tankWindow.isVisible {
                self.tankWindow.toggle()
            }
        }

        scheduledRevealWorkItem = reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: reveal)
    }

    private func cancelScheduledReveal() {
        scheduledRevealWorkItem?.cancel()
        scheduledRevealWorkItem = nil
    }

    private func openSettings() {
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create once, never destroy — avoids SwiftUI @ObservedObject teardown crash
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 450),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "OpenBird"
        window.center()
        window.minSize = NSSize(width: 500, height: 350)
        window.isReleasedWhenClosed = false  // Critical: window hides on close, never deallocated
        window.contentView = NSHostingView(rootView: SettingsView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    private func openAddRepository() {
        // Always create a fresh window (user may want different state each time)
        addRepoWindow?.close()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Add Repository"
        window.center()
        window.isReleasedWhenClosed = false

        let addView = AddRepositoryView { [weak self] repo in
            GitMonitorService.shared.addRepository(repo)
            self?.addRepoWindow?.orderOut(nil)  // Hide, don't close/destroy
        }
        window.contentView = NSHostingView(rootView: addView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        addRepoWindow = window
    }

    private func renameCreature(repoID: UUID, newName: String) {
        if let idx = GitMonitorService.shared.repositories.firstIndex(where: { $0.id == repoID }) {
            GitMonitorService.shared.repositories[idx].creatureName = newName
            PersistenceService.shared.saveRepositories(GitMonitorService.shared.repositories)
        }
        currentScene?.creatures[repoID]?.updateName(newName)
    }

    private func showCommitsForRepo(_ repoID: UUID) {
        guard let repo = GitMonitorService.shared.repositories.first(where: { $0.id == repoID }) else { return }

        commitsWindow?.orderOut(nil)  // Hide previous if open

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(repo.creatureName) - Commits"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ActivityLogView(repo: repo))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        commitsWindow = window
    }

    private func handleFeedEvent(repoID: UUID, commit: CommitRecord) {
        currentScene?.triggerFeedAnimation(for: repoID, commit: commit)

        if AppSettings.shared.enableSounds {
            NSSound(named: "Pop")?.play()
        }
    }

    private func handleQuestCompletion(_ quest: Quest) {
        // Show in SpriteKit scene
        if let scene = currentScene {
            let banner = SKLabelNode(text: "Quest Complete: \(quest.title)")
            banner.fontSize = 13
            banner.fontName = "Menlo-Bold"
            banner.fontColor = NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.5, alpha: 1.0)
            banner.position = CGPoint(x: scene.size.width / 2, y: scene.size.height - 20)
            banner.alpha = 0
            banner.zPosition = 100
            scene.addChild(banner)

            banner.run(SKAction.sequence([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.wait(forDuration: 3.0),
                SKAction.fadeOut(withDuration: 0.5),
                .removeFromParent()
            ]))
        }

        // System notification
        let content = UNMutableNotificationContent()
        content.title = "Quest Complete"
        content.body = "\(quest.title) - \(quest.rewardDescription)"
        content.sound = .default
        let request = UNNotificationRequest(identifier: "quest-\(quest.id)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Status Bar Controller

final class StatusBarController {
    private var statusItem: NSStatusItem?
    private let onToggle: () -> Void
    private let onSettings: () -> Void
    private let onAddRepo: () -> Void

    init(onToggle: @escaping () -> Void, onSettings: @escaping () -> Void, onAddRepo: @escaping () -> Void) {
        self.onToggle = onToggle
        self.onSettings = onSettings
        self.onAddRepo = onAddRepo
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

        let toggleItem = NSMenuItem(title: "Show/Hide Window", action: #selector(toggleAction), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let addItem = NSMenuItem(title: "Add Repository...", action: #selector(addAction), keyEquivalent: "")
        addItem.target = self
        menu.addItem(addItem)

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(settingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit OpenBird", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func toggleAction() { onToggle() }
    @objc private func addAction() { onAddRepo() }
    @objc private func settingsAction() { onSettings() }
}

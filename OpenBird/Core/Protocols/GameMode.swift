import SpriteKit
import AppKit

enum GameModeID: String, CaseIterable, Identifiable {
    case fish
    case bird
    case jam

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fish:
            return "Aquarium"
        case .bird:
            return "Bird View"
        case .jam:
            return "Jam Mode"
        }
    }

    var iconName: String {
        switch self {
        case .fish:
            return "water.waves"
        case .bird:
            return "bird"
        case .jam:
            return "waveform"
        }
    }
}

// MARK: - GameMode Protocol

protocol GameMode {
    var id: String { get }
    var displayName: String { get }

    func createScene(size: CGSize) -> GameModeScene
    func createCreatureNode(for creature: Creature, name: String, color: NSColor) -> CreatureNode
}

// MARK: - Base Scene

class GameModeScene: SKScene {
    var creatures: [UUID: CreatureNode] = [:]
    var selectedCreatureID: UUID?
    private(set) var isJamModeActive = false

    // Callbacks for context menu actions
    var onRenameCreature: ((UUID, String) -> Void)?
    var onViewCommits: ((UUID) -> Void)?
    var onAddRepository: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onHideWindow: (() -> Void)?
    var onHideWindowForHour: (() -> Void)?
    var onResetSize: (() -> Void)?

    func addCreature(_ node: CreatureNode, for repoID: UUID) {
        creatures[repoID] = node
        addChild(node)
        if isJamModeActive {
            node.beginJamMode()
        } else {
            node.startIdleBehavior(in: size)
        }
    }

    func removeCreature(for repoID: UUID) {
        if selectedCreatureID == repoID {
            selectedCreatureID = nil
        }
        if let creature = creatures[repoID] {
            releaseMovementReservation(for: creature)
        }
        creatures[repoID]?.removeAllActions()
        creatures[repoID]?.removeFromParent()
        creatures[repoID] = nil
    }

    func triggerFeedAnimation(for repoID: UUID, commit: CommitRecord) {
        guard let creature = creatures[repoID] else { return }

        // Spawn food at top, falling toward creature
        let food = SKShapeNode(circleOfRadius: 4)
        food.fillColor = .orange
        food.strokeColor = NSColor(white: 1.0, alpha: 0.5)
        food.lineWidth = 0.5
        food.position = CGPoint(
            x: creature.position.x + CGFloat.random(in: -20...20),
            y: size.height
        )
        addChild(food)

        let fall = SKAction.moveTo(y: creature.position.y + 10, duration: 0.8)
        fall.timingMode = .easeIn
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        food.run(SKAction.sequence([fall, fadeOut, .removeFromParent()]))

        creature.playCommitAnimation()
        spawnCommitReward(at: creature.position)
        showCommitLabel(for: commit, at: creature.position, prefix: "Commit!")
    }

    func updateCreatureState(_ repoID: UUID, creature: Creature) {
        creatures[repoID]?.updateAppearance(creature)
    }

    func updateAmbientEffects() {}

    func updateBackground() {}

    func releaseMovementReservation(for node: CreatureNode) {}

    func spawnCommitReward(at point: CGPoint) {
        let rewardNode = SKNode()
        rewardNode.position = point
        rewardNode.zPosition = 8
        addChild(rewardNode)

        let glow = SKShapeNode(circleOfRadius: 12)
        glow.fillColor = NSColor(calibratedRed: 1.0, green: 0.87, blue: 0.34, alpha: 0.28)
        glow.strokeColor = .clear
        rewardNode.addChild(glow)
        glow.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 3.8, duration: 0.42),
                SKAction.fadeOut(withDuration: 0.42)
            ]),
            .removeFromParent()
        ]))

        let ring = SKShapeNode(circleOfRadius: 14)
        ring.fillColor = .clear
        ring.strokeColor = NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.72, alpha: 0.9)
        ring.lineWidth = 1.8
        rewardNode.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.35, duration: 0.38),
                SKAction.fadeOut(withDuration: 0.38)
            ]),
            .removeFromParent()
        ]))

        let sparkleAngles = stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 3).map { CGFloat($0) }
        for (index, angle) in sparkleAngles.enumerated() {
            let sparkle = SKShapeNode(rectOf: CGSize(width: 3, height: 14), cornerRadius: 1.5)
            sparkle.fillColor = NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.7, alpha: 0.96)
            sparkle.strokeColor = .clear
            sparkle.zRotation = angle
            rewardNode.addChild(sparkle)

            let dx = cos(angle) * 18
            let dy = sin(angle) * 18 + 4
            sparkle.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(index) * 0.015),
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.3),
                    SKAction.scaleY(to: 0.15, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                .removeFromParent()
            ]))
        }

        rewardNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            .removeFromParent()
        ]))
    }

    func showCommitLabel(for commit: CommitRecord, at point: CGPoint, prefix: String) {
        let label = SKLabelNode(text: "\(prefix) \(String(commit.message.prefix(34)))")
        label.fontSize = 10
        label.fontColor = NSColor(calibratedRed: 1.0, green: 0.96, blue: 0.82, alpha: 0.98)
        label.fontName = "Menlo-Bold"
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: point.x, y: point.y + 32)
        label.alpha = 0
        label.zPosition = 9
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.16),
                SKAction.moveBy(x: 0, y: 10, duration: 0.16),
                SKAction.scale(to: 1.08, duration: 0.16)
            ]),
            SKAction.wait(forDuration: 2.0),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.42),
                SKAction.moveBy(x: 0, y: 6, duration: 0.42)
            ]),
            .removeFromParent()
        ]))
    }

    func setJamModeActive(_ active: Bool) {
        guard active != isJamModeActive else { return }
        isJamModeActive = active

        for (_, node) in creatures {
            if active {
                node.beginJamMode()
            } else {
                node.endJamMode(resumeIn: size)
            }
        }
    }

    func updateJamMode(level: CGFloat, beat: CGFloat) {
        guard isJamModeActive else { return }
        for (_, node) in creatures {
            node.updateJam(level: level, beat: beat)
        }
    }

    func selectCreature(_ repoID: UUID?) {
        // Deselect previous
        if let prev = selectedCreatureID, let node = creatures[prev] {
            node.setSelected(false)
        }
        selectedCreatureID = repoID
        if let id = repoID, let node = creatures[id] {
            node.setSelected(true)
        }
    }

    // MARK: - Mouse Handling

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        if let hit = creatureAt(location) {
            if event.clickCount == 2 {
                // Double-click on friend opens commits
                onViewCommits?(hit)
            } else {
                selectCreature(hit)
            }
        } else {
            selectCreature(nil)
            if event.clickCount == 1 && !creatures.isEmpty {
                // Single click on empty space drops food
                dropFood(at: location)
            }
        }
    }

    func dropFood(at point: CGPoint) {
        // Spawn food particle
        let food = SKShapeNode(circleOfRadius: 4)
        food.fillColor = .orange
        food.strokeColor = NSColor(white: 1.0, alpha: 0.5)
        food.lineWidth = 0.5
        food.position = point
        food.zPosition = 5
        food.name = "droppedFood"
        addChild(food)

        // Food sinks slowly
        let sink = SKAction.moveBy(x: 0, y: -50, duration: 5.0)
        sink.timingMode = .easeIn
        let fade = SKAction.fadeOut(withDuration: 1.0)
        food.run(SKAction.sequence([sink, fade, .removeFromParent()]))

        // Find nearest alive fish and send it to eat
        var nearestID: UUID?
        var nearestDist: CGFloat = .infinity
        for (repoID, node) in creatures {
            guard node.creatureState.isAlive else { continue }
            let dx = node.position.x - point.x
            let dy = node.position.y - point.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist < nearestDist {
                nearestDist = dist
                nearestID = repoID
            }
        }

        if let targetID = nearestID, let fishNode = creatures[targetID] {
            fishNode.swimToFood(at: point, food: food)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let screenPoint = event.locationInWindow

        if let repoID = creatureAt(location) {
            selectCreature(repoID)
            showCreatureContextMenu(repoID: repoID, at: screenPoint)
        } else {
            showBackgroundContextMenu(at: screenPoint)
        }
    }

    private func creatureAt(_ point: CGPoint) -> UUID? {
        let hitArea: CGFloat = 25
        for (repoID, node) in creatures {
            let dx = abs(node.position.x - point.x)
            let dy = abs(node.position.y - point.y)
            let hitSize = hitArea * CGFloat(node.creatureState.size)
            if dx < hitSize && dy < hitSize {
                return repoID
            }
        }
        return nil
    }

    private func showCreatureContextMenu(repoID: UUID, at point: NSPoint) {
        guard let view = self.view else { return }

        let menu = NSMenu()

        // Creature name header
        if let node = creatures[repoID] {
            let header = NSMenuItem(title: node.creatureName, action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
            menu.addItem(NSMenuItem.separator())
        }

        let renameItem = NSMenuItem(title: "Rename...", action: #selector(MenuActions.renameAction(_:)), keyEquivalent: "")
        renameItem.representedObject = repoID
        renameItem.target = menuHandler
        menu.addItem(renameItem)

        let commitsItem = NSMenuItem(title: "View Commits", action: #selector(MenuActions.viewCommitsAction(_:)), keyEquivalent: "")
        commitsItem.representedObject = repoID
        commitsItem.target = menuHandler
        menu.addItem(commitsItem)

        menu.addItem(NSMenuItem.separator())

        let hideForHourItem = NSMenuItem(title: "Hide for 1 Hour", action: #selector(MenuActions.hideForHourAction), keyEquivalent: "")
        hideForHourItem.target = menuHandler
        menu.addItem(hideForHourItem)

        // Convert point for menu positioning
        let viewPoint = view.convert(point, from: nil)
        menu.popUp(positioning: nil, at: viewPoint, in: view)
    }

    private func showBackgroundContextMenu(at point: NSPoint) {
        guard let view = self.view else { return }

        let menu = NSMenu()

        let addItem = NSMenuItem(title: "Add Repository...", action: #selector(MenuActions.addRepoAction), keyEquivalent: "")
        addItem.target = menuHandler
        menu.addItem(addItem)

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(MenuActions.settingsAction), keyEquivalent: "")
        settingsItem.target = menuHandler
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let defaultSizeItem = NSMenuItem(title: "Default Size", action: #selector(MenuActions.resetSizeAction), keyEquivalent: "")
        defaultSizeItem.target = menuHandler
        menu.addItem(defaultSizeItem)

        let hideItem = NSMenuItem(title: "Hide Window", action: #selector(MenuActions.hideAction), keyEquivalent: "")
        hideItem.target = menuHandler
        menu.addItem(hideItem)

        let hideForHourItem = NSMenuItem(title: "Hide for 1 Hour", action: #selector(MenuActions.hideForHourAction), keyEquivalent: "")
        hideForHourItem.target = menuHandler
        menu.addItem(hideForHourItem)

        let viewPoint = view.convert(point, from: nil)
        menu.popUp(positioning: nil, at: viewPoint, in: view)
    }

    // Menu action handler (needed for NSMenu target)
    lazy var menuHandler: MenuActions = MenuActions(scene: self)
}

// MARK: - Menu Actions Handler

class MenuActions: NSObject {
    weak var scene: GameModeScene?

    init(scene: GameModeScene) {
        self.scene = scene
    }

    @objc func renameAction(_ sender: NSMenuItem) {
        guard let repoID = sender.representedObject as? UUID else { return }

        let alert = NSAlert()
        alert.messageText = "Rename Friend"
        alert.informativeText = "Enter a new name:"
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        if let node = scene?.creatures[repoID] {
            input.stringValue = node.creatureName
        }
        alert.accessoryView = input

        if alert.runModal() == .alertFirstButtonReturn {
            let newName = input.stringValue.trimmingCharacters(in: .whitespaces)
            if !newName.isEmpty {
                scene?.onRenameCreature?(repoID, newName)
            }
        }
    }

    @objc func viewCommitsAction(_ sender: NSMenuItem) {
        guard let repoID = sender.representedObject as? UUID else { return }
        scene?.onViewCommits?(repoID)
    }

    @objc func addRepoAction() {
        scene?.onAddRepository?()
    }

    @objc func settingsAction() {
        scene?.onOpenSettings?()
    }

    @objc func resetSizeAction() {
        scene?.onResetSize?()
    }

    @objc func hideAction() {
        scene?.onHideWindow?()
    }

    @objc func hideForHourAction() {
        scene?.onHideWindowForHour?()
    }
}

// MARK: - Base Creature Node

class CreatureNode: SKSpriteNode {
    var creatureState: Creature
    var creatureName: String
    var baseColor: NSColor
    private var selectionOutline: SKShapeNode?

    init(creature: Creature, name: String, color: NSColor, texture: SKTexture?, size: CGSize) {
        self.creatureState = creature
        self.creatureName = name
        self.baseColor = color
        super.init(texture: texture, color: .clear, size: size)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func startIdleBehavior(in sceneSize: CGSize) {}
    func playFeedAnimation() {}
    func playCommitAnimation() {
        playFeedAnimation()
    }
    func beginJamMode() {}
    func endJamMode(resumeIn sceneSize: CGSize) {
        startIdleBehavior(in: sceneSize)
    }
    func updateJam(level: CGFloat, beat: CGFloat) {}

    func updateAppearance(_ creature: Creature) {
        self.creatureState = creature
    }

    func setSelected(_ selected: Bool) {
        if selected {
            updateSelectionOutline()
        } else {
            selectionOutline?.removeFromParent()
            selectionOutline = nil
        }
    }

    func updateSelectionOutline() {
        selectionOutline?.removeFromParent()

        let scale = CGFloat(creatureState.size)
        let outlineSize = CGSize(width: 52 * scale, height: 34 * scale)
        let outline = SKShapeNode(ellipseOf: outlineSize)
        outline.strokeColor = NSColor(white: 1.0, alpha: 0.8)
        outline.lineWidth = 1.5
        outline.fillColor = .clear
        outline.glowWidth = 2
        outline.zPosition = 10
        outline.name = "selectionOutline"
        // Counteract parent scaling so outline stays round
        outline.xScale = 1.0 / abs(xScale == 0 ? 1 : xScale)
        outline.yScale = 1.0 / abs(yScale == 0 ? 1 : yScale)
        addChild(outline)
        selectionOutline = outline
    }

    func updateName(_ newName: String) {
        creatureName = newName
    }

    func updateNameVisibility() {
        // Override in subclasses when names are rendered.
    }

    func swimToFood(at point: CGPoint, food: SKNode) {
        // Override in subclasses for specific behavior
    }

    func swimTowardPoint(_ target: CGPoint) {
        // Override in subclasses for schooling behavior
    }
}

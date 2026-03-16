import SpriteKit
import AppKit

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

    // Callbacks for context menu actions
    var onRenameCreature: ((UUID, String) -> Void)?
    var onViewCommits: ((UUID) -> Void)?
    var onAddRepository: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onHideWindow: (() -> Void)?
    var onResetSize: (() -> Void)?

    func addCreature(_ node: CreatureNode, for repoID: UUID) {
        creatures[repoID] = node
        addChild(node)
        node.startIdleBehavior(in: size)
    }

    func removeCreature(for repoID: UUID) {
        if selectedCreatureID == repoID {
            selectedCreatureID = nil
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

        // Creature reacts
        creature.playFeedAnimation()

        // Show commit message briefly
        let label = SKLabelNode(text: String(commit.message.prefix(40)))
        label.fontSize = 10
        label.fontColor = .white
        label.fontName = "Menlo"
        label.position = CGPoint(x: creature.position.x, y: creature.position.y + 30)
        label.alpha = 0
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5),
            .removeFromParent()
        ]))
    }

    func updateCreatureState(_ repoID: UUID, creature: Creature) {
        creatures[repoID]?.updateAppearance(creature)
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

    func swimToFood(at point: CGPoint, food: SKNode) {
        // Override in subclasses for specific behavior
    }

    func swimTowardPoint(_ target: CGPoint) {
        // Override in subclasses for schooling behavior
    }
}

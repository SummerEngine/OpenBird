import SpriteKit

final class FishScene: GameModeScene {
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        setupAmbience()
        startSchoolingCheck()

        // Enable mouse events
        view.window?.acceptsMouseMovedEvents = true
        isUserInteractionEnabled = true
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Reposition creatures, update scale, and restart movement with fresh bounds
        for (_, creature) in creatures {
            creature.position = constrainToScene(creature.position)
            creature.updateAppearance(creature.creatureState)
            creature.removeAction(forKey: "swimming")
            creature.removeAction(forKey: "swimLoop")
            creature.removeAction(forKey: "hovering")
            creature.removeAction(forKey: "hoverTimer")
            if isJamModeActive {
                creature.beginJamMode()
            } else {
                creature.startIdleBehavior(in: size)
            }
        }
        // Reposition backdrop
        childNode(withName: "backdrop")?.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func setupAmbience() {
        updateBackground()

        updateAmbientEffects()
    }

    override func updateBackground() {
        childNode(withName: "backdrop")?.removeFromParent()

        let style = AppSettings.shared.sceneBackgroundStyle
        guard style != "clear" else { return }

        let backdrop = SKShapeNode(rectOf: CGSize(width: 4000, height: 4000), cornerRadius: 8)
        switch style {
        case "night":
            backdrop.fillColor = NSColor(calibratedRed: 0.01, green: 0.03, blue: 0.08, alpha: 0.34)
        default:
            backdrop.fillColor = NSColor(calibratedRed: 0.02, green: 0.08, blue: 0.16, alpha: 0.15)
        }
        backdrop.strokeColor = .clear
        backdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backdrop.zPosition = -10
        backdrop.name = "backdrop"
        addChild(backdrop)
    }

    override func updateAmbientEffects() {
        if AppSettings.shared.showAmbientEffects {
            // Only start if not already running
            if action(forKey: "bubbleSpawner") == nil {
                spawnBubbles()
            }
        } else {
            removeAction(forKey: "bubbleSpawner")
            // Remove existing bubbles
            children.filter { $0.name == "bubble" }.forEach { $0.removeFromParent() }
        }
    }

    private func spawnBubbles() {
        let spawnAction = SKAction.run { [weak self] in
            self?.createBubble()
        }
        let wait = SKAction.wait(forDuration: 4.2, withRange: 3.0)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, wait])), withKey: "bubbleSpawner")
    }

    private func createBubble() {
        let radius = CGFloat.random(in: 1.5...4)
        let bubble = SKShapeNode(circleOfRadius: radius)
        bubble.fillColor = NSColor(white: 1.0, alpha: 0.08)
        bubble.strokeColor = NSColor(white: 1.0, alpha: 0.12)
        bubble.lineWidth = 0.5
        bubble.position = CGPoint(
            x: CGFloat.random(in: 0...size.width),
            y: -5
        )
        bubble.zPosition = -5
        bubble.name = "bubble"
        addChild(bubble)

        let wobbleX = CGFloat.random(in: -30...30)
        let duration = Double.random(in: 5...10)
        let rise = SKAction.moveBy(x: wobbleX, y: size.height + 20, duration: duration)
        rise.timingMode = .easeIn
        let fade = SKAction.fadeOut(withDuration: 1.0)
        bubble.run(SKAction.sequence([rise, fade, .removeFromParent()]))
    }

    func constrainToScene(_ point: CGPoint) -> CGPoint {
        let margin: CGFloat = 30
        return CGPoint(
            x: max(margin, min(size.width - margin, point.x)),
            y: max(margin, min(size.height - margin, point.y))
        )
    }

    // MARK: - Fish Schooling

    private func startSchoolingCheck() {
        let check = SKAction.run { [weak self] in
            self?.checkInteractions()
        }
        let wait = SKAction.wait(forDuration: 3.0)
        run(SKAction.repeatForever(SKAction.sequence([wait, check])), withKey: "schoolingCheck")
    }

    private func checkInteractions() {
        let aliveCreatures = creatures.filter { $0.value.creatureState.isAlive }
        guard aliveCreatures.count >= 2 else { return }

        let entries = Array(aliveCreatures)
        for i in 0..<entries.count {
            for j in (i + 1)..<entries.count {
                let nodeA = entries[i].value
                let nodeB = entries[j].value

                let dx = nodeA.position.x - nodeB.position.x
                let dy = nodeA.position.y - nodeB.position.y
                let dist = sqrt(dx * dx + dy * dy)

                if dist < 60 && Double.random(in: 0...1) < 0.15 {
                    // One fish swims toward the other briefly
                    let target = CGPoint(
                        x: nodeB.position.x + CGFloat.random(in: -20...20),
                        y: nodeB.position.y + CGFloat.random(in: -20...20)
                    )
                    nodeA.swimTowardPoint(target)
                    break // Only one interaction per check
                }
            }
        }
    }
}

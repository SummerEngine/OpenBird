import SpriteKit

final class BirdScene: GameModeScene {
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        updateBackground()
        updateAmbientEffects()
        view.window?.acceptsMouseMovedEvents = true
        isUserInteractionEnabled = true
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        for (_, creature) in creatures {
            creature.position = constrainToScene(creature.position)
            creature.updateAppearance(creature.creatureState)
            creature.removeAction(forKey: "swimming")
            creature.removeAction(forKey: "swimLoop")
            creature.removeAction(forKey: "hovering")
            creature.removeAction(forKey: "hoverTimer")
            creature.startIdleBehavior(in: size)
        }

        updateBackground()
    }

    override func updateBackground() {
        childNode(withName: "backdrop")?.removeFromParent()
        childNode(withName: "sunDisc")?.removeFromParent()
        childNode(withName: "perches")?.removeFromParent()

        let style = AppSettings.shared.sceneBackgroundStyle
        guard style != "clear" else { return }

        let backdrop = SKShapeNode(rectOf: CGSize(width: 4000, height: 4000), cornerRadius: 8)
        switch style {
        case "night":
            backdrop.fillColor = NSColor(calibratedRed: 0.08, green: 0.06, blue: 0.12, alpha: 0.24)
        default:
            backdrop.fillColor = NSColor(calibratedRed: 0.55, green: 0.78, blue: 0.96, alpha: 0.14)
        }
        backdrop.strokeColor = .clear
        backdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backdrop.zPosition = -12
        backdrop.name = "backdrop"
        addChild(backdrop)

        let sun = SKShapeNode(circleOfRadius: style == "night" ? 18 : 24)
        sun.fillColor = style == "night"
            ? NSColor(calibratedRed: 0.96, green: 0.9, blue: 0.72, alpha: 0.16)
            : NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.72, alpha: 0.2)
        sun.strokeColor = .clear
        sun.position = CGPoint(x: size.width - 48, y: size.height - 40)
        sun.zPosition = -11
        sun.name = "sunDisc"
        addChild(sun)

        let perchGroup = SKNode()
        perchGroup.name = "perches"
        perchGroup.zPosition = -4

        let yLevels: [CGFloat] = [0.24, 0.48, 0.72]
        let widths: [CGFloat] = [0.42, 0.36, 0.3]
        let offsets: [CGFloat] = [0.28, 0.68, 0.45]

        for index in 0..<yLevels.count {
            let width = max(80, size.width * widths[index])
            let branch = SKShapeNode(rectOf: CGSize(width: width, height: 4), cornerRadius: 2)
            branch.fillColor = style == "night"
                ? NSColor(calibratedRed: 0.36, green: 0.26, blue: 0.22, alpha: 0.42)
                : NSColor(calibratedRed: 0.45, green: 0.31, blue: 0.18, alpha: 0.32)
            branch.strokeColor = .clear
            branch.position = CGPoint(x: size.width * offsets[index], y: size.height * yLevels[index])
            perchGroup.addChild(branch)
        }

        addChild(perchGroup)
    }

    override func updateAmbientEffects() {
        if AppSettings.shared.showAmbientEffects {
            if action(forKey: "breezeSpawner") == nil {
                spawnBreeze()
            }
        } else {
            removeAction(forKey: "breezeSpawner")
            children.filter { $0.name == "breeze" }.forEach { $0.removeFromParent() }
        }
    }

    func constrainToScene(_ point: CGPoint) -> CGPoint {
        let margin: CGFloat = 32
        return CGPoint(
            x: max(margin, min(size.width - margin, point.x)),
            y: max(margin, min(size.height - margin, point.y))
        )
    }

    private func spawnBreeze() {
        let spawn = SKAction.run { [weak self] in
            self?.createBreeze()
        }
        let wait = SKAction.wait(forDuration: 5.2, withRange: 2.6)
        run(SKAction.repeatForever(SKAction.sequence([spawn, wait])), withKey: "breezeSpawner")
    }

    private func createBreeze() {
        let length = CGFloat.random(in: 18...42)
        let breeze = SKShapeNode(rectOf: CGSize(width: length, height: 1.5), cornerRadius: 0.75)
        breeze.fillColor = NSColor(white: 1.0, alpha: 0.14)
        breeze.strokeColor = .clear
        breeze.position = CGPoint(
            x: -length,
            y: CGFloat.random(in: max(32, size.height * 0.25)...max(40, size.height - 28))
        )
        breeze.zPosition = -6
        breeze.alpha = 0
        breeze.name = "breeze"
        addChild(breeze)

        let move = SKAction.moveBy(x: size.width + length * 2, y: CGFloat.random(in: -8...8), duration: Double.random(in: 6...9))
        move.timingMode = .easeInEaseOut
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)

        breeze.run(SKAction.sequence([
            fadeIn,
            move,
            fadeOut,
            .removeFromParent()
        ]))
    }
}

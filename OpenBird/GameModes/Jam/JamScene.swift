import SpriteKit

final class JamScene: GameModeScene {
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        updateBackground()
        updateAmbientEffects()
        startAudioSyncLoop()
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
            creature.startIdleBehavior(in: size)
        }

        updateBackground()
    }

    override func updateBackground() {
        ["backdrop", "floor", "spotlights"].forEach { childNode(withName: $0)?.removeFromParent() }

        let style = AppSettings.shared.sceneBackgroundStyle
        guard style != "clear" else { return }

        let backdrop = SKShapeNode(rectOf: CGSize(width: 4000, height: 4000), cornerRadius: 8)
        backdrop.strokeColor = .clear
        backdrop.fillColor = style == "night"
            ? NSColor(calibratedRed: 0.04, green: 0.02, blue: 0.08, alpha: 0.3)
            : NSColor(calibratedRed: 0.08, green: 0.03, blue: 0.12, alpha: 0.18)
        backdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backdrop.zPosition = -16
        backdrop.name = "backdrop"
        addChild(backdrop)

        let spotlightLayer = SKNode()
        spotlightLayer.name = "spotlights"
        spotlightLayer.zPosition = -12

        let colors: [NSColor] = style == "night"
            ? [
                NSColor(calibratedRed: 0.18, green: 0.68, blue: 1.0, alpha: 0.14),
                NSColor(calibratedRed: 0.95, green: 0.18, blue: 0.86, alpha: 0.12)
            ]
            : [
                NSColor(calibratedRed: 0.18, green: 0.98, blue: 0.88, alpha: 0.18),
                NSColor(calibratedRed: 0.98, green: 0.18, blue: 0.82, alpha: 0.14)
            ]

        let spotlightCenters = [
            CGPoint(x: size.width * 0.24, y: size.height * 0.78),
            CGPoint(x: size.width * 0.76, y: size.height * 0.74)
        ]

        for (index, center) in spotlightCenters.enumerated() {
            let light = SKShapeNode(ellipseOf: CGSize(width: size.width * 0.42, height: size.height * 0.7))
            light.fillColor = colors[index]
            light.strokeColor = .clear
            light.position = center
            light.zRotation = index == 0 ? -0.3 : 0.3
            spotlightLayer.addChild(light)
        }
        addChild(spotlightLayer)

        let floor = SKShapeNode(rectOf: CGSize(width: size.width + 120, height: 70), cornerRadius: 24)
        floor.fillColor = style == "night"
            ? NSColor(calibratedRed: 0.12, green: 0.05, blue: 0.18, alpha: 0.72)
            : NSColor(calibratedRed: 0.16, green: 0.07, blue: 0.22, alpha: 0.54)
        floor.strokeColor = NSColor(white: 1.0, alpha: 0.08)
        floor.lineWidth = 1
        floor.position = CGPoint(x: size.width / 2, y: 26)
        floor.zPosition = -8
        floor.name = "floor"
        addChild(floor)
    }

    override func updateAmbientEffects() {
        if AppSettings.shared.showAmbientEffects {
            if action(forKey: "lightTrailSpawner") == nil {
                spawnLightTrails()
            }
        } else {
            removeAction(forKey: "lightTrailSpawner")
            children.filter { $0.name == "lightTrail" }.forEach { $0.removeFromParent() }
        }
    }

    override func triggerFeedAnimation(for repoID: UUID, commit: CommitRecord) {
        guard let creature = creatures[repoID] else { return }

        let burst = SKShapeNode(circleOfRadius: 16)
        burst.fillColor = NSColor(calibratedRed: 0.98, green: 0.22, blue: 0.84, alpha: 0.22)
        burst.strokeColor = NSColor(calibratedRed: 0.22, green: 0.98, blue: 0.86, alpha: 0.74)
        burst.lineWidth = 1.5
        burst.position = creature.position
        burst.zPosition = 12
        addChild(burst)
        burst.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 3.8, duration: 0.42),
                SKAction.fadeOut(withDuration: 0.42)
            ]),
            .removeFromParent()
        ]))

        let label = SKLabelNode(text: "Drop: \(String(commit.message.prefix(32)))")
        label.fontName = "Menlo-Bold"
        label.fontSize = 10
        label.fontColor = .white
        label.alpha = 0
        label.position = CGPoint(x: creature.position.x, y: creature.position.y + 42)
        label.zPosition = 13
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.18),
                SKAction.moveBy(x: 0, y: 12, duration: 0.18)
            ]),
            SKAction.wait(forDuration: 1.8),
            SKAction.fadeOut(withDuration: 0.4),
            .removeFromParent()
        ]))

        creature.playFeedAnimation()
    }

    private func startAudioSyncLoop() {
        let update = SKAction.run { [weak self] in
            self?.applyAudioResponse()
        }
        let wait = SKAction.wait(forDuration: 0.05)
        run(SKAction.repeatForever(SKAction.sequence([update, wait])), withKey: "audioSync")
    }

    private func applyAudioResponse() {
        let monitor = SystemAudioMonitorService.shared
        let level = CGFloat(monitor.audioLevel)
        let beat = CGFloat(monitor.beatStrength)

        if let floor = childNode(withName: "floor") as? SKShapeNode {
            floor.fillColor = floor.fillColor.withAlphaComponent(0.4 + level * 0.2 + beat * 0.18)
            floor.glowWidth = beat * 8
        }

        if let spotlights = childNode(withName: "spotlights") {
            spotlights.alpha = 0.75 + level * 0.2 + beat * 0.25
            let scale = 1 + beat * 0.08
            spotlights.xScale = scale
            spotlights.yScale = 1 + level * 0.06
        }

        for (_, node) in creatures {
            (node as? JamCreatureNode)?.setAudioResponse(level: level, beat: beat)
        }
    }

    private func spawnLightTrails() {
        let spawn = SKAction.run { [weak self] in
            self?.createLightTrail()
        }
        let wait = SKAction.wait(forDuration: 1.6, withRange: 1.1)
        run(SKAction.repeatForever(SKAction.sequence([spawn, wait])), withKey: "lightTrailSpawner")
    }

    private func createLightTrail() {
        let width = CGFloat.random(in: 40...84)
        let trail = SKShapeNode(rectOf: CGSize(width: width, height: 2), cornerRadius: 1)
        trail.fillColor = [
            NSColor(calibratedRed: 0.18, green: 0.98, blue: 0.88, alpha: 0.22),
            NSColor(calibratedRed: 0.98, green: 0.2, blue: 0.82, alpha: 0.18),
            NSColor(calibratedRed: 0.46, green: 0.68, blue: 1.0, alpha: 0.18)
        ].randomElement() ?? .white
        trail.strokeColor = .clear
        trail.position = CGPoint(
            x: -width,
            y: CGFloat.random(in: size.height * 0.24...max(size.height * 0.25, size.height - 20))
        )
        trail.alpha = 0
        trail.zPosition = -9
        trail.name = "lightTrail"
        addChild(trail)

        let travel = SKAction.moveBy(
            x: size.width + width * 2,
            y: CGFloat.random(in: -16...16),
            duration: Double.random(in: 2.6...4.4)
        )
        travel.timingMode = .easeInEaseOut

        trail.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.25),
            travel,
            SKAction.fadeOut(withDuration: 0.45),
            .removeFromParent()
        ]))
    }

    private func constrainToScene(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: max(40, min(size.width - 40, point.x)),
            y: max(70, min(size.height - 34, point.y))
        )
    }
}

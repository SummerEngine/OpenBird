import SpriteKit

struct BirdPerchSegment {
    let xRange: ClosedRange<CGFloat>
    let y: CGFloat
}

final class BirdScene: GameModeScene {
    private(set) var perchSegments: [BirdPerchSegment] = []

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
            if isJamModeActive {
                creature.beginJamMode()
            } else {
                creature.startIdleBehavior(in: size)
            }
        }

        updateBackground()
    }

    override func updateBackground() {
        childNode(withName: "backdrop")?.removeFromParent()
        childNode(withName: "clouds")?.removeFromParent()
        childNode(withName: "tree")?.removeFromParent()
        perchSegments.removeAll()

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

        let cloudLayer = SKNode()
        cloudLayer.name = "clouds"
        cloudLayer.zPosition = -11

        let cloudConfigs: [(CGPoint, CGFloat)] = [
            (CGPoint(x: size.width * 0.7, y: size.height * 0.84), 0.9),
            (CGPoint(x: size.width * 0.46, y: size.height * 0.7), 0.7)
        ]
        let cloudAlpha: CGFloat = style == "night" ? 0.12 : 0.22
        for (center, scale) in cloudConfigs {
            let cloud = makeCloud(center: center, scale: scale, alpha: cloudAlpha)
            cloudLayer.addChild(cloud)
        }
        addChild(cloudLayer)

        let tree = SKNode()
        tree.name = "tree"
        tree.zPosition = -4

        let trunkWidth = max(24, size.width * 0.075)
        let trunkHeight = max(120, size.height * 0.8)
        let trunkX = max(30, size.width * 0.16)
        let trunk = SKShapeNode(rectOf: CGSize(width: trunkWidth, height: trunkHeight), cornerRadius: trunkWidth / 2)
        trunk.fillColor = style == "night"
            ? NSColor(calibratedRed: 0.24, green: 0.16, blue: 0.12, alpha: 0.72)
            : NSColor(calibratedRed: 0.42, green: 0.28, blue: 0.18, alpha: 0.6)
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: trunkX, y: trunkHeight / 2 - 10)
        tree.addChild(trunk)

        let canopyColor = style == "night"
            ? NSColor(calibratedRed: 0.2, green: 0.34, blue: 0.24, alpha: 0.28)
            : NSColor(calibratedRed: 0.42, green: 0.68, blue: 0.36, alpha: 0.24)
        let canopyCenters = [
            CGPoint(x: trunkX + size.width * 0.14, y: size.height * 0.78),
            CGPoint(x: trunkX + size.width * 0.03, y: size.height * 0.66),
            CGPoint(x: trunkX + size.width * 0.2, y: size.height * 0.58)
        ]
        let canopySizes = [
            CGSize(width: size.width * 0.36, height: size.height * 0.28),
            CGSize(width: size.width * 0.24, height: size.height * 0.2),
            CGSize(width: size.width * 0.26, height: size.height * 0.2)
        ]
        for (center, canopySize) in zip(canopyCenters, canopySizes) {
            let canopy = SKShapeNode(ellipseOf: canopySize)
            canopy.fillColor = canopyColor
            canopy.strokeColor = .clear
            canopy.position = center
            canopy.zPosition = -5
            tree.addChild(canopy)
        }

        let branchColor = style == "night"
            ? NSColor(calibratedRed: 0.36, green: 0.26, blue: 0.22, alpha: 0.56)
            : NSColor(calibratedRed: 0.45, green: 0.31, blue: 0.18, alpha: 0.46)
        let branchSpecs: [(start: CGPoint, end: CGPoint, width: CGFloat)] = [
            (
                CGPoint(x: trunkX + trunkWidth * 0.2, y: size.height * 0.72),
                CGPoint(x: size.width * 0.58, y: size.height * 0.72),
                6
            ),
            (
                CGPoint(x: trunkX - trunkWidth * 0.1, y: size.height * 0.5),
                CGPoint(x: size.width * 0.68, y: size.height * 0.52),
                5
            ),
            (
                CGPoint(x: trunkX + trunkWidth * 0.2, y: size.height * 0.31),
                CGPoint(x: size.width * 0.5, y: size.height * 0.3),
                5
            )
        ]

        for spec in branchSpecs {
            let path = CGMutablePath()
            path.move(to: spec.start)
            path.addLine(to: spec.end)

            let branch = SKShapeNode(path: path)
            branch.strokeColor = branchColor
            branch.lineWidth = spec.width
            branch.lineCap = .round
            tree.addChild(branch)

            let minX = min(spec.start.x, spec.end.x) + 18
            let maxX = max(spec.start.x, spec.end.x) - 18
            let y = (spec.start.y + spec.end.y) / 2 + 4
            perchSegments.append(BirdPerchSegment(
                xRange: minX...max(minX + 4, maxX),
                y: y
            ))
        }

        addChild(tree)
    }

    override func triggerFeedAnimation(for repoID: UUID, commit: CommitRecord) {
        guard let creature = creatures[repoID] else { return }

        let burst = SKShapeNode(circleOfRadius: 12)
        burst.fillColor = NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.48, alpha: 0.3)
        burst.strokeColor = NSColor(calibratedRed: 1.0, green: 0.94, blue: 0.72, alpha: 0.65)
        burst.lineWidth = 1.5
        burst.position = creature.position
        burst.zPosition = 8
        addChild(burst)
        burst.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 3.2, duration: 0.45),
                SKAction.fadeOut(withDuration: 0.45)
            ]),
            .removeFromParent()
        ]))

        creature.playFeedAnimation()

        let label = SKLabelNode(text: "Commit: \(String(commit.message.prefix(36)))")
        label.fontSize = 10
        label.fontColor = NSColor(white: 1.0, alpha: 0.96)
        label.fontName = "Menlo-Bold"
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: creature.position.x, y: creature.position.y + 34)
        label.alpha = 0
        label.zPosition = 9
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.18),
                SKAction.moveBy(x: 0, y: 10, duration: 0.18)
            ]),
            SKAction.wait(forDuration: 2.2),
            SKAction.fadeOut(withDuration: 0.45),
            .removeFromParent()
        ]))
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

    func randomPerchPoint() -> CGPoint {
        guard let perch = perchSegments.randomElement() else {
            return CGPoint(x: size.width * 0.55, y: size.height * 0.5)
        }
        return CGPoint(
            x: CGFloat.random(in: perch.xRange),
            y: perch.y
        )
    }

    private func makeCloud(center: CGPoint, scale: CGFloat, alpha: CGFloat) -> SKNode {
        let cloud = SKNode()
        let puffSizes = [
            CGSize(width: 54 * scale, height: 24 * scale),
            CGSize(width: 36 * scale, height: 20 * scale),
            CGSize(width: 40 * scale, height: 18 * scale)
        ]
        let puffOffsets = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: -20 * scale, y: -2 * scale),
            CGPoint(x: 20 * scale, y: -3 * scale)
        ]

        for (puffSize, offset) in zip(puffSizes, puffOffsets) {
            let puff = SKShapeNode(ellipseOf: puffSize)
            puff.fillColor = NSColor(white: 1.0, alpha: alpha)
            puff.strokeColor = .clear
            puff.position = CGPoint(x: center.x + offset.x, y: center.y + offset.y)
            cloud.addChild(puff)
        }

        return cloud
    }
}

import SpriteKit

struct BirdPerchSegment {
    let xRange: ClosedRange<CGFloat>
    let y: CGFloat
}

final class BirdScene: GameModeScene {
    private(set) var perchSegments: [BirdPerchSegment] = []
    private var cachedCloudTexture: SKTexture?
    private var cachedCloudSize: CGSize = CGSize(width: 96, height: 42)

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

        let trunkWidth = max(22, size.width * 0.058)
        let trunkHeight = max(120, size.height * 0.8)
        let trunkX = max(30, size.width * 0.16)
        let trunkPath = CGMutablePath()
        let trunkBottom = CGPoint(x: trunkX, y: 0)
        let trunkTopY = trunkHeight - 8
        trunkPath.move(to: CGPoint(x: trunkBottom.x - trunkWidth * 0.55, y: trunkBottom.y))
        trunkPath.addLine(to: CGPoint(x: trunkBottom.x - trunkWidth * 0.48, y: trunkTopY * 0.78))
        trunkPath.addQuadCurve(
            to: CGPoint(x: trunkX - trunkWidth * 0.2, y: trunkTopY),
            control: CGPoint(x: trunkX - trunkWidth * 0.62, y: trunkTopY * 0.96)
        )
        trunkPath.addLine(to: CGPoint(x: trunkX + trunkWidth * 0.22, y: trunkTopY))
        trunkPath.addQuadCurve(
            to: CGPoint(x: trunkBottom.x + trunkWidth * 0.52, y: trunkTopY * 0.76),
            control: CGPoint(x: trunkX + trunkWidth * 0.68, y: trunkTopY * 0.95)
        )
        trunkPath.addLine(to: CGPoint(x: trunkBottom.x + trunkWidth * 0.6, y: trunkBottom.y))
        trunkPath.closeSubpath()

        let trunk = SKShapeNode(path: trunkPath)
        trunk.fillColor = style == "night"
            ? NSColor(calibratedRed: 0.28, green: 0.2, blue: 0.15, alpha: 0.84)
            : NSColor(calibratedRed: 0.46, green: 0.31, blue: 0.19, alpha: 0.82)
        trunk.strokeColor = style == "night"
            ? NSColor(calibratedRed: 0.38, green: 0.28, blue: 0.21, alpha: 0.35)
            : NSColor(calibratedRed: 0.56, green: 0.38, blue: 0.24, alpha: 0.24)
        trunk.lineWidth = 1.2
        tree.addChild(trunk)

        let canopyColor = style == "night"
            ? NSColor(calibratedRed: 0.28, green: 0.42, blue: 0.31, alpha: 0.36)
            : NSColor(calibratedRed: 0.39, green: 0.63, blue: 0.34, alpha: 0.34)
        let canopyHighlight = style == "night"
            ? NSColor(calibratedRed: 0.42, green: 0.55, blue: 0.43, alpha: 0.12)
            : NSColor(calibratedRed: 0.58, green: 0.78, blue: 0.52, alpha: 0.16)
        let canopyCenters = [
            CGPoint(x: trunkX + size.width * 0.12, y: size.height * 0.82),
            CGPoint(x: trunkX + size.width * 0.03, y: size.height * 0.73),
            CGPoint(x: trunkX + size.width * 0.19, y: size.height * 0.69),
            CGPoint(x: trunkX + size.width * 0.1, y: size.height * 0.63)
        ]
        let canopySizes = [
            CGSize(width: size.width * 0.22, height: size.height * 0.17),
            CGSize(width: size.width * 0.14, height: size.height * 0.11),
            CGSize(width: size.width * 0.15, height: size.height * 0.12),
            CGSize(width: size.width * 0.12, height: size.height * 0.1)
        ]
        for (center, canopySize) in zip(canopyCenters, canopySizes) {
            let canopy = SKShapeNode(ellipseOf: canopySize)
            canopy.fillColor = canopyColor
            canopy.strokeColor = .clear
            canopy.position = center
            canopy.zPosition = -5
            tree.addChild(canopy)

            let highlight = SKShapeNode(ellipseOf: CGSize(width: canopySize.width * 0.54, height: canopySize.height * 0.4))
            highlight.fillColor = canopyHighlight
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: center.x - canopySize.width * 0.1, y: center.y + canopySize.height * 0.12)
            highlight.zPosition = -4.9
            tree.addChild(highlight)
        }

        let branchColor = style == "night"
            ? NSColor(calibratedRed: 0.46, green: 0.34, blue: 0.24, alpha: 0.72)
            : NSColor(calibratedRed: 0.55, green: 0.38, blue: 0.22, alpha: 0.68)
        let branchSpecs: [(start: CGPoint, end: CGPoint, width: CGFloat)] = [
            (
                CGPoint(x: trunkX + trunkWidth * 0.1, y: size.height * 0.72),
                CGPoint(x: size.width * 0.58, y: size.height * 0.72),
                7
            ),
            (
                CGPoint(x: trunkX + trunkWidth * 0.05, y: size.height * 0.51),
                CGPoint(x: size.width * 0.49, y: size.height * 0.51),
                6
            ),
            (
                CGPoint(x: trunkX + trunkWidth * 0.05, y: size.height * 0.3),
                CGPoint(x: size.width * 0.41, y: size.height * 0.3),
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

        creature.playCommitAnimation()
        spawnCommitReward(at: creature.position)
        showCommitLabel(for: commit, at: creature.position, prefix: "Commit!")
    }

    override func updateAmbientEffects() {
        if AppSettings.shared.showAmbientEffects {
            if action(forKey: "cloudSpawner") == nil {
                spawnAmbientClouds()
            }
        } else {
            removeAction(forKey: "cloudSpawner")
            children.filter { $0.name == "ambientCloud" }.forEach { $0.removeFromParent() }
        }
    }

    func constrainToScene(_ point: CGPoint) -> CGPoint {
        let margin: CGFloat = 32
        return CGPoint(
            x: max(margin, min(size.width - margin, point.x)),
            y: max(margin, min(size.height - margin, point.y))
        )
    }

    private func spawnAmbientClouds() {
        let spawn = SKAction.run { [weak self] in
            self?.createAmbientCloud()
        }
        let wait = SKAction.wait(forDuration: 13.0, withRange: 6.0)
        run(SKAction.repeatForever(SKAction.sequence([spawn, wait])), withKey: "cloudSpawner")
    }

    private func createAmbientCloud() {
        guard children.filter({ $0.name == "ambientCloud" }).count < 2 else { return }

        let scale = CGFloat.random(in: 0.42...0.72)
        let cloud = makeCloud(
            center: .zero,
            scale: scale,
            alpha: CGFloat.random(in: 0.1...0.18)
        )
        cloud.position = CGPoint(
            x: -70 * scale,
            y: CGFloat.random(in: max(52, size.height * 0.58)...max(72, size.height - 44))
        )
        cloud.zPosition = -10
        cloud.alpha = 0
        cloud.name = "ambientCloud"
        addChild(cloud)

        let move = SKAction.moveBy(
            x: size.width + 140 * scale,
            y: CGFloat.random(in: -6...6),
            duration: Double.random(in: 18...28)
        )
        move.timingMode = .easeInEaseOut
        let fadeIn = SKAction.fadeAlpha(to: CGFloat.random(in: 0.75...1.0), duration: 2.2)
        let fadeOut = SKAction.fadeOut(withDuration: 2.8)

        cloud.run(SKAction.sequence([
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
        let baseTexture = cloudTexture()
        let cloud = SKSpriteNode(texture: baseTexture)
        cloud.size = cachedCloudSize
        cloud.position = center
        cloud.alpha = alpha
        cloud.setScale(scale)
        return cloud
    }

    private func cloudTexture() -> SKTexture? {
        if let cachedCloudTexture {
            return cachedCloudTexture
        }

        guard let view else { return nil }

        let cloudTemplate = SKNode()
        let puffSizes = [
            CGSize(width: 62, height: 28),
            CGSize(width: 38, height: 24),
            CGSize(width: 42, height: 22),
            CGSize(width: 28, height: 16)
        ]
        let puffOffsets = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: -24, y: -1),
            CGPoint(x: 24, y: -3),
            CGPoint(x: 8, y: 7)
        ]

        for (puffSize, offset) in zip(puffSizes, puffOffsets) {
            let puff = SKShapeNode(ellipseOf: puffSize)
            puff.fillColor = .white
            puff.strokeColor = .clear
            puff.position = offset
            cloudTemplate.addChild(puff)
        }

        let frame = cloudTemplate.calculateAccumulatedFrame().insetBy(dx: -4, dy: -4)
        cachedCloudSize = frame.size
        cachedCloudTexture = view.texture(from: cloudTemplate, crop: frame)
        return cachedCloudTexture
    }
}

import SpriteKit
import QuartzCore

final class JamCreatureNode: CreatureNode {
    private let dancerNode = SKNode()
    private let nameLabel: SKLabelNode
    private let nameShadow: SKLabelNode
    private let phase = CGFloat.random(in: 0...(CGFloat.pi * 2))

    private var glowNode: SKShapeNode?
    private var bodyNode: SKShapeNode?
    private var bellyNode: SKShapeNode?
    private var leftArmNode: SKShapeNode?
    private var rightArmNode: SKShapeNode?
    private var equalizerBars: [SKShapeNode] = []

    init(creature: Creature, name: String, color: NSColor) {
        nameLabel = SKLabelNode(text: name)
        nameShadow = SKLabelNode(text: name)

        super.init(
            creature: creature,
            name: name,
            color: color,
            texture: nil,
            size: CGSize(width: 56, height: 64)
        )

        addChild(dancerNode)
        drawBody()
        configureNameLabels()
        updateNameVisibility()
        updateAppearance(creature)
    }

    private func drawBody() {
        let glow = SKShapeNode(circleOfRadius: 28)
        glow.fillColor = NSColor(calibratedRed: 0.64, green: 0.28, blue: 0.96, alpha: 0.18)
        glow.strokeColor = .clear
        glow.zPosition = -3
        dancerNode.addChild(glow)
        glowNode = glow

        let body = SKShapeNode(ellipseOf: CGSize(width: 36, height: 44))
        body.strokeColor = NSColor(white: 1.0, alpha: 0.22)
        body.lineWidth = 1.2
        dancerNode.addChild(body)
        bodyNode = body

        let belly = SKShapeNode(ellipseOf: CGSize(width: 18, height: 18))
        belly.position = CGPoint(x: 0, y: -6)
        belly.strokeColor = .clear
        belly.zPosition = 1
        dancerNode.addChild(belly)
        bellyNode = belly

        let leftArm = SKShapeNode(rectOf: CGSize(width: 7, height: 22), cornerRadius: 3.5)
        leftArm.position = CGPoint(x: -20, y: 2)
        leftArm.strokeColor = .clear
        leftArm.zPosition = -1
        dancerNode.addChild(leftArm)
        leftArmNode = leftArm

        let rightArm = SKShapeNode(rectOf: CGSize(width: 7, height: 22), cornerRadius: 3.5)
        rightArm.position = CGPoint(x: 20, y: 2)
        rightArm.strokeColor = .clear
        rightArm.zPosition = -1
        dancerNode.addChild(rightArm)
        rightArmNode = rightArm

        let leftLeg = SKShapeNode(rectOf: CGSize(width: 7, height: 18), cornerRadius: 3.5)
        leftLeg.fillColor = NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.18, alpha: 0.9)
        leftLeg.strokeColor = .clear
        leftLeg.position = CGPoint(x: -8, y: -28)
        dancerNode.addChild(leftLeg)

        let rightLeg = SKShapeNode(rectOf: CGSize(width: 7, height: 18), cornerRadius: 3.5)
        rightLeg.fillColor = leftLeg.fillColor
        rightLeg.strokeColor = .clear
        rightLeg.position = CGPoint(x: 8, y: -28)
        dancerNode.addChild(rightLeg)

        let headphoneBandPath = CGMutablePath()
        headphoneBandPath.move(to: CGPoint(x: -18, y: 18))
        headphoneBandPath.addQuadCurve(to: CGPoint(x: 18, y: 18), control: CGPoint(x: 0, y: 30))
        let headphoneBand = SKShapeNode(path: headphoneBandPath)
        headphoneBand.strokeColor = NSColor(white: 1.0, alpha: 0.88)
        headphoneBand.lineWidth = 2
        headphoneBand.zPosition = 2
        dancerNode.addChild(headphoneBand)

        let leftCup = SKShapeNode(rectOf: CGSize(width: 7, height: 14), cornerRadius: 3)
        leftCup.fillColor = NSColor(calibratedRed: 0.18, green: 0.98, blue: 0.88, alpha: 0.92)
        leftCup.strokeColor = .clear
        leftCup.position = CGPoint(x: -18, y: 11)
        leftCup.zPosition = 3
        dancerNode.addChild(leftCup)

        let rightCup = SKShapeNode(rectOf: CGSize(width: 7, height: 14), cornerRadius: 3)
        rightCup.fillColor = leftCup.fillColor
        rightCup.strokeColor = .clear
        rightCup.position = CGPoint(x: 18, y: 11)
        rightCup.zPosition = 3
        dancerNode.addChild(rightCup)

        let leftEye = SKShapeNode(circleOfRadius: 2.1)
        leftEye.fillColor = .white
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: -7, y: 8)
        leftEye.zPosition = 3
        dancerNode.addChild(leftEye)

        let rightEye = SKShapeNode(circleOfRadius: 2.1)
        rightEye.fillColor = .white
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: 7, y: 8)
        rightEye.zPosition = 3
        dancerNode.addChild(rightEye)

        let leftPupil = SKShapeNode(circleOfRadius: 1.0)
        leftPupil.fillColor = NSColor(white: 0.05, alpha: 1.0)
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: -7, y: 8)
        leftPupil.zPosition = 4
        dancerNode.addChild(leftPupil)

        let rightPupil = SKShapeNode(circleOfRadius: 1.0)
        rightPupil.fillColor = leftPupil.fillColor
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: 7, y: 8)
        rightPupil.zPosition = 4
        dancerNode.addChild(rightPupil)

        let smilePath = CGMutablePath()
        smilePath.move(to: CGPoint(x: -6, y: -2))
        smilePath.addQuadCurve(to: CGPoint(x: 6, y: -2), control: CGPoint(x: 0, y: -7))
        let smile = SKShapeNode(path: smilePath)
        smile.strokeColor = NSColor(white: 0.08, alpha: 0.45)
        smile.lineWidth = 1.4
        smile.lineCap = .round
        smile.zPosition = 3
        dancerNode.addChild(smile)

        let barOffsets: [CGFloat] = [-12, 0, 12]
        for x in barOffsets {
            let bar = SKShapeNode(rectOf: CGSize(width: 6, height: 10), cornerRadius: 3)
            bar.fillColor = NSColor(calibratedRed: 0.18, green: 0.98, blue: 0.88, alpha: 0.92)
            bar.strokeColor = .clear
            bar.position = CGPoint(x: x, y: -42)
            bar.zPosition = -2
            dancerNode.addChild(bar)
            equalizerBars.append(bar)
        }
    }

    private func configureNameLabels() {
        nameShadow.fontSize = 9
        nameShadow.fontName = "Menlo-Bold"
        nameShadow.fontColor = .black
        nameShadow.alpha = 0.45
        nameShadow.position = CGPoint(x: 1, y: -56)
        addChild(nameShadow)

        nameLabel.fontSize = 9
        nameLabel.fontName = "Menlo-Bold"
        nameLabel.fontColor = .white
        nameLabel.alpha = 0.88
        nameLabel.position = CGPoint(x: 0, y: -55)
        addChild(nameLabel)
    }

    override func updateAppearance(_ creature: Creature) {
        super.updateAppearance(creature)

        let palette = palette(for: creature)
        bodyNode?.fillColor = palette.body
        bellyNode?.fillColor = palette.belly
        leftArmNode?.fillColor = palette.arm
        rightArmNode?.fillColor = palette.arm
        glowNode?.fillColor = palette.glow
        glowNode?.alpha = creature.isAlive ? 0.18 + CGFloat(creature.happiness) * 0.1 : 0.08

        let creatureScale = CGFloat(creature.size)
        let windowScale = windowScaleFactor()
        let finalScale = max(0.42, creatureScale * windowScale)
        xScale = finalScale
        yScale = finalScale

        nameLabel.xScale = 1.0 / finalScale
        nameLabel.yScale = 1.0 / finalScale
        nameShadow.xScale = nameLabel.xScale
        nameShadow.yScale = nameLabel.yScale
        updateNameVisibility()
    }

    override func updateNameVisibility() {
        let show = AppSettings.shared.showCreatureNames
        nameLabel.isHidden = !show
        nameShadow.isHidden = !show
    }

    override func updateName(_ newName: String) {
        super.updateName(newName)
        nameLabel.text = newName
        nameShadow.text = newName
    }

    override func startIdleBehavior(in sceneSize: CGSize) {
        removeAction(forKey: "swimming")
        removeAction(forKey: "swimLoop")
        removeAction(forKey: "hovering")

        guard creatureState.isAlive else {
            alpha = 0.4
            run(
                SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.moveBy(x: 0, y: -2, duration: 2.4),
                        SKAction.moveBy(x: 0, y: 2, duration: 2.4)
                    ])
                ),
                withKey: "hovering"
            )
            return
        }

        alpha = 1.0
        if position == .zero {
            position = randomSpot(in: sceneSize)
        }
        wander(in: sceneSize)
    }

    override func playFeedAnimation() {
        guard let scene = scene else { return }

        removeAction(forKey: "swimming")
        removeAction(forKey: "swimLoop")

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.18, duration: 0.14),
            SKAction.scale(to: 1.0, duration: 0.18)
        ])
        let spin = SKAction.sequence([
            SKAction.rotate(byAngle: 0.18, duration: 0.08),
            SKAction.rotate(byAngle: -0.36, duration: 0.12),
            SKAction.rotate(byAngle: 0.18, duration: 0.08)
        ])

        dancerNode.run(SKAction.group([pulse, spin])) { [weak self] in
            self?.wander(in: scene.size)
        }
    }

    override func swimToFood(at point: CGPoint, food: SKNode) {
        guard let scene = scene, creatureState.isAlive else { return }

        removeAction(forKey: "swimming")
        removeAction(forKey: "swimLoop")

        let destination = clamp(point, in: scene.size)
        let distance = hypot(destination.x - position.x, destination.y - position.y)
        let speed = max(65, 90 * CGFloat(AppSettings.shared.movementSpeed))
        let duration = TimeInterval(distance / speed)

        let move = SKAction.move(to: destination, duration: duration)
        move.timingMode = .easeInEaseOut
        run(move, withKey: "swimming")

        run(
            SKAction.sequence([
                SKAction.wait(forDuration: duration),
                SKAction.run { [weak self, weak food] in
                    if let food = food, food.parent != nil {
                        food.removeAllActions()
                        food.run(SKAction.sequence([
                            SKAction.scale(to: 0.1, duration: 0.12),
                            .removeFromParent()
                        ]))
                    }
                    self?.creatureState.happiness = min(1.0, (self?.creatureState.happiness ?? 0) + 0.02)
                    self?.playFeedAnimation()
                }
            ]),
            withKey: "swimLoop"
        )
    }

    override func swimTowardPoint(_ target: CGPoint) {
        guard let scene = scene, creatureState.isAlive else { return }

        removeAction(forKey: "swimming")
        removeAction(forKey: "swimLoop")

        let destination = clamp(target, in: scene.size)
        let distance = hypot(destination.x - position.x, destination.y - position.y)
        let speed = max(55, 72 * CGFloat(AppSettings.shared.movementSpeed))
        let duration = TimeInterval(distance / speed)

        let move = SKAction.move(to: destination, duration: min(duration, 1.4))
        move.timingMode = .easeInEaseOut
        run(move, withKey: "swimming")
    }

    func setAudioResponse(level: CGFloat, beat: CGFloat) {
        guard creatureState.isAlive else { return }

        let time = CGFloat(CACurrentMediaTime())
        let groove = max(level, 0.08)
        let bounce = 2 + groove * 4 + beat * 8
        let sway = sin(time * (2.6 + groove * 3.0) + phase) * (0.06 + groove * 0.05 + beat * 0.07)
        let pulse = 1 + groove * 0.05 + beat * 0.14

        dancerNode.position.y = bounce
        dancerNode.zRotation = sway
        dancerNode.xScale = pulse
        dancerNode.yScale = 1 + groove * 0.07 + beat * 0.18

        leftArmNode?.zRotation = -0.18 - beat * 0.5 + sway * 0.4
        rightArmNode?.zRotation = 0.18 + beat * 0.5 - sway * 0.4
        glowNode?.alpha = 0.16 + groove * 0.18 + beat * 0.22

        for (index, bar) in equalizerBars.enumerated() {
            let phaseOffset = CGFloat(index) * 0.9
            let barGroove = max(0.18, groove + sin(time * 5.0 + phase + phaseOffset) * 0.08 + beat * 0.3)
            bar.yScale = 0.55 + barGroove * 2.0
        }
    }

    private func wander(in sceneSize: CGSize) {
        guard creatureState.isAlive else { return }

        let target = randomSpot(in: sceneSize)
        let distance = hypot(target.x - position.x, target.y - position.y)
        let speed = max(18, 28 * CGFloat(AppSettings.shared.movementSpeed))
        let duration = TimeInterval(distance / speed)

        let move = SKAction.move(to: target, duration: duration)
        move.timingMode = .easeInEaseOut
        run(move, withKey: "swimming")

        run(
            SKAction.sequence([
                SKAction.wait(forDuration: duration + Double.random(in: 0.7...1.8)),
                SKAction.run { [weak self] in
                    guard let self, let scene = self.scene else { return }
                    self.wander(in: scene.size)
                }
            ]),
            withKey: "swimLoop"
        )
    }

    private func randomSpot(in sceneSize: CGSize) -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: 44...max(45, sceneSize.width - 44)),
            y: CGFloat.random(in: 72...max(73, sceneSize.height - 46))
        )
    }

    private func clamp(_ point: CGPoint, in sceneSize: CGSize) -> CGPoint {
        CGPoint(
            x: max(36, min(sceneSize.width - 36, point.x)),
            y: max(64, min(sceneSize.height - 36, point.y))
        )
    }

    private func windowScaleFactor() -> CGFloat {
        guard let scene else { return 1.0 }
        let refArea: CGFloat = 400 * 300
        let currentArea = scene.size.width * scene.size.height
        return max(0.44, min(1.5, sqrt(currentArea / refArea)))
    }

    private func palette(for creature: Creature) -> (body: NSColor, belly: NSColor, arm: NSColor, glow: NSColor) {
        if !creature.isAlive {
            return (
                NSColor(white: 0.42, alpha: 0.7),
                NSColor(white: 0.54, alpha: 0.7),
                NSColor(white: 0.34, alpha: 0.7),
                NSColor(white: 0.76, alpha: 0.08)
            )
        }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        baseColor.usingColorSpace(.sRGB)?.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let energy = CGFloat(1.0 - creature.hunger * 0.45)
        let body = NSColor(
            hue: hue,
            saturation: saturation * 0.85 + 0.1,
            brightness: min(1.0, brightness * 0.86 + 0.1 * energy),
            alpha: 0.96
        )
        let belly = body.blended(withFraction: 0.4, of: .white) ?? body
        let arm = body.blended(withFraction: 0.18, of: .black) ?? body
        let glow = body.withAlphaComponent(0.22)
        return (body, belly, arm, glow)
    }
}

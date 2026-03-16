import SpriteKit
import QuartzCore

final class FishCreatureNode: CreatureNode {
    private let nameLabel: SKLabelNode
    private let nameShadow: SKLabelNode
    private var facingRight = true
    private var isJamming = false
    private var jamBasePosition = CGPoint.zero

    init(creature: Creature, name: String, color: NSColor) {
        nameLabel = SKLabelNode(text: name)
        nameShadow = SKLabelNode(text: name)

        let fishSize = CGSize(width: 48, height: 28)
        super.init(creature: creature, name: name, color: color, texture: nil, size: fishSize)

        drawFishBody()

        nameShadow.fontSize = 9
        nameShadow.fontName = "Menlo-Bold"
        nameShadow.fontColor = .black
        nameShadow.position = CGPoint(x: 1, y: -24)
        nameShadow.alpha = 0.5
        nameShadow.name = "nameShadow"
        addChild(nameShadow)

        nameLabel.fontSize = 9
        nameLabel.fontName = "Menlo-Bold"
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: 0, y: -23)
        nameLabel.alpha = 0.85
        nameLabel.name = "nameLabel"
        addChild(nameLabel)

        updateNameVisibility()
        updateAppearance(creature)
    }

    private func drawFishBody() {
        let glow = SKShapeNode(ellipseOf: CGSize(width: 54, height: 28))
        glow.fillColor = NSColor(white: 0.0, alpha: 0.18)
        glow.strokeColor = .clear
        glow.zPosition = -2
        glow.name = "glow"
        addChild(glow)

        let bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: -18, y: 0))
        bodyPath.addQuadCurve(to: CGPoint(x: 13, y: 8.5), control: CGPoint(x: -2, y: 14))
        bodyPath.addQuadCurve(to: CGPoint(x: 21, y: 0), control: CGPoint(x: 24, y: 6))
        bodyPath.addQuadCurve(to: CGPoint(x: 13, y: -8.5), control: CGPoint(x: 24, y: -6))
        bodyPath.addQuadCurve(to: CGPoint(x: -18, y: 0), control: CGPoint(x: -2, y: -14))

        let body = SKShapeNode(path: bodyPath)
        body.strokeColor = NSColor(white: 1.0, alpha: 0.3)
        body.lineWidth = 1
        body.zPosition = 0
        body.name = "body"
        addChild(body)

        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -18, y: 0))
        tailPath.addLine(to: CGPoint(x: -30, y: 9))
        tailPath.addLine(to: CGPoint(x: -24, y: 0))
        tailPath.addLine(to: CGPoint(x: -30, y: -9))
        tailPath.closeSubpath()

        let tail = SKShapeNode(path: tailPath)
        tail.strokeColor = .clear
        tail.zPosition = -1
        tail.name = "tail"
        addChild(tail)

        let dorsalFinPath = CGMutablePath()
        dorsalFinPath.move(to: CGPoint(x: -5, y: 6))
        dorsalFinPath.addQuadCurve(to: CGPoint(x: 5, y: 12), control: CGPoint(x: -1, y: 14))
        dorsalFinPath.addQuadCurve(to: CGPoint(x: 10, y: 5), control: CGPoint(x: 10, y: 11))
        dorsalFinPath.closeSubpath()

        let dorsalFin = SKShapeNode(path: dorsalFinPath)
        dorsalFin.strokeColor = .clear
        dorsalFin.zPosition = -1
        dorsalFin.name = "dorsalFin"
        addChild(dorsalFin)

        let bellyFinPath = CGMutablePath()
        bellyFinPath.move(to: CGPoint(x: 0, y: -4))
        bellyFinPath.addQuadCurve(to: CGPoint(x: 8, y: -11), control: CGPoint(x: 5, y: -12))
        bellyFinPath.addQuadCurve(to: CGPoint(x: 10, y: -3), control: CGPoint(x: 11, y: -9))
        bellyFinPath.closeSubpath()

        let bellyFin = SKShapeNode(path: bellyFinPath)
        bellyFin.strokeColor = .clear
        bellyFin.zPosition = -1
        bellyFin.name = "bellyFin"
        addChild(bellyFin)

        let highlight = SKShapeNode(ellipseOf: CGSize(width: 16, height: 7))
        highlight.fillColor = NSColor(white: 1.0, alpha: 0.18)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 5, y: 5)
        highlight.zPosition = 1
        highlight.name = "highlight"
        addChild(highlight)

        let eye = SKShapeNode(circleOfRadius: 2.6)
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 11, y: 2.8)
        eye.zPosition = 2
        addChild(eye)

        let pupil = SKShapeNode(circleOfRadius: 1.4)
        pupil.fillColor = NSColor(white: 0.1, alpha: 1.0)
        pupil.strokeColor = .clear
        pupil.position = CGPoint(x: 12.2, y: 2.8)
        pupil.zPosition = 3
        addChild(pupil)

        let mouth = SKShapeNode(rectOf: CGSize(width: 4.5, height: 1.3), cornerRadius: 0.65)
        mouth.fillColor = NSColor(white: 0.0, alpha: 0.3)
        mouth.strokeColor = .clear
        mouth.position = CGPoint(x: 17, y: -2)
        mouth.zPosition = 2
        addChild(mouth)
    }

    override func updateAppearance(_ creature: Creature) {
        super.updateAppearance(creature)

        let bodyNode = childNode(withName: "body") as? SKShapeNode
        let tailNode = childNode(withName: "tail") as? SKShapeNode
        let dorsalFinNode = childNode(withName: "dorsalFin") as? SKShapeNode
        let bellyFinNode = childNode(withName: "bellyFin") as? SKShapeNode
        let glowNode = childNode(withName: "glow") as? SKShapeNode

        let color: NSColor
        if !creature.isAlive {
            color = NSColor(white: 0.4, alpha: 0.6)
        } else {
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            baseColor.usingColorSpace(.sRGB)?.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            let hungerFactor = 1.0 - creature.hunger * 0.5
            color = NSColor(
                hue: h,
                saturation: s * hungerFactor,
                brightness: b * (0.64 + 0.36 * hungerFactor),
                alpha: 0.95
            )
        }

        bodyNode?.fillColor = color
        tailNode?.fillColor = color.withAlphaComponent(0.78)
        dorsalFinNode?.fillColor = color.withAlphaComponent(0.68)
        bellyFinNode?.fillColor = color.withAlphaComponent(0.6)
        glowNode?.alpha = creature.isAlive ? 0.18 + CGFloat(creature.happiness * 0.08) : 0.08

        let creatureScale = CGFloat(creature.size)
        let windowScale = windowScaleFactor()
        let finalScale = max(0.35, creatureScale * windowScale)
        let appliedX = facingRight ? finalScale : -finalScale
        xScale = appliedX
        yScale = finalScale

        nameLabel.xScale = facingRight ? 1.0 / finalScale : -1.0 / finalScale
        nameLabel.yScale = 1.0 / finalScale
        nameShadow.xScale = nameLabel.xScale
        nameShadow.yScale = nameLabel.yScale

        updateNameVisibility()
    }

    private func windowScaleFactor() -> CGFloat {
        guard let scene = scene else { return 1.0 }
        let refArea: CGFloat = 400 * 300
        let currentArea = scene.size.width * scene.size.height
        return max(0.4, min(1.5, sqrt(currentArea / refArea)))
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
        isJamming = false
        guard creatureState.isAlive else {
            zRotation = .pi
            alpha = 0.4
            let drift = SKAction.moveBy(x: 0, y: 3, duration: 4)
            let driftBack = drift.reversed()
            run(SKAction.repeatForever(SKAction.sequence([drift, driftBack])))
            return
        }

        if position == .zero {
            position = reservedSwimPoint(in: sceneSize, avoidCurrent: false)
        }
        swimToRandomPoint(in: sceneSize)
    }

    override func beginJamMode() {
        guard creatureState.isAlive else { return }

        isJamming = true
        removeAction(forKey: "swimming")
        removeAction(forKey: "swimLoop")
        removeAction(forKey: "hovering")
        removeAction(forKey: "hoverTimer")
        removeAction(forKey: "schooling")
        jamBasePosition = position
        zRotation = facingRight ? .pi / 3 : -.pi / 3
    }

    override func endJamMode(resumeIn sceneSize: CGSize) {
        guard isJamming else {
            startIdleBehavior(in: sceneSize)
            return
        }

        isJamming = false
        position = jamBasePosition == .zero ? position : jamBasePosition
        zRotation = 0
        startIdleBehavior(in: sceneSize)
    }

    override func updateJam(level: CGFloat, beat: CGFloat) {
        guard isJamming else { return }

        let time = CGFloat(CACurrentMediaTime())
        let groove = level * 0.5
        let bounce = 0.8 + groove * 1.8 + beat * 5.2
        let sway = sin(time * 2.4) * (0.025 + groove * 0.035) + beat * 0.035
        let upright = facingRight ? CGFloat.pi / 3 : -CGFloat.pi / 3

        position = CGPoint(
            x: jamBasePosition.x + sin(time * 1.6) * (0.35 + groove * 0.75),
            y: jamBasePosition.y + abs(sin(time * 2.2)) * bounce
        )
        zRotation = upright + sway

        let glowNode = childNode(withName: "glow") as? SKShapeNode
        glowNode?.glowWidth = beat * 5
        glowNode?.alpha = creatureState.isAlive ? 0.16 + groove * 0.08 + beat * 0.14 : 0.08
    }

    private func swimToRandomPoint(in sceneSize: CGSize) {
        guard creatureState.isAlive else { return }

        let currentSize = scene?.size ?? sceneSize
        let target = reservedSwimPoint(in: currentSize)

        let goingRight = target.x > position.x
        if goingRight != facingRight {
            facingRight = goingRight
            updateAppearance(creatureState)
        }

        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = sqrt(dx * dx + dy * dy)

        let speedMultiplier = CGFloat(AppSettings.shared.movementSpeed)
        let speed: CGFloat = (24 + 34 * CGFloat(creatureState.happiness)) * speedMultiplier
        let duration = TimeInterval(distance / max(speed, 10))

        let move = SKAction.move(to: target, duration: duration)
        move.timingMode = .easeInEaseOut

        let wagUp = SKAction.rotate(byAngle: 0.022, duration: 0.32)
        wagUp.timingMode = .easeInEaseOut
        let wagDown = SKAction.rotate(byAngle: -0.022, duration: 0.32)
        wagDown.timingMode = .easeInEaseOut
        let waggle = SKAction.repeatForever(SKAction.sequence([wagUp, wagDown]))

        run(SKAction.group([move, waggle]), withKey: "swimming")

        let afterArrival = SKAction.run { [weak self] in
            self?.removeAction(forKey: "swimming")
            self?.zRotation = 0
            self?.maybeHoverOrSwim()
        }
        run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            afterArrival
        ]), withKey: "swimLoop")
    }

    private func maybeHoverOrSwim() {
        guard creatureState.isAlive else { return }

        let hoverChance = 0.08 + (1.0 - creatureState.happiness) * 0.14
        if Double.random(in: 0...1) < hoverChance {
            startHovering()
        } else {
            let wait = SKAction.wait(forDuration: Double.random(in: 0.6...1.8))
            let nextSwim = SKAction.run { [weak self] in
                guard let self = self, let scene = self.scene else { return }
                self.swimToRandomPoint(in: scene.size)
            }
            run(SKAction.sequence([wait, nextSwim]), withKey: "swimLoop")
        }
    }

    private func startHovering() {
        let hoverDuration = Double.random(in: 1.5...4.0)

        let driftUp = SKAction.moveBy(x: 0, y: 2.5, duration: 1.8)
        driftUp.timingMode = .easeInEaseOut
        let driftDown = driftUp.reversed()
        let drift = SKAction.repeatForever(SKAction.sequence([driftUp, driftDown]))

        let lookRight = SKAction.rotate(byAngle: 0.012, duration: 2.4)
        lookRight.timingMode = .easeInEaseOut
        let lookLeft = lookRight.reversed()
        let look = SKAction.repeatForever(SKAction.sequence([lookRight, lookLeft]))

        run(SKAction.group([drift, look]), withKey: "hovering")

        let resume = SKAction.run { [weak self] in
            self?.removeAction(forKey: "hovering")
            self?.zRotation = 0
            guard let self = self, let scene = self.scene else { return }
            self.swimToRandomPoint(in: scene.size)
        }
        run(SKAction.sequence([
            SKAction.wait(forDuration: hoverDuration),
            resume
        ]), withKey: "hoverTimer")
    }

    override func playFeedAnimation() {
        removeAction(forKey: "swimming")
        removeAction(forKey: "swimLoop")
        removeAction(forKey: "hovering")
        removeAction(forKey: "hoverTimer")
        removeAction(forKey: "schooling")
        zRotation = 0

        let wiggle = SKAction.sequence([
            SKAction.rotate(byAngle: 0.08, duration: 0.06),
            SKAction.rotate(byAngle: -0.16, duration: 0.09),
            SKAction.rotate(byAngle: 0.18, duration: 0.1),
            SKAction.rotate(byAngle: -0.1, duration: 0.06),
        ])

        let currentXScale = xScale
        let currentYScale = yScale
        let pulse = SKAction.sequence([
            SKAction.scaleX(to: currentXScale * 0.94, y: currentYScale * 1.14, duration: 0.1),
            SKAction.scaleX(to: currentXScale * 1.08, y: currentYScale * 0.94, duration: 0.12),
            SKAction.scaleX(to: currentXScale, y: currentYScale, duration: 0.12),
        ])

        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 7, duration: 0.12),
            SKAction.moveBy(x: 0, y: -7, duration: 0.18)
        ])

        let bodyNode = childNode(withName: "body") as? SKShapeNode
        let tailNode = childNode(withName: "tail") as? SKShapeNode
        let dorsalFinNode = childNode(withName: "dorsalFin") as? SKShapeNode
        let bellyFinNode = childNode(withName: "bellyFin") as? SKShapeNode
        let glowNode = childNode(withName: "glow") as? SKShapeNode
        let originalColor = bodyNode?.fillColor ?? baseColor
        let originalTailColor = tailNode?.fillColor ?? baseColor
        let originalDorsalColor = dorsalFinNode?.fillColor ?? baseColor
        let originalBellyColor = bellyFinNode?.fillColor ?? baseColor
        let originalGlowAlpha = glowNode?.alpha ?? 0.2
        let celebratoryColor = originalColor.blended(withFraction: 0.18, of: NSColor(calibratedRed: 1.0, green: 0.88, blue: 0.5, alpha: 1.0)) ?? originalColor
        let flash = SKAction.run {
            bodyNode?.fillColor = celebratoryColor
            tailNode?.fillColor = celebratoryColor.withAlphaComponent(0.82)
            dorsalFinNode?.fillColor = celebratoryColor.withAlphaComponent(0.72)
            bellyFinNode?.fillColor = celebratoryColor.withAlphaComponent(0.64)
            glowNode?.alpha = max(originalGlowAlpha, 0.34)
            glowNode?.glowWidth = 8
        }
        let restore = SKAction.run {
            bodyNode?.fillColor = originalColor
            tailNode?.fillColor = originalTailColor
            dorsalFinNode?.fillColor = originalDorsalColor
            bellyFinNode?.fillColor = originalBellyColor
            glowNode?.alpha = originalGlowAlpha
            glowNode?.glowWidth = 0
        }
        let colorFlash = SKAction.sequence([flash, SKAction.wait(forDuration: 0.24), restore])

        run(SKAction.group([wiggle, pulse, bounce, colorFlash])) { [weak self] in
            guard let self = self, let scene = self.scene else { return }
            self.swimToRandomPoint(in: scene.size)
        }
    }

    override func swimToFood(at point: CGPoint, food: SKNode) {
        guard creatureState.isAlive else { return }

        removeAction(forKey: "swimming")
        removeAction(forKey: "swimLoop")
        removeAction(forKey: "hovering")
        removeAction(forKey: "hoverTimer")
        removeAction(forKey: "schooling")
        zRotation = 0

        let goingRight = point.x > position.x
        if goingRight != facingRight {
            facingRight = goingRight
            updateAppearance(creatureState)
        }

        let dx = point.x - position.x
        let dy = point.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        let speed: CGFloat = 72 * CGFloat(AppSettings.shared.movementSpeed)
        let duration = TimeInterval(distance / max(speed, 10))

        let move = SKAction.move(to: point, duration: duration)
        move.timingMode = .easeInEaseOut

        let wagUp = SKAction.rotate(byAngle: 0.03, duration: 0.18)
        let wagDown = SKAction.rotate(byAngle: -0.03, duration: 0.18)
        let waggle = SKAction.repeatForever(SKAction.sequence([wagUp, wagDown]))

        run(SKAction.group([move, waggle]), withKey: "swimming")

        let eat = SKAction.run { [weak self, weak food] in
            self?.removeAction(forKey: "swimming")
            self?.zRotation = 0

            if let food = food, food.parent != nil {
                food.removeAllActions()
                food.run(SKAction.sequence([
                    SKAction.scale(to: 0.1, duration: 0.15),
                    .removeFromParent()
                ]))
            }

            let miniWiggle = SKAction.sequence([
                SKAction.rotate(byAngle: 0.08, duration: 0.05),
                SKAction.rotate(byAngle: -0.16, duration: 0.1),
                SKAction.rotate(byAngle: 0.08, duration: 0.05),
            ])
            self?.run(miniWiggle) {
                guard let self = self, let scene = self.scene else { return }
                self.creatureState.happiness = min(1.0, self.creatureState.happiness + 0.02)
                self.swimToRandomPoint(in: scene.size)
            }
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: duration + 0.1),
            eat
        ]), withKey: "swimLoop")
    }

    override func swimTowardPoint(_ target: CGPoint) {
        guard creatureState.isAlive else { return }

        removeAction(forKey: "swimming")
        removeAction(forKey: "swimLoop")
        removeAction(forKey: "hovering")
        removeAction(forKey: "hoverTimer")
        zRotation = 0

        let goingRight = target.x > position.x
        if goingRight != facingRight {
            facingRight = goingRight
            updateAppearance(creatureState)
        }

        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        let speed: CGFloat = (24 + 34 * CGFloat(creatureState.happiness)) * CGFloat(AppSettings.shared.movementSpeed)
        let duration = TimeInterval(distance / max(speed, 10))

        let move = SKAction.move(to: target, duration: min(duration, 2.2))
        move.timingMode = .easeInEaseOut

        let wagUp = SKAction.rotate(byAngle: 0.022, duration: 0.32)
        let wagDown = SKAction.rotate(byAngle: -0.022, duration: 0.32)
        let waggle = SKAction.repeatForever(SKAction.sequence([wagUp, wagDown]))

        run(SKAction.group([move, waggle]), withKey: "schooling")

        let resume = SKAction.run { [weak self] in
            self?.removeAction(forKey: "schooling")
            self?.zRotation = 0
            guard let self = self, let scene = self.scene else { return }
            self.swimToRandomPoint(in: scene.size)
        }
        run(SKAction.sequence([
            SKAction.wait(forDuration: min(duration, 2.2) + 0.3),
            resume
        ]), withKey: "swimLoop")
    }

    private func reservedSwimPoint(in sceneSize: CGSize, avoidCurrent: Bool = true) -> CGPoint {
        if let fishScene = scene as? FishScene {
            let preferredPoint = position == .zero
                ? CGPoint(x: sceneSize.width * 0.5, y: sceneSize.height * 0.5)
                : position
            return fishScene.reserveSwimPoint(
                for: self,
                near: preferredPoint,
                avoidCurrent: avoidCurrent
            )
        }

        let margin: CGFloat = 40
        let maxX = max(margin + 1, sceneSize.width - margin)
        let maxY = max(margin + 1, sceneSize.height - margin)
        return CGPoint(
            x: CGFloat.random(in: margin...maxX),
            y: CGFloat.random(in: margin...maxY)
        )
    }
}

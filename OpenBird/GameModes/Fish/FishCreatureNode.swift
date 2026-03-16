import SpriteKit

final class FishCreatureNode: CreatureNode {
    private let nameLabel: SKLabelNode
    private let nameShadow: SKLabelNode
    private var facingRight = true

    init(creature: Creature, name: String, color: NSColor) {
        nameLabel = SKLabelNode(text: name)
        nameShadow = SKLabelNode(text: name)

        let fishSize = CGSize(width: 44, height: 26)
        super.init(creature: creature, name: name, color: color, texture: nil, size: fishSize)

        drawFishBody()

        // Name shadow
        nameShadow.fontSize = 9
        nameShadow.fontName = "Menlo-Bold"
        nameShadow.fontColor = .black
        nameShadow.position = CGPoint(x: 1, y: -23)
        nameShadow.alpha = 0.5
        nameShadow.name = "nameShadow"
        addChild(nameShadow)

        // Name label
        nameLabel.fontSize = 9
        nameLabel.fontName = "Menlo-Bold"
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: 0, y: -22)
        nameLabel.alpha = 0.85
        nameLabel.name = "nameLabel"
        addChild(nameLabel)

        updateNameVisibility()
        updateAppearance(creature)
    }

    private func drawFishBody() {
        // Glow behind fish for visibility
        let glow = SKShapeNode(ellipseOf: CGSize(width: 48, height: 30))
        glow.fillColor = NSColor(white: 0.0, alpha: 0.25)
        glow.strokeColor = .clear
        glow.zPosition = -2
        glow.name = "glow"
        addChild(glow)

        // Body
        let body = SKShapeNode(ellipseOf: CGSize(width: 40, height: 22))
        body.strokeColor = NSColor(white: 1.0, alpha: 0.3)
        body.lineWidth = 1
        body.zPosition = 0
        body.name = "body"
        addChild(body)

        // Tail
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -20, y: 0))
        tailPath.addLine(to: CGPoint(x: -30, y: 10))
        tailPath.addLine(to: CGPoint(x: -30, y: -10))
        tailPath.closeSubpath()

        let tail = SKShapeNode(path: tailPath)
        tail.strokeColor = .clear
        tail.zPosition = -1
        tail.name = "tail"
        addChild(tail)

        // Eye
        let eye = SKShapeNode(circleOfRadius: 3)
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 12, y: 3)
        eye.zPosition = 1
        addChild(eye)

        let pupil = SKShapeNode(circleOfRadius: 1.5)
        pupil.fillColor = NSColor(white: 0.1, alpha: 1.0)
        pupil.strokeColor = .clear
        pupil.position = CGPoint(x: 13, y: 3)
        pupil.zPosition = 2
        addChild(pupil)

        // Mouth
        let mouth = SKShapeNode(rectOf: CGSize(width: 4, height: 1.5), cornerRadius: 0.75)
        mouth.fillColor = NSColor(white: 0.0, alpha: 0.3)
        mouth.strokeColor = .clear
        mouth.position = CGPoint(x: 16, y: -2)
        mouth.zPosition = 1
        addChild(mouth)
    }

    override func updateAppearance(_ creature: Creature) {
        super.updateAppearance(creature)

        let bodyNode = childNode(withName: "body") as? SKShapeNode
        let tailNode = childNode(withName: "tail") as? SKShapeNode

        // Use permanent base color, modulated by hunger
        let color: NSColor
        if !creature.isAlive {
            color = NSColor(white: 0.4, alpha: 0.6)
        } else {
            // Desaturate and dim based on hunger
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            baseColor.usingColorSpace(.sRGB)?.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            let hungerFactor = 1.0 - creature.hunger * 0.5
            color = NSColor(
                hue: h,
                saturation: s * hungerFactor,
                brightness: b * (0.6 + 0.4 * hungerFactor),
                alpha: 0.95
            )
        }

        bodyNode?.fillColor = color
        tailNode?.fillColor = color.withAlphaComponent(0.75)

        // Scale based on creature size, clamped to minimum visible
        let creatureScale = CGFloat(creature.size)
        let windowScale = windowScaleFactor()
        let finalScale = max(0.35, creatureScale * windowScale) // never too tiny
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
        let refArea: CGFloat = 400 * 300 // reference window size
        let currentArea = scene.size.width * scene.size.height
        // Scale proportionally but clamp
        return max(0.4, min(1.5, sqrt(currentArea / refArea)))
    }

    func updateNameVisibility() {
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
        guard creatureState.isAlive else {
            zRotation = .pi
            alpha = 0.4
            let drift = SKAction.moveBy(x: 0, y: 3, duration: 4)
            let driftBack = drift.reversed()
            run(SKAction.repeatForever(SKAction.sequence([drift, driftBack])))
            return
        }

        swimToRandomPoint(in: sceneSize)
    }

    private func swimToRandomPoint(in sceneSize: CGSize) {
        guard creatureState.isAlive else { return }

        // Always use fresh scene size to avoid stale bounds
        let currentSize = scene?.size ?? sceneSize

        let margin: CGFloat = 40
        let maxX = max(margin + 1, currentSize.width - margin)
        let maxY = max(margin + 1, currentSize.height - margin)
        let target = CGPoint(
            x: CGFloat.random(in: margin...maxX),
            y: CGFloat.random(in: margin...maxY)
        )

        let goingRight = target.x > position.x
        if goingRight != facingRight {
            facingRight = goingRight
            updateAppearance(creatureState)
        }

        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = sqrt(dx * dx + dy * dy)

        let speedMultiplier = CGFloat(AppSettings.shared.movementSpeed)
        let speed: CGFloat = (25 + 45 * CGFloat(creatureState.happiness)) * speedMultiplier
        let duration = TimeInterval(distance / max(speed, 10))

        let move = SKAction.move(to: target, duration: duration)
        move.timingMode = .easeInEaseOut

        let wagUp = SKAction.rotate(byAngle: 0.04, duration: 0.25)
        wagUp.timingMode = .easeInEaseOut
        let wagDown = SKAction.rotate(byAngle: -0.04, duration: 0.25)
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

        // Unhappy fish hover more (25-50% chance)
        let hoverChance = 0.25 + (1.0 - creatureState.happiness) * 0.25
        if Double.random(in: 0...1) < hoverChance {
            startHovering()
        } else {
            // Brief pause then swim again
            let wait = SKAction.wait(forDuration: Double.random(in: 0.3...1.5))
            let nextSwim = SKAction.run { [weak self] in
                guard let self = self, let scene = self.scene else { return }
                self.swimToRandomPoint(in: scene.size)
            }
            run(SKAction.sequence([wait, nextSwim]), withKey: "swimLoop")
        }
    }

    private func startHovering() {
        let hoverDuration = Double.random(in: 2.0...8.0)

        // Gentle vertical drift
        let driftUp = SKAction.moveBy(x: 0, y: 4, duration: 1.5)
        driftUp.timingMode = .easeInEaseOut
        let driftDown = driftUp.reversed()
        let drift = SKAction.repeatForever(SKAction.sequence([driftUp, driftDown]))

        // Subtle "look around" rotation
        let lookRight = SKAction.rotate(byAngle: 0.02, duration: 2.0)
        lookRight.timingMode = .easeInEaseOut
        let lookLeft = lookRight.reversed()
        let look = SKAction.repeatForever(SKAction.sequence([lookRight, lookLeft]))

        let hoverGroup = SKAction.group([drift, look])
        run(hoverGroup, withKey: "hovering")

        // After hover, resume swimming
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
            SKAction.rotate(byAngle: 0.2, duration: 0.05),
            SKAction.rotate(byAngle: -0.4, duration: 0.1),
            SKAction.rotate(byAngle: 0.4, duration: 0.1),
            SKAction.rotate(byAngle: -0.2, duration: 0.05),
        ])

        let currentScale = CGFloat(creatureState.size)
        let pulse = SKAction.sequence([
            SKAction.scale(to: currentScale * 1.3, duration: 0.12),
            SKAction.scale(to: currentScale, duration: 0.12),
        ])

        let bodyNode = childNode(withName: "body") as? SKShapeNode
        let originalColor = bodyNode?.fillColor ?? baseColor
        let flash = SKAction.run {
            bodyNode?.fillColor = NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.4, alpha: 1.0)
        }
        let restore = SKAction.run {
            bodyNode?.fillColor = originalColor
        }
        let colorFlash = SKAction.sequence([flash, SKAction.wait(forDuration: 0.25), restore])

        let feedAnim = SKAction.group([wiggle, pulse, colorFlash])

        run(feedAnim) { [weak self] in
            guard let self = self, let scene = self.scene else { return }
            self.swimToRandomPoint(in: scene.size)
        }
    }

    // MARK: - Food & Schooling

    override func swimToFood(at point: CGPoint, food: SKNode) {
        guard creatureState.isAlive else { return }

        // Interrupt current behavior
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
        let speed: CGFloat = 80 * CGFloat(AppSettings.shared.movementSpeed)
        let duration = TimeInterval(distance / max(speed, 10))

        let move = SKAction.move(to: point, duration: duration)
        move.timingMode = .easeInEaseOut

        let wagUp = SKAction.rotate(byAngle: 0.06, duration: 0.15)
        let wagDown = SKAction.rotate(byAngle: -0.06, duration: 0.15)
        let waggle = SKAction.repeatForever(SKAction.sequence([wagUp, wagDown]))

        run(SKAction.group([move, waggle]), withKey: "swimming")

        let eat = SKAction.run { [weak self, weak food] in
            self?.removeAction(forKey: "swimming")
            self?.zRotation = 0

            // Remove food safely
            if let food = food, food.parent != nil {
                food.removeAllActions()
                food.run(SKAction.sequence([
                    SKAction.scale(to: 0.1, duration: 0.15),
                    .removeFromParent()
                ]))
            }

            // Mini wiggle
            let miniWiggle = SKAction.sequence([
                SKAction.rotate(byAngle: 0.1, duration: 0.05),
                SKAction.rotate(byAngle: -0.2, duration: 0.1),
                SKAction.rotate(byAngle: 0.1, duration: 0.05),
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

        // Interrupt current behavior
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
        let speed: CGFloat = (25 + 45 * CGFloat(creatureState.happiness)) * CGFloat(AppSettings.shared.movementSpeed)
        let duration = TimeInterval(distance / max(speed, 10))

        let move = SKAction.move(to: target, duration: min(duration, 2.0))
        move.timingMode = .easeInEaseOut

        let wagUp = SKAction.rotate(byAngle: 0.04, duration: 0.25)
        let wagDown = SKAction.rotate(byAngle: -0.04, duration: 0.25)
        let waggle = SKAction.repeatForever(SKAction.sequence([wagUp, wagDown]))

        run(SKAction.group([move, waggle]), withKey: "schooling")

        // After schooling movement, resume normal swimming
        let resume = SKAction.run { [weak self] in
            self?.removeAction(forKey: "schooling")
            self?.zRotation = 0
            guard let self = self, let scene = self.scene else { return }
            self.swimToRandomPoint(in: scene.size)
        }
        run(SKAction.sequence([
            SKAction.wait(forDuration: min(duration, 2.0) + 0.3),
            resume
        ]), withKey: "swimLoop")
    }
}

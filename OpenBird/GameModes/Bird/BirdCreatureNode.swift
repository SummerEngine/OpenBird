import SpriteKit

final class BirdCreatureNode: CreatureNode {
    private let nameLabel: SKLabelNode
    private let nameShadow: SKLabelNode
    private var facingRight = true
    private let wingRestAngle: CGFloat = -0.22

    init(creature: Creature, name: String, color: NSColor) {
        nameLabel = SKLabelNode(text: name)
        nameShadow = SKLabelNode(text: name)

        let birdSize = CGSize(width: 44, height: 34)
        super.init(creature: creature, name: name, color: color, texture: nil, size: birdSize)

        drawBirdBody()

        nameShadow.fontSize = 9
        nameShadow.fontName = "Menlo-Bold"
        nameShadow.fontColor = .black
        nameShadow.position = CGPoint(x: 1, y: -26)
        nameShadow.alpha = 0.45
        nameShadow.name = "nameShadow"
        addChild(nameShadow)

        nameLabel.fontSize = 9
        nameLabel.fontName = "Menlo-Bold"
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: 0, y: -25)
        nameLabel.alpha = 0.85
        nameLabel.name = "nameLabel"
        addChild(nameLabel)

        updateNameVisibility()
        updateAppearance(creature)
    }

    private func drawBirdBody() {
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 24, height: 7))
        shadow.fillColor = NSColor(white: 0.0, alpha: 0.18)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -13)
        shadow.zPosition = -3
        shadow.name = "shadow"
        addChild(shadow)

        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -14, y: 2))
        tailPath.addLine(to: CGPoint(x: -24, y: 8))
        tailPath.addLine(to: CGPoint(x: -23, y: -1))
        tailPath.closeSubpath()

        let tail = SKShapeNode(path: tailPath)
        tail.strokeColor = .clear
        tail.position = CGPoint.zero
        tail.zPosition = -1
        tail.name = "tail"
        addChild(tail)

        let body = SKShapeNode(ellipseOf: CGSize(width: 24, height: 18))
        body.strokeColor = NSColor(white: 1.0, alpha: 0.24)
        body.lineWidth = 1
        body.position = CGPoint(x: -1, y: 1)
        body.zPosition = 0
        body.name = "body"
        addChild(body)

        let head = SKShapeNode(circleOfRadius: 6)
        head.strokeColor = NSColor(white: 1.0, alpha: 0.18)
        head.lineWidth = 0.8
        head.position = CGPoint(x: 9, y: 6)
        head.zPosition = 1
        head.name = "head"
        addChild(head)

        let wingContainer = SKNode()
        wingContainer.position = CGPoint(x: -4, y: 1)
        wingContainer.zRotation = wingRestAngle
        wingContainer.zPosition = 2
        wingContainer.name = "wingContainer"
        addChild(wingContainer)

        let wing = SKShapeNode(ellipseOf: CGSize(width: 14, height: 9))
        wing.strokeColor = .clear
        wing.position = CGPoint(x: 0, y: 0)
        wing.name = "wing"
        wingContainer.addChild(wing)

        let beakPath = CGMutablePath()
        beakPath.move(to: CGPoint(x: 14, y: 7))
        beakPath.addLine(to: CGPoint(x: 20, y: 9))
        beakPath.addLine(to: CGPoint(x: 19, y: 5))
        beakPath.closeSubpath()

        let beak = SKShapeNode(path: beakPath)
        beak.fillColor = NSColor(calibratedRed: 0.96, green: 0.69, blue: 0.24, alpha: 0.98)
        beak.strokeColor = .clear
        beak.zPosition = 2
        beak.name = "beak"
        addChild(beak)

        let eye = SKShapeNode(circleOfRadius: 1.8)
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 10, y: 7)
        eye.zPosition = 3
        addChild(eye)

        let pupil = SKShapeNode(circleOfRadius: 0.85)
        pupil.fillColor = NSColor(white: 0.05, alpha: 1.0)
        pupil.strokeColor = .clear
        pupil.position = CGPoint(x: 10.6, y: 7)
        pupil.zPosition = 4
        addChild(pupil)

        let legsPath = CGMutablePath()
        legsPath.move(to: CGPoint(x: -1, y: -7))
        legsPath.addLine(to: CGPoint(x: -1, y: -13))
        legsPath.move(to: CGPoint(x: 3, y: -7))
        legsPath.addLine(to: CGPoint(x: 3, y: -13))
        legsPath.move(to: CGPoint(x: -3, y: -13))
        legsPath.addLine(to: CGPoint(x: 1, y: -13))
        legsPath.move(to: CGPoint(x: 1, y: -13))
        legsPath.addLine(to: CGPoint(x: 5, y: -13))

        let legs = SKShapeNode(path: legsPath)
        legs.strokeColor = NSColor(calibratedRed: 0.82, green: 0.58, blue: 0.18, alpha: 0.9)
        legs.lineWidth = 1.2
        legs.lineCap = .round
        legs.zPosition = -2
        legs.name = "legs"
        addChild(legs)
    }

    override func updateAppearance(_ creature: Creature) {
        super.updateAppearance(creature)

        let bodyNode = childNode(withName: "body") as? SKShapeNode
        let headNode = childNode(withName: "head") as? SKShapeNode
        let wingNode = childNode(withName: "//wing") as? SKShapeNode
        let tailNode = childNode(withName: "tail") as? SKShapeNode
        let shadowNode = childNode(withName: "shadow") as? SKShapeNode
        let legsNode = childNode(withName: "legs") as? SKShapeNode

        let mainColor: NSColor
        let wingColor: NSColor
        if !creature.isAlive {
            mainColor = NSColor(white: 0.42, alpha: 0.65)
            wingColor = NSColor(white: 0.34, alpha: 0.7)
        } else {
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            baseColor.usingColorSpace(.sRGB)?.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            let hungerFactor = 1.0 - creature.hunger * 0.45
            mainColor = NSColor(
                hue: h,
                saturation: max(0.2, s * 0.9 * hungerFactor),
                brightness: min(1.0, b * (0.72 + 0.3 * hungerFactor)),
                alpha: 0.96
            )
            wingColor = mainColor.shadow(withLevel: 0.22) ?? mainColor
        }

        bodyNode?.fillColor = mainColor
        headNode?.fillColor = mainColor
        wingNode?.fillColor = wingColor
        tailNode?.fillColor = wingColor.withAlphaComponent(0.88)
        legsNode?.alpha = creature.isAlive ? 0.9 : 0.45
        shadowNode?.alpha = creature.isAlive ? 0.16 + CGFloat((1.0 - creature.hunger) * 0.04) : 0.08

        let creatureScale = CGFloat(creature.size)
        let windowScale = windowScaleFactor()
        let finalScale = max(0.38, creatureScale * windowScale)
        let appliedX = facingRight ? finalScale : -finalScale
        xScale = appliedX
        yScale = finalScale

        nameLabel.xScale = facingRight ? 1.0 / finalScale : -1.0 / finalScale
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
        stopWingAnimation()

        guard creatureState.isAlive else {
            alpha = 0.45
            zRotation = -0.5
            run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y: -2, duration: 2.6),
                SKAction.moveBy(x: 0, y: 2, duration: 2.6)
            ])), withKey: "hovering")
            return
        }

        alpha = 1.0
        zRotation = 0
        if position == .zero {
            position = randomPerch(in: sceneSize)
        }
        planNextMove(in: sceneSize)
    }

    override func playFeedAnimation() {
        guard let scene = scene else { return }

        cancelMovement()

        let landing = randomPerch(in: scene.size)
        let points = [
            CGPoint(x: min(scene.size.width - 28, position.x + 36), y: min(scene.size.height - 30, position.y + 52)),
            CGPoint(x: scene.size.width * 0.4, y: scene.size.height * 0.76),
            landing
        ]

        runFlight(through: points, lift: 28, baseDuration: 1.5, key: "swimming") { [weak self] in
            self?.peckAndResume(in: scene.size)
        }
    }

    override func swimToFood(at point: CGPoint, food: SKNode) {
        guard let scene = scene, creatureState.isAlive else { return }

        cancelMovement()
        let target = clamp(point, in: scene.size)
        let distance = hypot(target.x - position.x, target.y - position.y)

        let completion = { [weak self, weak food] in
            if let food = food, food.parent != nil {
                food.removeAllActions()
                food.run(SKAction.sequence([
                    SKAction.scale(to: 0.1, duration: 0.12),
                    .removeFromParent()
                ]))
            }
            self?.creatureState.happiness = min(1.0, (self?.creatureState.happiness ?? 0) + 0.02)
            self?.peckAndResume(in: scene.size)
        }

        if distance > 90 {
            runFlight(through: [target], lift: 34, baseDuration: 1.0, key: "swimming", completion: completion)
        } else {
            runHop(to: target, key: "swimming", completion: completion)
        }
    }

    override func swimTowardPoint(_ target: CGPoint) {
        guard let scene = scene, creatureState.isAlive else { return }
        cancelMovement()
        runFlight(through: [clamp(target, in: scene.size)], lift: 28, baseDuration: 1.0, key: "schooling") { [weak self] in
            self?.planNextMove(in: scene.size)
        }
    }

    private func planNextMove(in sceneSize: CGSize) {
        guard creatureState.isAlive else { return }

        let roll = Double.random(in: 0...1)
        if roll < 0.58 + creatureState.happiness * 0.15 {
            perchBriefly(in: sceneSize)
        } else if roll < 0.9 {
            runHop(to: randomPerch(in: sceneSize), key: "swimming") { [weak self] in
                self?.planNextMove(in: sceneSize)
            }
        } else {
            runFlight(through: [randomPerch(in: sceneSize)], lift: 30, baseDuration: 1.15, key: "swimming") { [weak self] in
                self?.planNextMove(in: sceneSize)
            }
        }
    }

    private func perchBriefly(in sceneSize: CGSize) {
        let bobUp = SKAction.moveBy(x: 0, y: 1.5, duration: 0.25)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = bobUp.reversed()
        let bob = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))
        run(bob, withKey: "hovering")

        let wait = SKAction.wait(forDuration: Double.random(in: 2.4...5.2))
        let resume = SKAction.run { [weak self] in
            self?.removeAction(forKey: "hovering")
            self?.planNextMove(in: sceneSize)
        }
        run(SKAction.sequence([wait, resume]), withKey: "hoverTimer")
    }

    private func runHop(to target: CGPoint, key: String, completion: @escaping () -> Void) {
        let destination = target.x == position.x && target.y == position.y
            ? CGPoint(x: target.x + 24, y: target.y)
            : target
        updateFacing(toward: destination.x)
        stopWingAnimation()
        removeAction(forKey: "hovering")
        removeAction(forKey: "hoverTimer")

        let distance = hypot(destination.x - position.x, destination.y - position.y)
        let speed = max(65, 85 * CGFloat(AppSettings.shared.movementSpeed))
        let duration = TimeInterval(distance / speed).clamped(to: 0.28...0.9)
        let path = curvePath(to: destination, lift: min(28, 10 + distance * 0.08))

        let hop = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        hop.timingMode = .easeInEaseOut
        run(hop, withKey: key)
        run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.run {
                completion()
            }
        ]), withKey: "swimLoop")
    }

    private func runFlight(through points: [CGPoint], lift: CGFloat, baseDuration: TimeInterval, key: String, completion: @escaping () -> Void) {
        guard !points.isEmpty else {
            completion()
            return
        }

        let destinations = points.map { clamp($0, in: scene?.size ?? CGSize(width: 400, height: 300)) }
        if let last = destinations.last {
            updateFacing(toward: last.x)
        }

        removeAction(forKey: "hovering")
        removeAction(forKey: "hoverTimer")
        startWingAnimation()

        let path = multiCurvePath(through: destinations, lift: lift)
        let totalDistance = destinations.reduce((total: CGFloat.zero, previous: position)) { partial, next in
            let segment = hypot(next.x - partial.previous.x, next.y - partial.previous.y)
            return (partial.total + segment, next)
        }.total
        let speed = max(85, 120 * CGFloat(AppSettings.shared.movementSpeed))
        let duration = max(baseDuration, TimeInterval(totalDistance / speed))

        let flight = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        flight.timingMode = .easeInEaseOut
        run(flight, withKey: key)
        run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.run { [weak self] in
                self?.stopWingAnimation()
                completion()
            }
        ]), withKey: "swimLoop")
    }

    private func peckAndResume(in sceneSize: CGSize) {
        let peck = SKAction.sequence([
            SKAction.rotate(toAngle: 0.08, duration: 0.06),
            SKAction.rotate(toAngle: 0, duration: 0.08)
        ])
        run(peck) { [weak self] in
            self?.planNextMove(in: sceneSize)
        }
    }

    private func updateFacing(toward x: CGFloat) {
        let shouldFaceRight = x >= position.x
        guard shouldFaceRight != facingRight else { return }
        facingRight = shouldFaceRight
        updateAppearance(creatureState)
    }

    private func randomPerch(in sceneSize: CGSize) -> CGPoint {
        if let birdScene = scene as? BirdScene {
            return birdScene.randomPerchPoint()
        }

        let size = scene?.size ?? sceneSize
        let yLevels = [size.height * 0.3, size.height * 0.52, size.height * 0.72]
        return CGPoint(
            x: CGFloat.random(in: 72...max(73, size.width - 36)),
            y: yLevels.randomElement() ?? size.height * 0.52
        )
    }

    private func curvePath(to target: CGPoint, lift: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: position)
        let control = CGPoint(
            x: (position.x + target.x) / 2,
            y: max(position.y, target.y) + lift
        )
        path.addQuadCurve(to: target, control: control)
        return path
    }

    private func multiCurvePath(through points: [CGPoint], lift: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: position)
        var current = position
        for point in points {
            let control = CGPoint(
                x: (current.x + point.x) / 2,
                y: max(current.y, point.y) + lift
            )
            path.addQuadCurve(to: point, control: control)
            current = point
        }
        return path
    }

    private func startWingAnimation() {
        guard let wingContainer = childNode(withName: "wingContainer") else { return }
        wingContainer.removeAction(forKey: "flapping")
        let up = SKAction.rotate(toAngle: 0.5, duration: 0.12, shortestUnitArc: true)
        let down = SKAction.rotate(toAngle: -0.34, duration: 0.12, shortestUnitArc: true)
        wingContainer.run(SKAction.repeatForever(SKAction.sequence([up, down])), withKey: "flapping")
    }

    private func stopWingAnimation() {
        guard let wingContainer = childNode(withName: "wingContainer") else { return }
        wingContainer.removeAction(forKey: "flapping")
        wingContainer.zRotation = wingRestAngle
    }

    private func cancelMovement() {
        removeAction(forKey: "swimming")
        removeAction(forKey: "swimLoop")
        removeAction(forKey: "hovering")
        removeAction(forKey: "hoverTimer")
        removeAction(forKey: "schooling")
        stopWingAnimation()
    }

    private func clamp(_ point: CGPoint, in sceneSize: CGSize) -> CGPoint {
        CGPoint(
            x: max(28, min(sceneSize.width - 28, point.x)),
            y: max(30, min(sceneSize.height - 28, point.y))
        )
    }

    private func windowScaleFactor() -> CGFloat {
        guard let scene = scene else { return 1.0 }
        let refArea: CGFloat = 400 * 300
        let currentArea = scene.size.width * scene.size.height
        return max(0.45, min(1.45, sqrt(currentArea / refArea)))
    }
}

private extension TimeInterval {
    func clamped(to range: ClosedRange<TimeInterval>) -> TimeInterval {
        min(range.upperBound, max(range.lowerBound, self))
    }
}

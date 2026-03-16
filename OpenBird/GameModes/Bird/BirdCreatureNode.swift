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

        let leftCrestPath = CGMutablePath()
        leftCrestPath.move(to: CGPoint(x: -8, y: 15))
        leftCrestPath.addQuadCurve(to: CGPoint(x: -1, y: 20), control: CGPoint(x: -6, y: 22))
        leftCrestPath.addLine(to: CGPoint(x: 0, y: 13))
        leftCrestPath.closeSubpath()

        let leftCrest = SKShapeNode(path: leftCrestPath)
        leftCrest.strokeColor = .clear
        leftCrest.zPosition = 0
        leftCrest.name = "leftCrest"
        addChild(leftCrest)

        let centerCrestPath = CGMutablePath()
        centerCrestPath.move(to: CGPoint(x: -1, y: 15))
        centerCrestPath.addQuadCurve(to: CGPoint(x: 5, y: 22), control: CGPoint(x: 4, y: 21))
        centerCrestPath.addLine(to: CGPoint(x: 5, y: 14))
        centerCrestPath.closeSubpath()

        let centerCrest = SKShapeNode(path: centerCrestPath)
        centerCrest.strokeColor = .clear
        centerCrest.zPosition = 0
        centerCrest.name = "centerCrest"
        addChild(centerCrest)

        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: 13, y: 2))
        tailPath.addQuadCurve(to: CGPoint(x: 25, y: 10), control: CGPoint(x: 23, y: 12))
        tailPath.addQuadCurve(to: CGPoint(x: 25, y: -6), control: CGPoint(x: 28, y: 0))
        tailPath.closeSubpath()

        let tail = SKShapeNode(path: tailPath)
        tail.strokeColor = .clear
        tail.position = CGPoint.zero
        tail.zPosition = -1
        tail.name = "tail"
        addChild(tail)

        let body = SKShapeNode(ellipseOf: CGSize(width: 26, height: 20))
        body.strokeColor = NSColor(white: 1.0, alpha: 0.24)
        body.lineWidth = 1
        body.position = CGPoint(x: 0, y: 0)
        body.zPosition = 0
        body.name = "body"
        addChild(body)

        let belly = SKShapeNode(ellipseOf: CGSize(width: 18, height: 15))
        belly.strokeColor = .clear
        belly.position = CGPoint(x: -1, y: -3)
        belly.zPosition = 1
        belly.name = "belly"
        addChild(belly)

        let head = SKShapeNode(circleOfRadius: 7)
        head.strokeColor = NSColor(white: 1.0, alpha: 0.18)
        head.lineWidth = 0.8
        head.position = CGPoint(x: -6, y: 11)
        head.zPosition = 1
        head.name = "head"
        addChild(head)

        let wingContainer = SKNode()
        wingContainer.position = CGPoint(x: 4, y: 1)
        wingContainer.zRotation = wingRestAngle
        wingContainer.zPosition = 2
        wingContainer.name = "wingContainer"
        addChild(wingContainer)

        let wing = SKShapeNode(ellipseOf: CGSize(width: 18, height: 12))
        wing.strokeColor = .clear
        wing.position = CGPoint(x: 0, y: 0)
        wing.name = "wing"
        wingContainer.addChild(wing)

        let beakPath = CGMutablePath()
        beakPath.move(to: CGPoint(x: -12, y: 11))
        beakPath.addLine(to: CGPoint(x: -20, y: 14))
        beakPath.addLine(to: CGPoint(x: -12, y: 17))
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
        eye.position = CGPoint(x: -8, y: 13)
        eye.zPosition = 3
        addChild(eye)

        let pupil = SKShapeNode(circleOfRadius: 0.85)
        pupil.fillColor = NSColor(white: 0.05, alpha: 1.0)
        pupil.strokeColor = .clear
        pupil.position = CGPoint(x: -8.5, y: 13)
        pupil.zPosition = 4
        addChild(pupil)

        let leftCheek = SKShapeNode(circleOfRadius: 3.8)
        leftCheek.strokeColor = .clear
        leftCheek.position = CGPoint(x: -13, y: 8)
        leftCheek.zPosition = 2
        leftCheek.name = "leftCheek"
        addChild(leftCheek)

        let rightCheek = SKShapeNode(circleOfRadius: 3.8)
        rightCheek.strokeColor = .clear
        rightCheek.position = CGPoint(x: -1, y: 8)
        rightCheek.zPosition = 2
        rightCheek.name = "rightCheek"
        addChild(rightCheek)

        let legsPath = CGMutablePath()
        legsPath.move(to: CGPoint(x: 0, y: -8))
        legsPath.addLine(to: CGPoint(x: 0, y: -14))
        legsPath.move(to: CGPoint(x: 6, y: -8))
        legsPath.addLine(to: CGPoint(x: 6, y: -14))
        legsPath.move(to: CGPoint(x: -3, y: -14))
        legsPath.addLine(to: CGPoint(x: 1, y: -14))
        legsPath.move(to: CGPoint(x: 1, y: -14))
        legsPath.addLine(to: CGPoint(x: 5, y: -12))
        legsPath.move(to: CGPoint(x: 3, y: -14))
        legsPath.addLine(to: CGPoint(x: 7, y: -14))
        legsPath.move(to: CGPoint(x: 7, y: -14))
        legsPath.addLine(to: CGPoint(x: 11, y: -12))

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
        let bellyNode = childNode(withName: "belly") as? SKShapeNode
        let headNode = childNode(withName: "head") as? SKShapeNode
        let wingNode = childNode(withName: "//wing") as? SKShapeNode
        let tailNode = childNode(withName: "tail") as? SKShapeNode
        let shadowNode = childNode(withName: "shadow") as? SKShapeNode
        let legsNode = childNode(withName: "legs") as? SKShapeNode

        let leftCrestNode = childNode(withName: "leftCrest") as? SKShapeNode
        let centerCrestNode = childNode(withName: "centerCrest") as? SKShapeNode
        let leftCheekNode = childNode(withName: "leftCheek") as? SKShapeNode
        let rightCheekNode = childNode(withName: "rightCheek") as? SKShapeNode

        let palette = palette(for: creature)

        bodyNode?.fillColor = palette.body
        bellyNode?.fillColor = palette.belly
        headNode?.fillColor = palette.body
        wingNode?.fillColor = palette.wing
        tailNode?.fillColor = palette.wingBright
        leftCrestNode?.fillColor = palette.crestOuter
        centerCrestNode?.fillColor = palette.crestInner
        leftCheekNode?.fillColor = palette.cheek
        rightCheekNode?.fillColor = palette.cheek
        legsNode?.alpha = creature.isAlive ? 0.9 : 0.45
        shadowNode?.alpha = creature.isAlive ? 0.16 + CGFloat((1.0 - creature.hunger) * 0.04) : 0.08

        let creatureScale = CGFloat(creature.size)
        let windowScale = windowScaleFactor()
        let finalScale = max(0.38, creatureScale * windowScale)
        let appliedX = facingRight ? -finalScale : finalScale
        xScale = appliedX
        yScale = finalScale

        nameLabel.xScale = facingRight ? -1.0 / finalScale : 1.0 / finalScale
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
            CGPoint(x: min(scene.size.width - 36, position.x + 60), y: min(scene.size.height - 28, position.y + 70)),
            CGPoint(x: scene.size.width * 0.45, y: scene.size.height * 0.84),
            CGPoint(x: scene.size.width * 0.72, y: scene.size.height * 0.7),
            landing
        ]

        runFlight(through: points, lift: 40, baseDuration: 2.0, key: "swimming") { [weak self] in
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
        if roll < 0.82 + creatureState.happiness * 0.12 {
            perchBriefly(in: sceneSize)
        } else if roll < 0.97 {
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

        let wait = SKAction.wait(forDuration: Double.random(in: 4.0...8.0))
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
        let speed = max(55, 72 * CGFloat(AppSettings.shared.movementSpeed))
        let duration = TimeInterval(distance / speed).clamped(to: 0.32...1.0)
        let path = curvePath(to: destination, lift: min(22, 8 + distance * 0.06))

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
        let speed = max(90, 130 * CGFloat(AppSettings.shared.movementSpeed))
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

    private func palette(for creature: Creature) -> BirdPalette {
        if !creature.isAlive {
            return BirdPalette(
                body: NSColor(white: 0.42, alpha: 0.65),
                belly: NSColor(white: 0.54, alpha: 0.66),
                wing: NSColor(white: 0.34, alpha: 0.7),
                wingBright: NSColor(white: 0.46, alpha: 0.72),
                crestOuter: NSColor(white: 0.34, alpha: 0.68),
                crestInner: NSColor(white: 0.52, alpha: 0.68),
                cheek: NSColor(white: 0.66, alpha: 0.4)
            )
        }

        if creature.totalCommitsFed >= 1000 {
            return BirdPalette(
                body: NSColor(calibratedRed: 1.0, green: 0.94, blue: 0.73, alpha: 0.98),
                belly: NSColor(calibratedRed: 0.98, green: 0.82, blue: 0.38, alpha: 0.98),
                wing: NSColor(calibratedRed: 0.94, green: 0.72, blue: 0.22, alpha: 0.98),
                wingBright: NSColor(calibratedRed: 1.0, green: 0.84, blue: 0.38, alpha: 0.98),
                crestOuter: NSColor(calibratedRed: 0.94, green: 0.72, blue: 0.22, alpha: 0.98),
                crestInner: NSColor(calibratedRed: 0.98, green: 0.82, blue: 0.38, alpha: 0.98),
                cheek: NSColor(calibratedRed: 1.0, green: 0.81, blue: 0.68, alpha: 0.74)
            )
        }

        return BirdPalette(
            body: NSColor(calibratedRed: 1.0, green: 0.96, blue: 0.86, alpha: 0.98),
            belly: NSColor(calibratedRed: 0.95, green: 0.77, blue: 0.42, alpha: 0.98),
            wing: NSColor(calibratedRed: 0.42, green: 0.63, blue: 0.5, alpha: 0.98),
            wingBright: NSColor(calibratedRed: 0.56, green: 0.73, blue: 0.54, alpha: 0.98),
            crestOuter: NSColor(calibratedRed: 0.29, green: 0.54, blue: 0.4, alpha: 0.98),
            crestInner: NSColor(calibratedRed: 0.95, green: 0.77, blue: 0.42, alpha: 0.98),
            cheek: NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.78, alpha: 0.7)
        )
    }
}

private extension TimeInterval {
    func clamped(to range: ClosedRange<TimeInterval>) -> TimeInterval {
        min(range.upperBound, max(range.lowerBound, self))
    }
}

private struct BirdPalette {
    let body: NSColor
    let belly: NSColor
    let wing: NSColor
    let wingBright: NSColor
    let crestOuter: NSColor
    let crestInner: NSColor
    let cheek: NSColor
}

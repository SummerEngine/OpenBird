import SpriteKit
import QuartzCore

private enum BirdPose {
    case idle
    case moving
    case resting
}

final class BirdCreatureNode: CreatureNode {
    let nameLabel: SKLabelNode
    let nameShadow: SKLabelNode
    let motionContainer = SKNode()
    let idleContainer = SKNode()
    private var facingRight = true
    let motionWingRestAngle: CGFloat = -0.22
    private var isJamming = false
    private var jamBasePosition = CGPoint.zero
    private let jamPhase = CGFloat.random(in: 0...(CGFloat.pi * 2))

    init(creature: Creature, name: String, color: NSColor) {
        nameLabel = SKLabelNode(text: name)
        nameShadow = SKLabelNode(text: name)

        super.init(creature: creature, name: name, color: color, texture: nil, size: CGSize(width: 48, height: 38))

        drawBirdBody()
        configureNameLabels()
        updateNameVisibility()
        updateAppearance(creature)
        setPose(creature.isAlive ? .idle : .resting)
    }

    override func updateAppearance(_ creature: Creature) {
        super.updateAppearance(creature)

        let birdPalette = palette(for: creature)
        let shadowNode = childNode(withName: "shadow") as? SKShapeNode

        let motionBody = childNode(withName: "//motionBody") as? SKShapeNode
        let motionBelly = childNode(withName: "//motionBelly") as? SKShapeNode
        let motionHead = childNode(withName: "//motionHead") as? SKShapeNode
        let motionWing = childNode(withName: "//motionWing") as? SKShapeNode
        let motionTail = childNode(withName: "//motionTail") as? SKShapeNode
        let motionLeftCrest = childNode(withName: "//motionLeftCrest") as? SKShapeNode
        let motionCenterCrest = childNode(withName: "//motionCenterCrest") as? SKShapeNode
        let motionLeftCheek = childNode(withName: "//motionLeftCheek") as? SKShapeNode
        let motionRightCheek = childNode(withName: "//motionRightCheek") as? SKShapeNode
        let motionLegs = childNode(withName: "//motionLegs") as? SKShapeNode

        motionBody?.fillColor = birdPalette.body
        motionBelly?.fillColor = birdPalette.belly
        motionHead?.fillColor = birdPalette.body
        motionWing?.fillColor = birdPalette.wing
        motionTail?.fillColor = birdPalette.wingBright
        motionLeftCrest?.fillColor = birdPalette.crestOuter
        motionCenterCrest?.fillColor = birdPalette.crestInner
        motionLeftCheek?.fillColor = birdPalette.cheek
        motionRightCheek?.fillColor = birdPalette.cheek
        motionLegs?.alpha = creature.isAlive ? 0.9 : 0.45

        let idleHead = childNode(withName: "//idleHead") as? SKShapeNode
        let idleBody = childNode(withName: "//idleBody") as? SKShapeNode
        let idleBelly = childNode(withName: "//idleBelly") as? SKShapeNode
        let idleLeftWing = childNode(withName: "//idleLeftWing") as? SKShapeNode
        let idleRightWing = childNode(withName: "//idleRightWing") as? SKShapeNode
        let idleLeftCrest = childNode(withName: "//idleLeftCrest") as? SKShapeNode
        let idleCenterCrest = childNode(withName: "//idleCenterCrest") as? SKShapeNode
        let idleRightCrest = childNode(withName: "//idleRightCrest") as? SKShapeNode
        let idleLeftCheek = childNode(withName: "//idleLeftCheek") as? SKShapeNode
        let idleRightCheek = childNode(withName: "//idleRightCheek") as? SKShapeNode
        let idleTailPrimary = childNode(withName: "//idleTailPrimary") as? SKShapeNode
        let idleTailSecondary = childNode(withName: "//idleTailSecondary") as? SKShapeNode
        let idleFeet = childNode(withName: "//idleFeet") as? SKShapeNode

        idleHead?.fillColor = birdPalette.body
        idleBody?.fillColor = birdPalette.body
        idleBelly?.fillColor = birdPalette.belly
        idleLeftWing?.fillColor = birdPalette.wing
        idleRightWing?.fillColor = birdPalette.wing
        idleLeftCrest?.fillColor = birdPalette.crestOuter
        idleCenterCrest?.fillColor = birdPalette.crestInner
        idleRightCrest?.fillColor = birdPalette.crestOuter
        idleLeftCheek?.fillColor = birdPalette.cheek
        idleRightCheek?.fillColor = birdPalette.cheek
        idleTailPrimary?.strokeColor = birdPalette.wing
        idleTailSecondary?.strokeColor = birdPalette.wingBright
        idleFeet?.alpha = creature.isAlive ? 0.9 : 0.45

        shadowNode?.alpha = creature.isAlive ? 0.16 + CGFloat((1.0 - creature.hunger) * 0.04) : 0.08

        let finalScale = max(0.38, CGFloat(creature.size) * windowScaleFactor())
        xScale = finalScale
        yScale = finalScale

        motionContainer.xScale = facingRight ? -1 : 1
        motionContainer.yScale = 1
        idleContainer.xScale = 1
        idleContainer.yScale = 1

        nameLabel.xScale = 1.0 / finalScale
        nameLabel.yScale = 1.0 / finalScale
        nameShadow.xScale = nameLabel.xScale
        nameShadow.yScale = nameLabel.yScale

        if childNode(withName: "selectionOutline") != nil {
            updateSelectionOutline()
        }
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
        isJamming = false
        cancelMovement()

        guard creatureState.isAlive else {
            alpha = 0.45
            zRotation = -0.5
            setPose(.resting)
            run(
                SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.moveBy(x: 0, y: -2, duration: 2.6),
                        SKAction.moveBy(x: 0, y: 2, duration: 2.6)
                    ])
                ),
                withKey: "hovering"
            )
            return
        }

        alpha = 1.0
        zRotation = 0
        if position == .zero {
            position = reservedPerch(in: sceneSize, avoidCurrent: false)
        }
        setPose(.idle)
        planNextMove(in: sceneSize)
    }

    override func beginJamMode() {
        guard creatureState.isAlive else { return }

        isJamming = true
        cancelMovement()
        setPose(.idle)
        stopIdleAnimation()
        jamBasePosition = position
        zRotation = 0
    }

    override func endJamMode(resumeIn sceneSize: CGSize) {
        guard isJamming else {
            startIdleBehavior(in: sceneSize)
            return
        }

        isJamming = false
        position = jamBasePosition == .zero ? position : jamBasePosition
        zRotation = 0
        idleContainer.position = .zero
        resetJamPose()
        startIdleBehavior(in: sceneSize)
    }

    override func updateJam(level: CGFloat, beat: CGFloat) {
        guard isJamming else { return }

        let time = CGFloat(CACurrentMediaTime())
        let groove = level * 0.55
        let bounce = 0.7 + groove * 1.5 + beat * 4.6
        let sway = sin(time * 1.9 + jamPhase) * (0.018 + groove * 0.03) + beat * 0.03
        let wingLift = 0.03 + groove * 0.05 + beat * 0.16

        position = CGPoint(
            x: jamBasePosition.x,
            y: jamBasePosition.y + abs(sin(time * 2.0 + jamPhase)) * bounce
        )
        zRotation = sway
        idleContainer.position.y = sin(time * 4.2 + jamPhase) * (0.3 + groove * 0.7)

        if let leftWing = childNode(withName: "//idleLeftWingContainer") {
            leftWing.zRotation = -0.08 - wingLift + sway * 0.6
        }
        if let rightWing = childNode(withName: "//idleRightWingContainer") {
            rightWing.zRotation = 0.08 + wingLift - sway * 0.6
        }
        if let crestGroup = childNode(withName: "//idleCrestGroup") {
            crestGroup.zRotation = sin(time * 3.8 + jamPhase) * (0.012 + beat * 0.05)
        }
        if let beak = childNode(withName: "//idleBeak") {
            beak.position = CGPoint(x: 0, y: 10 + abs(sin(time * 4.4 + jamPhase)) * (0.18 + beat * 0.55))
        }
    }

    override func playFeedAnimation() {
        guard let scene = scene else { return }

        cancelMovement()

        let landing = reservedPerch(in: scene.size)
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
            runHop(to: reservedPerch(in: sceneSize), key: "swimming") { [weak self] in
                self?.planNextMove(in: sceneSize)
            }
        } else {
            runFlight(through: [reservedPerch(in: sceneSize)], lift: 30, baseDuration: 1.15, key: "swimming") { [weak self] in
                self?.planNextMove(in: sceneSize)
            }
        }
    }

    private func perchBriefly(in sceneSize: CGSize) {
        setPose(.idle)
        removeAction(forKey: "hovering")

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
        setPose(.moving)
        stopMotionWingAnimation()
        removeAction(forKey: "hovering")
        removeAction(forKey: "hoverTimer")

        let distance = hypot(destination.x - position.x, destination.y - position.y)
        let speed = max(55, 72 * CGFloat(AppSettings.shared.movementSpeed))
        let duration = TimeInterval(distance / speed).clamped(to: 0.32...1.0)
        let path = curvePath(to: destination, lift: min(22, 8 + distance * 0.06))

        let hop = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        hop.timingMode = .easeInEaseOut
        run(hop, withKey: key)
        run(
            SKAction.sequence([
                SKAction.wait(forDuration: duration),
                SKAction.run(completion)
            ]),
            withKey: "swimLoop"
        )
    }

    private func runFlight(
        through points: [CGPoint],
        lift: CGFloat,
        baseDuration: TimeInterval,
        key: String,
        completion: @escaping () -> Void
    ) {
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
        setPose(.moving)
        startMotionWingAnimation()

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
        run(
            SKAction.sequence([
                SKAction.wait(forDuration: duration),
                SKAction.run { [weak self] in
                    self?.stopMotionWingAnimation()
                    completion()
                }
            ]),
            withKey: "swimLoop"
        )
    }

    private func peckAndResume(in sceneSize: CGSize) {
        setPose(.moving)
        let peck = SKAction.sequence([
            SKAction.rotate(toAngle: 0.08, duration: 0.06),
            SKAction.rotate(toAngle: 0, duration: 0.08)
        ])
        run(peck) { [weak self] in
            self?.planNextMove(in: sceneSize)
        }
    }

    private func setPose(_ pose: BirdPose) {
        switch pose {
        case .idle:
            idleContainer.isHidden = false
            motionContainer.isHidden = true
            stopMotionWingAnimation()
            startIdleAnimation()
        case .moving:
            idleContainer.isHidden = true
            motionContainer.isHidden = false
            stopIdleAnimation()
        case .resting:
            idleContainer.isHidden = true
            motionContainer.isHidden = false
            stopIdleAnimation()
            stopMotionWingAnimation()
        }
    }

    private func startIdleAnimation() {
        idleContainer.removeAction(forKey: "idleFloat")
        idleContainer.zRotation = 0

        animateIdleNode(named: "idleLeftWingContainer", startAngle: 0, endAngle: -0.21, key: "idleSway", duration: 1.5)
        animateIdleNode(named: "idleRightWingContainer", startAngle: 0, endAngle: 0.21, key: "idleSway", duration: 1.5)
        animateIdleNode(named: "idleTailGroup", startAngle: 0, endAngle: 0.14, key: "idleTail", duration: 1.9)
        animateIdleNode(named: "idleLeftCrest", startAngle: 0, endAngle: -0.12, key: "idleCrest", duration: 2.1)
        animateIdleNode(named: "idleCenterCrest", startAngle: 0, endAngle: -0.03, key: "idleCrest", duration: 2.1)
        animateIdleNode(named: "idleRightCrest", startAngle: 0, endAngle: 0.12, key: "idleCrest", duration: 2.1)

        if let beak = childNode(withName: "//idleBeak") {
            beak.removeAction(forKey: "idleBop")
            let bop = SKAction.sequence([
                SKAction.moveBy(x: 0, y: -0.16, duration: 2.4),
                SKAction.moveBy(x: 0, y: 0.16, duration: 2.4)
            ])
            beak.run(SKAction.repeatForever(bop), withKey: "idleBop")
        }

        startBlinkLoop()
    }

    private func stopIdleAnimation() {
        idleContainer.removeAction(forKey: "idleFloat")
        idleContainer.zRotation = 0
        if let leftWing = childNode(withName: "//idleLeftWingContainer") {
            leftWing.removeAction(forKey: "idleSway")
            leftWing.zRotation = 0
        }
        if let rightWing = childNode(withName: "//idleRightWingContainer") {
            rightWing.removeAction(forKey: "idleSway")
            rightWing.zRotation = 0
        }
        if let tailGroup = childNode(withName: "//idleTailGroup") {
            tailGroup.removeAction(forKey: "idleTail")
            tailGroup.zRotation = 0
        }
        for crestName in ["idleLeftCrest", "idleCenterCrest", "idleRightCrest"] {
            if let crest = childNode(withName: "//\(crestName)") {
                crest.removeAction(forKey: "idleCrest")
                crest.zRotation = 0
            }
        }
        if let beak = childNode(withName: "//idleBeak") {
            beak.removeAction(forKey: "idleBop")
            beak.position = .zero
        }
        for eyeName in ["idleLeftEyeContainer", "idleRightEyeContainer"] {
            if let eye = childNode(withName: "//\(eyeName)") {
                eye.removeAction(forKey: "blink")
                eye.yScale = 1
            }
        }
        removeAction(forKey: "blinkLoop")
    }

    private func resetJamPose() {
        if let leftWing = childNode(withName: "//idleLeftWingContainer") {
            leftWing.zRotation = 0
        }
        if let rightWing = childNode(withName: "//idleRightWingContainer") {
            rightWing.zRotation = 0
        }
        if let tailGroup = childNode(withName: "//idleTailGroup") {
            tailGroup.zRotation = 0
        }
        for crestName in ["idleLeftCrest", "idleCenterCrest", "idleRightCrest"] {
            if let crest = childNode(withName: "//\(crestName)") {
                crest.zRotation = 0
            }
        }
        if let beak = childNode(withName: "//idleBeak") {
            beak.position = .zero
        }
    }

    private func animateIdleNode(
        named name: String,
        startAngle: CGFloat,
        endAngle: CGFloat,
        key: String,
        duration: TimeInterval = 1.25
    ) {
        guard let node = childNode(withName: "//\(name)") else { return }
        node.removeAction(forKey: key)
        node.zRotation = startAngle
        let toEnd = SKAction.rotate(toAngle: endAngle, duration: duration, shortestUnitArc: true)
        let toStart = SKAction.rotate(toAngle: startAngle, duration: duration, shortestUnitArc: true)
        toEnd.timingMode = .easeInEaseOut
        toStart.timingMode = .easeInEaseOut
        node.run(SKAction.repeatForever(SKAction.sequence([toEnd, toStart])), withKey: key)
    }

    private func startBlinkLoop() {
        removeAction(forKey: "blinkLoop")
        scheduleNextBlink()
    }

    private func scheduleNextBlink() {
        let wait = SKAction.wait(forDuration: Double.random(in: 2.6...5.6))
        let blink = SKAction.run { [weak self] in
            self?.performBlink()
            self?.scheduleNextBlink()
        }
        run(SKAction.sequence([wait, blink]), withKey: "blinkLoop")
    }

    private func performBlink() {
        let close = SKAction.scaleY(to: 0.16, duration: 0.08)
        let open = SKAction.scaleY(to: 1, duration: 0.11)
        close.timingMode = .easeInEaseOut
        open.timingMode = .easeInEaseOut

        for eyeName in ["idleLeftEyeContainer", "idleRightEyeContainer"] {
            if let eye = childNode(withName: "//\(eyeName)") {
                eye.removeAction(forKey: "blink")
                eye.run(SKAction.sequence([close, open]), withKey: "blink")
            }
        }
    }

    private func updateFacing(toward x: CGFloat) {
        let shouldFaceRight = x >= position.x
        guard shouldFaceRight != facingRight else { return }
        facingRight = shouldFaceRight
        updateAppearance(creatureState)
    }

    private func reservedPerch(in sceneSize: CGSize, avoidCurrent: Bool = true) -> CGPoint {
        if let birdScene = scene as? BirdScene {
            return birdScene.reservePerchPoint(
                for: self,
                near: clamp(position == .zero ? CGPoint(x: sceneSize.width * 0.55, y: sceneSize.height * 0.5) : position, in: sceneSize),
                avoidCurrent: avoidCurrent
            )
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

    private func startMotionWingAnimation() {
        guard let wingContainer = childNode(withName: "//motionWingContainer") else { return }
        wingContainer.removeAction(forKey: "flapping")
        let up = SKAction.rotate(toAngle: 0.5, duration: 0.12, shortestUnitArc: true)
        let down = SKAction.rotate(toAngle: -0.34, duration: 0.12, shortestUnitArc: true)
        wingContainer.run(SKAction.repeatForever(SKAction.sequence([up, down])), withKey: "flapping")
    }

    private func stopMotionWingAnimation() {
        guard let wingContainer = childNode(withName: "//motionWingContainer") else { return }
        wingContainer.removeAction(forKey: "flapping")
        wingContainer.zRotation = motionWingRestAngle
    }

    private func cancelMovement() {
        removeAction(forKey: "swimming")
        removeAction(forKey: "swimLoop")
        removeAction(forKey: "hovering")
        removeAction(forKey: "hoverTimer")
        removeAction(forKey: "schooling")
        stopIdleAnimation()
        stopMotionWingAnimation()
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

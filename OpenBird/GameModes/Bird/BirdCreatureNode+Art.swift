import SpriteKit

extension BirdCreatureNode {
    func configureNameLabels() {
        nameShadow.fontSize = 9
        nameShadow.fontName = "Menlo-Bold"
        nameShadow.fontColor = .black
        nameShadow.position = CGPoint(x: 1, y: -28)
        nameShadow.alpha = 0.45
        nameShadow.name = "nameShadow"
        addChild(nameShadow)

        nameLabel.fontSize = 9
        nameLabel.fontName = "Menlo-Bold"
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: 0, y: -27)
        nameLabel.alpha = 0.85
        nameLabel.name = "nameLabel"
        addChild(nameLabel)
    }

    func drawBirdBody() {
        addShadow()

        motionContainer.name = "motionContainer"
        motionContainer.zPosition = 0
        addChild(motionContainer)
        drawMotionBird()

        idleContainer.name = "idleContainer"
        idleContainer.zPosition = 0
        addChild(idleContainer)
        drawIdleBird()
    }

    func palette(for creature: Creature) -> BirdPalette {
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

    private func addShadow() {
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 24, height: 7))
        shadow.fillColor = NSColor(white: 0.0, alpha: 0.18)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -14)
        shadow.zPosition = -3
        shadow.name = "shadow"
        addChild(shadow)
    }

    private func drawMotionBird() {
        let leftCrest = makeFilledNode(path: path {
            $0.move(to: CGPoint(x: -8, y: 15))
            $0.addQuadCurve(to: CGPoint(x: -1, y: 20), control: CGPoint(x: -6, y: 22))
            $0.addLine(to: CGPoint(x: 0, y: 13))
            $0.closeSubpath()
        }, name: "motionLeftCrest")
        leftCrest.zPosition = 0
        motionContainer.addChild(leftCrest)

        let centerCrest = makeFilledNode(path: path {
            $0.move(to: CGPoint(x: -1, y: 15))
            $0.addQuadCurve(to: CGPoint(x: 5, y: 22), control: CGPoint(x: 4, y: 21))
            $0.addLine(to: CGPoint(x: 5, y: 14))
            $0.closeSubpath()
        }, name: "motionCenterCrest")
        centerCrest.zPosition = 0
        motionContainer.addChild(centerCrest)

        let tail = makeFilledNode(path: path {
            $0.move(to: CGPoint(x: 13, y: 2))
            $0.addQuadCurve(to: CGPoint(x: 25, y: 10), control: CGPoint(x: 23, y: 12))
            $0.addQuadCurve(to: CGPoint(x: 25, y: -6), control: CGPoint(x: 28, y: 0))
            $0.closeSubpath()
        }, name: "motionTail")
        tail.zPosition = -1
        motionContainer.addChild(tail)

        let body = SKShapeNode(ellipseOf: CGSize(width: 26, height: 20))
        body.strokeColor = NSColor(white: 1.0, alpha: 0.24)
        body.lineWidth = 1
        body.zPosition = 0
        body.name = "motionBody"
        motionContainer.addChild(body)

        let belly = SKShapeNode(ellipseOf: CGSize(width: 18, height: 15))
        belly.strokeColor = .clear
        belly.position = CGPoint(x: -1, y: -3)
        belly.zPosition = 1
        belly.name = "motionBelly"
        motionContainer.addChild(belly)

        let head = SKShapeNode(circleOfRadius: 7)
        head.strokeColor = NSColor(white: 1.0, alpha: 0.18)
        head.lineWidth = 0.8
        head.position = CGPoint(x: -6, y: 11)
        head.zPosition = 1
        head.name = "motionHead"
        motionContainer.addChild(head)

        let wingContainer = SKNode()
        wingContainer.position = CGPoint(x: 4, y: 1)
        wingContainer.zRotation = motionWingRestAngle
        wingContainer.zPosition = 2
        wingContainer.name = "motionWingContainer"
        motionContainer.addChild(wingContainer)

        let wing = SKShapeNode(ellipseOf: CGSize(width: 18, height: 12))
        wing.strokeColor = .clear
        wing.name = "motionWing"
        wingContainer.addChild(wing)

        let beak = makeFilledNode(path: path {
            $0.move(to: CGPoint(x: -12, y: 11))
            $0.addLine(to: CGPoint(x: -20, y: 14))
            $0.addLine(to: CGPoint(x: -12, y: 17))
            $0.closeSubpath()
        }, fillColor: NSColor(calibratedRed: 0.96, green: 0.69, blue: 0.24, alpha: 0.98))
        beak.zPosition = 2
        motionContainer.addChild(beak)

        let eye = SKShapeNode(ellipseOf: CGSize(width: 3.1, height: 4.4))
        eye.fillColor = NSColor(white: 0.08, alpha: 1.0)
        eye.strokeColor = .clear
        eye.position = CGPoint(x: -8.2, y: 13)
        eye.zPosition = 3
        eye.name = "motionEye"
        motionContainer.addChild(eye)

        let highlight = circleNode(radius: 0.65, fillColor: .white)
        highlight.position = CGPoint(x: -7.5, y: 13.9)
        highlight.zPosition = 4
        highlight.name = "motionEyeSparkle"
        motionContainer.addChild(highlight)

        let leftCheek = circleNode(radius: 3.8, fillColor: .white)
        leftCheek.position = CGPoint(x: -13, y: 8)
        leftCheek.zPosition = 2
        leftCheek.name = "motionLeftCheek"
        motionContainer.addChild(leftCheek)

        let rightCheek = circleNode(radius: 3.8, fillColor: .white)
        rightCheek.position = CGPoint(x: -1, y: 8)
        rightCheek.zPosition = 2
        rightCheek.name = "motionRightCheek"
        motionContainer.addChild(rightCheek)

        let legs = makeStrokeNode(path: path {
            $0.move(to: CGPoint(x: 0, y: -8))
            $0.addLine(to: CGPoint(x: 0, y: -14))
            $0.move(to: CGPoint(x: 6, y: -8))
            $0.addLine(to: CGPoint(x: 6, y: -14))
            $0.move(to: CGPoint(x: -3, y: -14))
            $0.addLine(to: CGPoint(x: 1, y: -14))
            $0.move(to: CGPoint(x: 1, y: -14))
            $0.addLine(to: CGPoint(x: 5, y: -12))
            $0.move(to: CGPoint(x: 3, y: -14))
            $0.addLine(to: CGPoint(x: 7, y: -14))
            $0.move(to: CGPoint(x: 7, y: -14))
            $0.addLine(to: CGPoint(x: 11, y: -12))
        }, strokeColor: NSColor(calibratedRed: 0.82, green: 0.58, blue: 0.18, alpha: 0.9), lineWidth: 1.2, name: "motionLegs")
        legs.zPosition = -2
        motionContainer.addChild(legs)
    }

    private func drawIdleBird() {
        let mascotRoot = SKNode()
        mascotRoot.name = "idleMascotRoot"
        mascotRoot.position = CGPoint(x: -23, y: 24)
        mascotRoot.xScale = 0.145
        mascotRoot.yScale = -0.145
        idleContainer.addChild(mascotRoot)

        let tailGroup = SKNode()
        tailGroup.position = .zero
        tailGroup.zPosition = -1
        tailGroup.name = "idleTailGroup"
        mascotRoot.addChild(tailGroup)

        tailGroup.addChild(makeStrokeNode(path: path {
            $0.move(to: CGPoint(x: 216, y: 200))
            $0.addCurve(to: CGPoint(x: 280, y: 224), control1: CGPoint(x: 250, y: 194), control2: CGPoint(x: 268, y: 204))
            $0.addCurve(to: CGPoint(x: 218, y: 229), control1: CGPoint(x: 256, y: 230), control2: CGPoint(x: 240, y: 232))
        }, strokeColor: NSColor(calibratedRed: 0.29, green: 0.54, blue: 0.4, alpha: 0.98), lineWidth: 18, name: "idleTailPrimary"))

        tailGroup.addChild(makeStrokeNode(path: path {
            $0.move(to: CGPoint(x: 212, y: 178))
            $0.addCurve(to: CGPoint(x: 282, y: 170), control1: CGPoint(x: 240, y: 158), control2: CGPoint(x: 260, y: 156))
            $0.addCurve(to: CGPoint(x: 228, y: 204), control1: CGPoint(x: 264, y: 187), control2: CGPoint(x: 250, y: 197))
        }, strokeColor: NSColor(calibratedRed: 0.56, green: 0.73, blue: 0.54, alpha: 0.98), lineWidth: 14, name: "idleTailSecondary"))

        let leftWingContainer = SKNode()
        leftWingContainer.position = CGPoint(x: 131, y: 202)
        leftWingContainer.zPosition = 0
        leftWingContainer.name = "idleLeftWingContainer"
        mascotRoot.addChild(leftWingContainer)
        leftWingContainer.addChild(makeFilledNode(path: path {
            $0.move(to: CGPoint(x: -15, y: -48))
            $0.addCurve(to: CGPoint(x: -66, y: 28), control1: CGPoint(x: -55, y: -38), control2: CGPoint(x: -78, y: -5))
            $0.addCurve(to: CGPoint(x: 5, y: -13), control1: CGPoint(x: -56, y: 57), control2: CGPoint(x: -26, y: 71))
            $0.addCurve(to: CGPoint(x: -15, y: -48), control1: CGPoint(x: -15, y: -31), control2: CGPoint(x: -17, y: -38))
            $0.closeSubpath()
        }, name: "idleLeftWing"))
        leftWingContainer.addChild(makeStrokeNode(path: path {
            $0.move(to: CGPoint(x: -16, y: -31))
            $0.addQuadCurve(to: CGPoint(x: -45, y: 9), control: CGPoint(x: -42, y: -23))
        }, strokeColor: NSColor(calibratedRed: 0.85, green: 0.93, blue: 0.85, alpha: 1.0), lineWidth: 6))

        let rightWingContainer = SKNode()
        rightWingContainer.position = CGPoint(x: 189, y: 202)
        rightWingContainer.zPosition = 0
        rightWingContainer.name = "idleRightWingContainer"
        mascotRoot.addChild(rightWingContainer)
        rightWingContainer.addChild(makeFilledNode(path: path {
            $0.move(to: CGPoint(x: 15, y: -48))
            $0.addCurve(to: CGPoint(x: 66, y: 28), control1: CGPoint(x: 55, y: -38), control2: CGPoint(x: 78, y: -5))
            $0.addCurve(to: CGPoint(x: -5, y: -13), control1: CGPoint(x: 56, y: 57), control2: CGPoint(x: 26, y: 71))
            $0.addCurve(to: CGPoint(x: 15, y: -48), control1: CGPoint(x: 15, y: -31), control2: CGPoint(x: 17, y: -38))
            $0.closeSubpath()
        }, name: "idleRightWing"))
        rightWingContainer.addChild(makeStrokeNode(path: path {
            $0.move(to: CGPoint(x: 16, y: -31))
            $0.addQuadCurve(to: CGPoint(x: 45, y: 9), control: CGPoint(x: 42, y: -23))
        }, strokeColor: NSColor(calibratedRed: 0.85, green: 0.93, blue: 0.85, alpha: 1.0), lineWidth: 6))

        let head = SKShapeNode(circleOfRadius: 56)
        head.strokeColor = .clear
        head.position = CGPoint(x: 160, y: 109)
        head.zPosition = 2
        head.name = "idleHead"
        mascotRoot.addChild(head)

        let body = SKShapeNode(ellipseOf: CGSize(width: 156, height: 172))
        body.strokeColor = .clear
        body.position = CGPoint(x: 160, y: 208)
        body.zPosition = 1
        body.name = "idleBody"
        mascotRoot.addChild(body)

        let belly = SKShapeNode(ellipseOf: CGSize(width: 96, height: 112))
        belly.strokeColor = .clear
        belly.position = CGPoint(x: 160, y: 214)
        belly.zPosition = 2
        belly.name = "idleBelly"
        mascotRoot.addChild(belly)

        let leftCrest = makeFilledNode(path: path {
            $0.move(to: CGPoint(x: 147, y: 40))
            $0.addCurve(to: CGPoint(x: 101, y: 27), control1: CGPoint(x: 131, y: 20), control2: CGPoint(x: 116, y: 16))
            $0.addCurve(to: CGPoint(x: 132, y: 56), control1: CGPoint(x: 112, y: 32), control2: CGPoint(x: 123, y: 41))
            $0.closeSubpath()
        }, name: "idleLeftCrest")
        leftCrest.zPosition = 3
        mascotRoot.addChild(leftCrest)

        let rightCrest = makeFilledNode(path: path {
            $0.move(to: CGPoint(x: 173, y: 40))
            $0.addCurve(to: CGPoint(x: 219, y: 27), control1: CGPoint(x: 189, y: 20), control2: CGPoint(x: 204, y: 16))
            $0.addCurve(to: CGPoint(x: 188, y: 56), control1: CGPoint(x: 208, y: 32), control2: CGPoint(x: 197, y: 41))
            $0.closeSubpath()
        }, name: "idleRightCrest")
        rightCrest.zPosition = 3
        mascotRoot.addChild(rightCrest)

        let centerCrest = makeFilledNode(path: path {
            $0.move(to: CGPoint(x: 160, y: 31))
            $0.addCurve(to: CGPoint(x: 123, y: 7), control1: CGPoint(x: 152, y: 12), control2: CGPoint(x: 139, y: 4))
            $0.addCurve(to: CGPoint(x: 149, y: 44), control1: CGPoint(x: 135, y: 16), control2: CGPoint(x: 145, y: 29))
            $0.closeSubpath()
        }, name: "idleCenterCrest")
        centerCrest.zPosition = 4
        mascotRoot.addChild(centerCrest)

        let leftEyeContainer = SKNode()
        leftEyeContainer.position = CGPoint(x: 130, y: 128)
        leftEyeContainer.zPosition = 5
        leftEyeContainer.name = "idleLeftEyeContainer"
        mascotRoot.addChild(leftEyeContainer)
        leftEyeContainer.addChild(circleNode(radius: 12, fillColor: NSColor(white: 0.1, alpha: 1.0)))
        let leftEyeHighlight = circleNode(radius: 3.5, fillColor: .white)
        leftEyeHighlight.position = CGPoint(x: 3, y: -2)
        leftEyeHighlight.name = "idleLeftEyeHighlight"
        leftEyeContainer.addChild(leftEyeHighlight)

        let rightEyeContainer = SKNode()
        rightEyeContainer.position = CGPoint(x: 190, y: 128)
        rightEyeContainer.zPosition = 5
        rightEyeContainer.name = "idleRightEyeContainer"
        mascotRoot.addChild(rightEyeContainer)
        rightEyeContainer.addChild(circleNode(radius: 12, fillColor: NSColor(white: 0.1, alpha: 1.0)))
        let rightEyeHighlight = circleNode(radius: 3.5, fillColor: .white)
        rightEyeHighlight.position = CGPoint(x: 3, y: -2)
        rightEyeHighlight.name = "idleRightEyeHighlight"
        rightEyeContainer.addChild(rightEyeHighlight)

        let leftCheek = circleNode(radius: 11, fillColor: .white)
        leftCheek.position = CGPoint(x: 116, y: 145)
        leftCheek.zPosition = 4
        leftCheek.alpha = 0.75
        leftCheek.name = "idleLeftCheek"
        mascotRoot.addChild(leftCheek)

        let rightCheek = circleNode(radius: 11, fillColor: .white)
        rightCheek.position = CGPoint(x: 204, y: 145)
        rightCheek.zPosition = 4
        rightCheek.alpha = 0.75
        rightCheek.name = "idleRightCheek"
        mascotRoot.addChild(rightCheek)

        let beakGroup = SKNode()
        beakGroup.position = .zero
        beakGroup.zPosition = 6
        beakGroup.name = "idleBeak"
        mascotRoot.addChild(beakGroup)
        beakGroup.addChild(makeFilledNode(path: path {
            $0.move(to: CGPoint(x: 160, y: 132))
            $0.addLine(to: CGPoint(x: 181, y: 143))
            $0.addLine(to: CGPoint(x: 160, y: 154))
            $0.addLine(to: CGPoint(x: 139, y: 143))
            $0.closeSubpath()
        }, fillColor: NSColor(calibratedRed: 0.89, green: 0.49, blue: 0.28, alpha: 0.98)))
        beakGroup.addChild(makeFilledNode(path: path {
            $0.move(to: CGPoint(x: 160, y: 143))
            $0.addLine(to: CGPoint(x: 177, y: 152))
            $0.addLine(to: CGPoint(x: 160, y: 160))
            $0.addLine(to: CGPoint(x: 143, y: 152))
            $0.closeSubpath()
        }, fillColor: NSColor(calibratedRed: 0.94, green: 0.62, blue: 0.39, alpha: 0.98)))

        let feet = makeStrokeNode(path: path {
            $0.move(to: CGPoint(x: 140, y: 289))
            $0.addLine(to: CGPoint(x: 140, y: 305))
            $0.move(to: CGPoint(x: 180, y: 289))
            $0.addLine(to: CGPoint(x: 180, y: 305))
            $0.move(to: CGPoint(x: 129, y: 305))
            $0.addLine(to: CGPoint(x: 140, y: 301))
            $0.move(to: CGPoint(x: 140, y: 305))
            $0.addLine(to: CGPoint(x: 128, y: 309))
            $0.move(to: CGPoint(x: 151, y: 305))
            $0.addLine(to: CGPoint(x: 140, y: 301))
            $0.move(to: CGPoint(x: 169, y: 305))
            $0.addLine(to: CGPoint(x: 180, y: 301))
            $0.move(to: CGPoint(x: 180, y: 305))
            $0.addLine(to: CGPoint(x: 168, y: 309))
            $0.move(to: CGPoint(x: 191, y: 305))
            $0.addLine(to: CGPoint(x: 180, y: 301))
        }, strokeColor: NSColor(calibratedRed: 0.89, green: 0.49, blue: 0.28, alpha: 0.9), lineWidth: 6, name: "idleFeet")
        feet.zPosition = 0
        mascotRoot.addChild(feet)
    }
}

private func path(_ build: (CGMutablePath) -> Void) -> CGPath {
    let path = CGMutablePath()
    build(path)
    return path
}

private func makeFilledNode(path: CGPath, fillColor: NSColor = .white, name: String? = nil) -> SKShapeNode {
    let node = SKShapeNode(path: path)
    node.fillColor = fillColor
    node.strokeColor = .clear
    node.name = name
    return node
}

private func makeStrokeNode(
    path: CGPath,
    strokeColor: NSColor,
    lineWidth: CGFloat,
    name: String? = nil
) -> SKShapeNode {
    let node = SKShapeNode(path: path)
    node.fillColor = .clear
    node.strokeColor = strokeColor
    node.lineWidth = lineWidth
    node.lineCap = .round
    node.lineJoin = .round
    node.name = name
    return node
}

private func circleNode(radius: CGFloat, fillColor: NSColor) -> SKShapeNode {
    let node = SKShapeNode(circleOfRadius: radius)
    node.fillColor = fillColor
    node.strokeColor = .clear
    return node
}

extension TimeInterval {
    func clamped(to range: ClosedRange<TimeInterval>) -> TimeInterval {
        min(range.upperBound, max(range.lowerBound, self))
    }
}

struct BirdPalette {
    let body: NSColor
    let belly: NSColor
    let wing: NSColor
    let wingBright: NSColor
    let crestOuter: NSColor
    let crestInner: NSColor
    let cheek: NSColor
}

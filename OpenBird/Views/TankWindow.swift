import AppKit
import SpriteKit

// MARK: - Custom SKView that forwards mouse events to the scene

final class TankSKView: SKView {
    private var hoverTrackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = hoverTrackingArea {
            removeTrackingArea(existing)
        }
        hoverTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(hoverTrackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        wantsLayer = true
        layer?.borderColor = NSColor(white: 1.0, alpha: 0.4).cgColor
        layer?.borderWidth = 1.5
    }

    override func mouseExited(with event: NSEvent) {
        wantsLayer = true
        layer?.borderColor = NSColor(white: 1.0, alpha: 0.1).cgColor
        layer?.borderWidth = 1.0
    }

    override func mouseDown(with event: NSEvent) {
        // Forward to scene so SpriteKit handles clicks
        scene?.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        scene?.mouseUp(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        // Drag the window
        window?.performDrag(with: event)
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

// MARK: - Tank Window

final class TankWindow: NSPanel {
    let skView: TankSKView
    private var moveObserver: NSObjectProtocol?
    private var resizeObserver: NSObjectProtocol?

    init() {
        skView = TankSKView()

        let settings = AppSettings.shared
        let frame = NSRect(
            x: settings.windowX,
            y: settings.windowY,
            width: settings.windowWidth,
            height: settings.windowHeight
        )

        super.init(
            contentRect: frame,
            styleMask: [.nonactivatingPanel, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Transparent floating window
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        isMovableByWindowBackground = false  // TankSKView.mouseDragged handles this
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        minSize = NSSize(width: 150, height: 100)

        // Spaces behavior
        updateSpacesBehavior()

        // SpriteKit view setup
        skView.allowsTransparency = true
        skView.preferredFramesPerSecond = 30
        skView.frame = NSRect(origin: .zero, size: frame.size)
        skView.autoresizingMask = [.width, .height]
        contentView = skView

        // Initial border state (subtle)
        skView.wantsLayer = true
        skView.layer?.borderColor = NSColor(white: 1.0, alpha: 0.1).cgColor
        skView.layer?.borderWidth = 1.0
        skView.layer?.cornerRadius = 8

        // Save position on move/resize — use block-based observers (auto-cleanup)
        moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.saveFrame()
        }
        resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.saveFrame()
        }
    }

    deinit {
        if let obs = moveObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = resizeObserver { NotificationCenter.default.removeObserver(obs) }
    }

    func presentScene(_ scene: SKScene) {
        scene.size = skView.bounds.size
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    func toggle() {
        if isVisible {
            orderOut(nil)
            skView.isPaused = true
        } else {
            orderFront(nil)
            skView.isPaused = false
        }
    }

    func resetToDefaultSize() {
        let defaultWidth: CGFloat = 300
        let defaultHeight: CGFloat = 200
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let newFrame = NSRect(
            x: screen.maxX - defaultWidth - 20,
            y: screen.minY + 100,
            width: defaultWidth,
            height: defaultHeight
        )
        setFrame(newFrame, display: true, animate: true)
    }

    func updateSpacesBehavior() {
        if AppSettings.shared.followAcrossSpaces {
            collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        } else {
            collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        }
    }

    private func saveFrame() {
        let settings = AppSettings.shared
        settings.windowX = frame.origin.x
        settings.windowY = frame.origin.y
        settings.windowWidth = frame.width
        settings.windowHeight = frame.height
    }

    // Forward right-click to SpriteKit scene
    override func rightMouseDown(with event: NSEvent) {
        skView.scene?.rightMouseDown(with: event)
    }
}

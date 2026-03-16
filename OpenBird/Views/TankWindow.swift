import AppKit
import SpriteKit

// MARK: - Custom SKView that forwards mouse events to the scene

final class TankSKView: SKView {
    private var hoverTrackingArea: NSTrackingArea?
    private var isHovering = false
    private var isPressing = false

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = hoverTrackingArea {
            removeTrackingArea(existing)
        }
        hoverTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .inVisibleRect, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(hoverTrackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
        refreshChrome()
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        refreshChrome()
    }

    override func mouseDown(with event: NSEvent) {
        isHovering = true
        isPressing = true
        refreshChrome()
        // Forward to scene so SpriteKit handles clicks
        scene?.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        isPressing = false
        refreshChrome()
        scene?.mouseUp(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        isHovering = true
        isPressing = true
        refreshChrome()
        // Drag the window
        window?.performDrag(with: event)
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    func refreshChrome() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true

        let keepVisible = AppSettings.shared.showWindowBorder || isHovering || isPressing
        guard keepVisible else {
            layer?.borderColor = NSColor.clear.cgColor
            layer?.borderWidth = 0
            return
        }

        let alpha: CGFloat
        let width: CGFloat
        if AppSettings.shared.showWindowBorder {
            alpha = isPressing ? 0.42 : (isHovering ? 0.3 : 0.1)
            width = isPressing ? 1.8 : (isHovering ? 1.4 : 1.0)
        } else {
            alpha = isPressing ? 0.4 : 0.24
            width = isPressing ? 1.8 : 1.25
        }
        layer?.borderColor = NSColor(white: 1.0, alpha: alpha).cgColor
        layer?.borderWidth = width
    }
}

// MARK: - Tank Window

final class TankWindow: NSPanel {
    let skView: TankSKView
    private var moveObserver: NSObjectProtocol?
    private var resizeObserver: NSObjectProtocol?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

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
        skView.preferredFramesPerSecond = 60
        skView.frame = NSRect(origin: .zero, size: frame.size)
        skView.autoresizingMask = [.width, .height]
        contentView = skView

        // Initial border state (subtle)
        skView.wantsLayer = true
        skView.refreshChrome()

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

    func updateChrome() {
        skView.refreshChrome()
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

import Foundation
import AppKit
import Carbon.HIToolbox

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    @Published var windowX: Double {
        didSet { defaults.set(windowX, forKey: "windowX") }
    }
    @Published var windowY: Double {
        didSet { defaults.set(windowY, forKey: "windowY") }
    }
    @Published var windowWidth: Double {
        didSet { defaults.set(windowWidth, forKey: "windowWidth") }
    }
    @Published var windowHeight: Double {
        didSet { defaults.set(windowHeight, forKey: "windowHeight") }
    }
    @Published var hotkeyKeyCode: UInt32 {
        didSet { defaults.set(hotkeyKeyCode, forKey: "hotkeyKeyCode") }
    }
    @Published var hotkeyModifiers: UInt32 {
        didSet { defaults.set(hotkeyModifiers, forKey: "hotkeyModifiers") }
    }
    @Published var showOnLaunch: Bool {
        didSet { defaults.set(showOnLaunch, forKey: "showOnLaunch") }
    }
    @Published var enableSounds: Bool {
        didSet { defaults.set(enableSounds, forKey: "enableSounds") }
    }
    @Published var currentGameMode: String {
        didSet { defaults.set(currentGameMode, forKey: "currentGameMode") }
    }
    @Published var showCreatureNames: Bool {
        didSet { defaults.set(showCreatureNames, forKey: "showCreatureNames") }
    }
    @Published var movementSpeed: Double {
        didSet { defaults.set(movementSpeed, forKey: "movementSpeed") }
    }
    @Published var followAcrossSpaces: Bool {
        didSet { defaults.set(followAcrossSpaces, forKey: "followAcrossSpaces") }
    }
    @Published var showAmbientEffects: Bool {
        didSet { defaults.set(showAmbientEffects, forKey: "showAmbientEffects") }
    }
    @Published var showWindowBorder: Bool {
        didSet { defaults.set(showWindowBorder, forKey: "showWindowBorder") }
    }
    @Published var sceneBackgroundStyle: String {
        didSet { defaults.set(sceneBackgroundStyle, forKey: "sceneBackgroundStyle") }
    }
    @Published var jamModeAudioReactiveEnabled: Bool {
        didSet { defaults.set(jamModeAudioReactiveEnabled, forKey: "jamModeAudioReactiveEnabled") }
    }

    private init() {
        let screenWidth = NSScreen.main?.frame.width ?? 1440
        let storedBackground = defaults.string(forKey: "sceneBackgroundStyle")
            ?? defaults.string(forKey: "tankBackground")
            ?? "ocean"
        let normalizedBackground: String
        switch storedBackground {
        case "transparent", "clear":
            normalizedBackground = "clear"
        case "dark", "sunset":
            normalizedBackground = "night"
        default:
            normalizedBackground = "themed"
        }

        let ambientEffectsEnabled: Bool
        if defaults.object(forKey: "showAmbientEffects") != nil {
            ambientEffectsEnabled = defaults.bool(forKey: "showAmbientEffects")
        } else if defaults.object(forKey: "showBubbles") != nil {
            ambientEffectsEnabled = defaults.bool(forKey: "showBubbles")
        } else {
            ambientEffectsEnabled = true
        }

        self.windowX = defaults.object(forKey: "windowX") as? Double ?? Double(screenWidth - 420)
        self.windowY = defaults.object(forKey: "windowY") as? Double ?? 100
        self.windowWidth = defaults.object(forKey: "windowWidth") as? Double ?? 400
        self.windowHeight = defaults.object(forKey: "windowHeight") as? Double ?? 300
        self.hotkeyKeyCode = defaults.object(forKey: "hotkeyKeyCode") as? UInt32 ?? 17
        self.hotkeyModifiers = defaults.object(forKey: "hotkeyModifiers") as? UInt32 ?? UInt32(cmdKey | shiftKey)
        self.showOnLaunch = defaults.object(forKey: "showOnLaunch") as? Bool ?? true
        self.enableSounds = defaults.object(forKey: "enableSounds") as? Bool ?? true
        self.currentGameMode = defaults.string(forKey: "currentGameMode") ?? "fish"
        self.showCreatureNames = defaults.object(forKey: "showCreatureNames") as? Bool ?? true
        self.movementSpeed = defaults.object(forKey: "movementSpeed") as? Double ?? 1.0
        self.followAcrossSpaces = defaults.object(forKey: "followAcrossSpaces") as? Bool ?? true
        self.showAmbientEffects = ambientEffectsEnabled
        self.showWindowBorder = defaults.object(forKey: "showWindowBorder") as? Bool ?? true
        self.sceneBackgroundStyle = normalizedBackground
        self.jamModeAudioReactiveEnabled = defaults.object(forKey: "jamModeAudioReactiveEnabled") as? Bool ?? false
    }
}

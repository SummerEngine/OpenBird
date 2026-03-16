import Foundation
import Carbon.HIToolbox
import AppKit

@MainActor
final class HotkeyService: ObservableObject {
    static let shared = HotkeyService()

    var onToggle: (() -> Void)?

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private init() {}

    func register() {
        let settings = AppSettings.shared

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyEventHandler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )

        guard status == noErr else { return }

        // Register the hotkey
        var hotKeyID = EventHotKeyID(signature: OSType(0x574F5243), id: 1) // "WORC"
        RegisterEventHotKey(
            settings.hotkeyKeyCode,
            settings.hotkeyModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
    }

    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    func reregister() {
        unregister()
        register()
    }

    static func shortcutDisplayString(keyCode: UInt32, modifiers: UInt32) -> String {
        let modifierLabels = shortcutLabels(for: modifiers)
        let keyLabel = keyDisplayStrings[keyCode] ?? "Key"
        return (modifierLabels + [keyLabel]).joined(separator: "+")
    }

    static func menuShortcut(keyCode: UInt32, modifiers: UInt32) -> (keyEquivalent: String, modifierFlags: NSEvent.ModifierFlags)? {
        guard let keyEquivalent = menuKeyEquivalents[keyCode] else {
            return nil
        }
        return (keyEquivalent, eventModifierFlags(for: modifiers))
    }
}

// MARK: - Carbon Callback

private func hotkeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else { return OSStatus(eventNotHandledErr) }

    let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()

    DispatchQueue.main.async {
        service.onToggle?()
    }

    return noErr
}

private func shortcutLabels(for modifiers: UInt32) -> [String] {
    var labels: [String] = []

    if modifiers & UInt32(cmdKey) != 0 {
        labels.append("Cmd")
    }
    if modifiers & UInt32(shiftKey) != 0 {
        labels.append("Shift")
    }
    if modifiers & UInt32(optionKey) != 0 {
        labels.append("Option")
    }
    if modifiers & UInt32(controlKey) != 0 {
        labels.append("Ctrl")
    }

    return labels
}

private func eventModifierFlags(for modifiers: UInt32) -> NSEvent.ModifierFlags {
    var flags: NSEvent.ModifierFlags = []

    if modifiers & UInt32(cmdKey) != 0 {
        flags.insert(.command)
    }
    if modifiers & UInt32(shiftKey) != 0 {
        flags.insert(.shift)
    }
    if modifiers & UInt32(optionKey) != 0 {
        flags.insert(.option)
    }
    if modifiers & UInt32(controlKey) != 0 {
        flags.insert(.control)
    }

    return flags
}

private let menuKeyEquivalents: [UInt32: String] = [
    UInt32(kVK_ANSI_A): "a",
    UInt32(kVK_ANSI_B): "b",
    UInt32(kVK_ANSI_C): "c",
    UInt32(kVK_ANSI_D): "d",
    UInt32(kVK_ANSI_E): "e",
    UInt32(kVK_ANSI_F): "f",
    UInt32(kVK_ANSI_G): "g",
    UInt32(kVK_ANSI_H): "h",
    UInt32(kVK_ANSI_I): "i",
    UInt32(kVK_ANSI_J): "j",
    UInt32(kVK_ANSI_K): "k",
    UInt32(kVK_ANSI_L): "l",
    UInt32(kVK_ANSI_M): "m",
    UInt32(kVK_ANSI_N): "n",
    UInt32(kVK_ANSI_O): "o",
    UInt32(kVK_ANSI_P): "p",
    UInt32(kVK_ANSI_Q): "q",
    UInt32(kVK_ANSI_R): "r",
    UInt32(kVK_ANSI_S): "s",
    UInt32(kVK_ANSI_T): "t",
    UInt32(kVK_ANSI_U): "u",
    UInt32(kVK_ANSI_V): "v",
    UInt32(kVK_ANSI_W): "w",
    UInt32(kVK_ANSI_X): "x",
    UInt32(kVK_ANSI_Y): "y",
    UInt32(kVK_ANSI_Z): "z",
    UInt32(kVK_ANSI_0): "0",
    UInt32(kVK_ANSI_1): "1",
    UInt32(kVK_ANSI_2): "2",
    UInt32(kVK_ANSI_3): "3",
    UInt32(kVK_ANSI_4): "4",
    UInt32(kVK_ANSI_5): "5",
    UInt32(kVK_ANSI_6): "6",
    UInt32(kVK_ANSI_7): "7",
    UInt32(kVK_ANSI_8): "8",
    UInt32(kVK_ANSI_9): "9",
    UInt32(kVK_ANSI_Comma): ",",
    UInt32(kVK_ANSI_Period): ".",
    UInt32(kVK_ANSI_Slash): "/",
    UInt32(kVK_ANSI_Semicolon): ";",
    UInt32(kVK_ANSI_Quote): "'",
    UInt32(kVK_ANSI_LeftBracket): "[",
    UInt32(kVK_ANSI_RightBracket): "]",
    UInt32(kVK_ANSI_Backslash): "\\",
    UInt32(kVK_ANSI_Minus): "-",
    UInt32(kVK_ANSI_Equal): "="
]

private let keyDisplayStrings: [UInt32: String] = [
    UInt32(kVK_ANSI_A): "A",
    UInt32(kVK_ANSI_B): "B",
    UInt32(kVK_ANSI_C): "C",
    UInt32(kVK_ANSI_D): "D",
    UInt32(kVK_ANSI_E): "E",
    UInt32(kVK_ANSI_F): "F",
    UInt32(kVK_ANSI_G): "G",
    UInt32(kVK_ANSI_H): "H",
    UInt32(kVK_ANSI_I): "I",
    UInt32(kVK_ANSI_J): "J",
    UInt32(kVK_ANSI_K): "K",
    UInt32(kVK_ANSI_L): "L",
    UInt32(kVK_ANSI_M): "M",
    UInt32(kVK_ANSI_N): "N",
    UInt32(kVK_ANSI_O): "O",
    UInt32(kVK_ANSI_P): "P",
    UInt32(kVK_ANSI_Q): "Q",
    UInt32(kVK_ANSI_R): "R",
    UInt32(kVK_ANSI_S): "S",
    UInt32(kVK_ANSI_T): "T",
    UInt32(kVK_ANSI_U): "U",
    UInt32(kVK_ANSI_V): "V",
    UInt32(kVK_ANSI_W): "W",
    UInt32(kVK_ANSI_X): "X",
    UInt32(kVK_ANSI_Y): "Y",
    UInt32(kVK_ANSI_Z): "Z",
    UInt32(kVK_ANSI_0): "0",
    UInt32(kVK_ANSI_1): "1",
    UInt32(kVK_ANSI_2): "2",
    UInt32(kVK_ANSI_3): "3",
    UInt32(kVK_ANSI_4): "4",
    UInt32(kVK_ANSI_5): "5",
    UInt32(kVK_ANSI_6): "6",
    UInt32(kVK_ANSI_7): "7",
    UInt32(kVK_ANSI_8): "8",
    UInt32(kVK_ANSI_9): "9",
    UInt32(kVK_ANSI_Comma): ",",
    UInt32(kVK_ANSI_Period): ".",
    UInt32(kVK_ANSI_Slash): "/",
    UInt32(kVK_ANSI_Semicolon): ";",
    UInt32(kVK_ANSI_Quote): "'",
    UInt32(kVK_ANSI_LeftBracket): "[",
    UInt32(kVK_ANSI_RightBracket): "]",
    UInt32(kVK_ANSI_Backslash): "\\",
    UInt32(kVK_ANSI_Minus): "-",
    UInt32(kVK_ANSI_Equal): "="
]

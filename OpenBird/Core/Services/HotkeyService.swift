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

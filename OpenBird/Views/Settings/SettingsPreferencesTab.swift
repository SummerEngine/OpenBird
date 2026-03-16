import SwiftUI

struct SettingsPreferencesTab: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var audioMonitor = SystemAudioMonitorService.shared

    @State private var showingJamPermissionSheet = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Show window on launch", isOn: $settings.showOnLaunch)
                Toggle("Play sounds on commit", isOn: $settings.enableSounds)
                Toggle("Show friend names", isOn: $settings.showCreatureNames)
                Toggle("Show on all Spaces", isOn: $settings.followAcrossSpaces)
                    .help("Keep the tank visible when switching between macOS Spaces")
            }

            Section("Friends") {
                HStack {
                    Text("Movement speed")
                    Slider(value: $settings.movementSpeed, in: 0.3...2.5, step: 0.1)
                    Text(String(format: "%.1fx", settings.movementSpeed))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 35)
                }
                Text("Commits grow your friends over time. Manual feeding only gives them a small happiness boost.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("World") {
                Picker("Mode", selection: $settings.currentGameMode) {
                    ForEach(GameModeID.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.iconName)
                            .tag(mode.rawValue)
                    }
                }
                Text(modeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isJamModeSelected {
                    jamModeControls
                }

                Toggle("Show window border", isOn: $settings.showWindowBorder)
                Toggle("Ambient effects", isOn: $settings.showAmbientEffects)
                    .help("Bubbles in Aquarium, breeze lines in Aviary, neon trails in Jam Mode")
                Picker("Backdrop", selection: $settings.sceneBackgroundStyle) {
                    Text("Themed").tag("themed")
                    Text("Night").tag("night")
                    Text("Clear").tag("clear")
                }
                Text("Backdrop and effects adapt to the selected world.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Keyboard Shortcut") {
                Text("Cmd+Shift+T to toggle window")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            Section("About") {
                HStack {
                    Text("OpenBird")
                        .fontWeight(.medium)
                    Text("v1.0")
                        .foregroundColor(.secondary)
                }
                Text("Your repos, alive.")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showingJamPermissionSheet) {
            JamModePermissionSheet(
                onContinue: {
                    showingJamPermissionSheet = false
                    audioMonitor.requestPermission()
                },
                onCancel: {
                    showingJamPermissionSheet = false
                }
            )
        }
        .onAppear {
            audioMonitor.checkPermissionStatus()
        }
    }

    private var isJamModeSelected: Bool {
        GameModeID(rawValue: settings.currentGameMode) == .jam
    }

    private var jamModeControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(
                "React to music playing on this Mac",
                isOn: Binding(
                    get: { settings.jamModeAudioReactiveEnabled },
                    set: { enabled in
                        settings.jamModeAudioReactiveEnabled = enabled
                        if enabled && !audioMonitor.hasScreenCapturePermission {
                            showingJamPermissionSheet = true
                        }
                    }
                )
            )

            if settings.jamModeAudioReactiveEnabled {
                Text(jamStatusDescription)
                    .font(.caption)
                    .foregroundColor(jamStatusColor)

                if !audioMonitor.hasScreenCapturePermission {
                    Button(audioMonitor.hasRequestedPermission ? "Open Screen Recording Settings" : "Grant Screen + Audio Access") {
                        if audioMonitor.hasRequestedPermission {
                            audioMonitor.openSystemSettings()
                        } else {
                            showingJamPermissionSheet = true
                        }
                    }
                } else if audioMonitor.isCapturing {
                    Label("Listening for beat energy now", systemImage: "waveform")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var jamStatusDescription: String {
        switch audioMonitor.permissionState {
        case .notRequested:
            return "Jam Mode can bounce to music by reading live system audio levels. Nothing is stored or uploaded."
        case .denied:
            return "Screen Recording access is still off. Enable it in System Settings to sync Jam Mode to music."
        case .restartRequired:
            return "Access was requested. Quit and reopen OpenBird after granting permission so live beat sync can start."
        case .granted:
            if audioMonitor.isCapturing {
                return "OpenBird is reading local audio energy and beat intensity for Jam Mode."
            }
            return "Permission is ready. Switch to Jam Mode to start music-reactive animation."
        }
    }

    private var jamStatusColor: Color {
        switch audioMonitor.permissionState {
        case .notRequested:
            return .secondary
        case .denied:
            return .orange
        case .restartRequired:
            return .accentColor
        case .granted:
            return audioMonitor.isCapturing ? .green : .secondary
        }
    }

    private var modeDescription: String {
        switch GameModeID(rawValue: settings.currentGameMode) ?? .fish {
        case .fish:
            return "Aquarium keeps the friends in water, with calmer swim paths and optional bubbles."
        case .bird:
            return "Aviary gives each repo a bird that perches, hops, and takes a flight loop when a commit lands."
        case .jam:
            return "Jam Mode turns your friends into little dancers, with optional real-time music sync from local system audio."
        }
    }
}

private struct JamModePermissionSheet: View {
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Enable Jam Mode Sync", systemImage: "waveform.circle.fill")
                .font(.title2.bold())

            Text("Jam Mode can react to music playing on your Mac by analyzing live system audio energy.")

            VStack(alignment: .leading, spacing: 10) {
                Label("macOS will ask for Screen Recording access", systemImage: "display")
                Label("OpenBird only uses the audio levels for animation", systemImage: "lock.shield")
                Label("No audio is uploaded or saved", systemImage: "externaldrive.badge.checkmark")
            }
            .font(.callout)
            .foregroundColor(.secondary)

            Text("After granting access, you may need to quit and reopen OpenBird before beat sync starts.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Button("Not Now", action: onCancel)
                Spacer()
                Button("Continue", action: onContinue)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

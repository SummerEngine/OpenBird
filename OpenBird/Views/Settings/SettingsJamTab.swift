import SwiftUI

struct SettingsJamTab: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var audioMonitor = SystemAudioMonitorService.shared

    @State private var showingJamPermissionSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                mainCard
                statusCard
            }
            .padding(20)
        }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Jam", systemImage: "waveform")
                .font(.title2.weight(.semibold))

            Text("Jam works on top of your current world. Same fish, same birds, but they stop their normal movement and bounce to whatever is playing on this Mac.")
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    private var mainCard: some View {
        card(
            title: "Enable Jam Mode",
            subtitle: "Jam is a local feature. No account is required for audio-reactive animation."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(
                    "Enable Jam Mode",
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

                detailRow(
                    icon: "sparkles",
                    title: "Current world stays the same",
                    detail: "Jam layers on top of Aquarium or Aviary. It does not swap in a different creature type."
                )
                detailRow(
                    icon: "person.3",
                    title: "All visible creatures react together",
                    detail: "For now, every creature in the active world enters its species-specific jam animation with calmer beat-driven motion."
                )
                detailRow(
                    icon: "lock.shield",
                    title: "Permission stays local",
                    detail: "OpenBird only reads live system audio energy to drive animation. The microphone is not used and nothing is uploaded or saved."
                )
            }
        }
    }

    private var statusCard: some View {
        card(
            title: "Jam Status",
            subtitle: activeWorldDescription
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(jamStatusDescription)
                    .font(.callout)
                    .foregroundColor(jamStatusColor)

                if settings.jamModeAudioReactiveEnabled {
                    switch audioMonitor.permissionState {
                    case .notRequested:
                        Button("Grant Screen Recording Access") {
                            showingJamPermissionSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    case .denied, .restartRequired:
                        Button("Open Screen Recording Settings") {
                            audioMonitor.openSystemSettings()
                        }
                        .buttonStyle(.bordered)
                    case .granted:
                        if audioMonitor.isCapturing {
                            Label("Listening for beat energy now", systemImage: "waveform")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func card<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.callout)
                .foregroundColor(.secondary)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.08))
        )
    }

    private func detailRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var activeWorldDescription: String {
        switch GameModeID(rawValue: settings.currentGameMode) ?? .fish {
        case .fish, .jam:
            return "Active world: Aquarium"
        case .bird:
            return "Active world: Aviary"
        }
    }

    private var jamStatusDescription: String {
        guard settings.jamModeAudioReactiveEnabled else {
            return "Jam is currently off. Turn it on to trigger the local Screen Recording permission flow and let your creatures react to music."
        }

        switch audioMonitor.permissionState {
        case .notRequested:
            return "Jam is on, but macOS Screen Recording permission is still needed before the creatures can react to system audio levels."
        case .denied:
            return "Screen Recording access is still off. Enable it in System Settings so OpenBird can read system audio levels. The microphone is not used."
        case .restartRequired:
            return "Access was requested. Quit and reopen OpenBird if macOS needs a relaunch before Jam starts reacting."
        case .granted:
            if audioMonitor.isCapturing {
                return "Jam is live. The current creatures follow smoothed system audio energy and pop on stronger beats while the window is visible."
            }
            return "Permission is ready. OpenBird will react as soon as the tank is visible and Jam stays enabled."
        }
    }

    private var jamStatusColor: Color {
        guard settings.jamModeAudioReactiveEnabled else { return .secondary }

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
}

private struct JamModePermissionSheet: View {
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Enable Jam Mode Sync", systemImage: "waveform.circle.fill")
                .font(.title2.bold())

            Text("Jam can react to music playing on your Mac by analyzing live system audio levels.")

            VStack(alignment: .leading, spacing: 10) {
                Label("macOS will ask for Screen Recording access", systemImage: "display")
                Label("This is used to read system audio levels for animation", systemImage: "speaker.wave.2")
                Label("The microphone is not used", systemImage: "mic.slash")
                Label("No audio is uploaded or saved", systemImage: "externaldrive.badge.checkmark")
            }
            .font(.callout)
            .foregroundColor(.secondary)

            Text("After granting access, you may need to quit and reopen OpenBird before Jam starts reacting.")
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

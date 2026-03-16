import SwiftUI

struct SettingsPreferencesTab: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var updateService = UpdateService.shared

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
                    ForEach([GameModeID.fish, GameModeID.bird]) { mode in
                        Label(mode.displayName, systemImage: mode.iconName)
                            .tag(mode.rawValue)
                    }
                }
                Text(modeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Show window border", isOn: $settings.showWindowBorder)
                Toggle("Ambient effects", isOn: $settings.showAmbientEffects)
                    .help("Bubbles in Aquarium and breeze lines in Aviary")
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
                Text("\(HotkeyService.shortcutDisplayString(keyCode: settings.hotkeyKeyCode, modifiers: settings.hotkeyModifiers)) to show or hide the window")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            Section("Updates") {
                Button(updateService.isChecking ? "Checking for Updates..." : "Check for Updates...") {
                    updateService.checkForUpdates()
                }
                .disabled(updateService.isChecking || !updateService.canCheckForUpdates)

                Text(updateStatusDescription)
                    .font(.caption)
                    .foregroundColor(updateStatusColor)

                if let lastCheckDate = updateService.lastCheckDate {
                    Text("Last checked \(lastCheckDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(updateScheduleDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Section("About") {
                HStack {
                    Text("OpenBird")
                        .fontWeight(.medium)
                    Text(appVersionSummary)
                        .foregroundColor(.secondary)
                }
                Text("Your repos, alive.")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var modeDescription: String {
        switch GameModeID(rawValue: settings.currentGameMode) ?? .fish {
        case .fish:
            return "Aquarium keeps the friends in water, with calmer swim paths and optional bubbles."
        case .bird:
            return "Aviary gives each repo a bird that perches, hops, and takes a flight loop when a commit lands."
        case .jam:
            return "Jam layers on top of your current world and is configured from the Jam tab."
        }
    }

    private var appVersionSummary: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "v\(shortVersion) (\(buildNumber))"
    }

    private var updateStatusDescription: String {
        #if DEBUG
        if !updateService.isUsingTestFeed {
            return "Automatic update checks stay off while developing. Set SparkleTestFeedURL if you want to test Sparkle locally."
        }
        #endif

        if let lastError = updateService.lastError, !lastError.isEmpty {
            return "OpenBird could not reach the update feed just now. You can try again later."
        }

        if updateService.isChecking {
            return "Checking for a newer version now."
        }

        if let availableVersion = updateService.availableVersion {
            return "Version \(availableVersion) is available. Sparkle will guide you through the update."
        }

        return "OpenBird checks quietly in the background and only shows a prompt when an update is available."
    }

    private var updateStatusColor: Color {
        if updateService.lastError != nil {
            return .orange
        }

        if updateService.availableVersion != nil {
            return .accentColor
        }

        return .secondary
    }

    private var updateScheduleDescription: String {
        #if DEBUG
        if !updateService.isUsingTestFeed {
            return "Automatic checks are disabled in debug builds."
        }
        #endif

        guard updateService.automaticallyChecksForUpdates else {
            return "Automatic checks are currently off."
        }

        let hours = max(1, Int(updateService.updateCheckInterval / 3600))
        if hours == 1 {
            return "Automatic checks run about once per hour."
        }

        return "Automatic checks run about every \(hours) hours."
    }
}

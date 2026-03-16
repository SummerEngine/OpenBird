import Foundation
import Sparkle

@MainActor
final class UpdateService: NSObject, ObservableObject {
    static let shared = UpdateService()

    @Published private(set) var isChecking = false
    @Published private(set) var availableVersion: String?
    @Published private(set) var lastCheckDate: Date?
    @Published private(set) var lastError: String?

    private var updaterController: SPUStandardUpdaterController!

    var canCheckForUpdates: Bool {
        isUpdaterEnabled && updaterController.updater.canCheckForUpdates
    }

    var automaticallyChecksForUpdates: Bool {
        updaterController.updater.automaticallyChecksForUpdates
    }

    var updateCheckInterval: TimeInterval {
        updaterController.updater.updateCheckInterval
    }

    #if DEBUG
    var isUsingTestFeed: Bool {
        testFeedURL != nil
    }
    #endif

    private override init() {
        super.init()

        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )

        configureAutomaticChecks()

        print("[UpdateService] Feed URL: \(updaterController.updater.feedURL?.absoluteString ?? "nil")")
        print("[UpdateService] Automatic checks: \(updaterController.updater.automaticallyChecksForUpdates)")
        print("[UpdateService] Check interval: \(updaterController.updater.updateCheckInterval)s")
    }

    func checkForUpdates() {
        guard isUpdaterEnabled else {
            #if DEBUG
            lastError = "Automatic update checks stay off in debug builds unless SparkleTestFeedURL is set."
            #else
            lastError = "Updater is not available right now."
            #endif
            return
        }

        guard updaterController.updater.canCheckForUpdates else { return }

        print("[UpdateService] Manual check triggered")
        isChecking = true
        lastError = nil
        updaterController.updater.checkForUpdates()
    }

    private func configureAutomaticChecks() {
        updaterController.updater.automaticallyChecksForUpdates = shouldAutomaticallyCheckForUpdates
    }

    private var isUpdaterEnabled: Bool {
        #if DEBUG
        return testFeedURL != nil
        #else
        return true
        #endif
    }

    private var shouldAutomaticallyCheckForUpdates: Bool {
        #if DEBUG
        return testFeedURL != nil
        #else
        return true
        #endif
    }

    #if DEBUG
    private var testFeedURL: String? {
        let value = UserDefaults.standard.string(forKey: "SparkleTestFeedURL")?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else { return nil }
        return value
    }
    #endif
}

extension UpdateService: SPUUpdaterDelegate {
    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        let build = item.versionString

        print("[UpdateService] Found update: v\(version) (build \(build))")
        print("[UpdateService] Update URL: \(item.fileURL?.absoluteString ?? "nil")")

        Task { @MainActor in
            self.isChecking = false
            self.availableVersion = version
            self.lastCheckDate = Date()
            self.lastError = nil
        }
    }

    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        print("[UpdateService] No update available")

        Task { @MainActor in
            self.isChecking = false
            self.availableVersion = nil
            self.lastCheckDate = Date()
        }
    }

    nonisolated func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        print("[UpdateService] Update failed: \(error.localizedDescription)")

        if let nsError = error as NSError? {
            print("[UpdateService] Domain: \(nsError.domain)")
            print("[UpdateService] Code: \(nsError.code)")
        }

        Task { @MainActor in
            self.isChecking = false
            self.lastError = error.localizedDescription
            self.lastCheckDate = Date()
        }
    }

    nonisolated func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
        print("[UpdateService] Download complete for v\(item.displayVersionString)")
    }

    nonisolated func updater(
        _ updater: SPUUpdater,
        failedToDownloadUpdate item: SUAppcastItem,
        error: Error
    ) {
        print("[UpdateService] Download failed for v\(item.displayVersionString): \(error.localizedDescription)")

        Task { @MainActor in
            self.lastError = "Download failed: \(error.localizedDescription)"
        }
    }

    #if DEBUG
    nonisolated func feedURLString(for updater: SPUUpdater) -> String? {
        UserDefaults.standard.string(forKey: "SparkleTestFeedURL")
    }
    #endif
}

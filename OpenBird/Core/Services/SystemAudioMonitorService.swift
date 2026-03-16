import AppKit
import Foundation
import ScreenCaptureKit
import CoreGraphics
import CoreMedia

final class SystemAudioMonitorService: NSObject, ObservableObject {
    static let shared = SystemAudioMonitorService()

    enum PermissionState: Equatable {
        case notRequested
        case denied
        case restartRequired
        case granted
    }

    @Published private(set) var permissionState: PermissionState = .notRequested
    @Published private(set) var isCapturing = false
    @Published private(set) var audioLevel: Double = 0
    @Published private(set) var beatStrength: Double = 0
    @Published private(set) var captureErrorMessage: String?

    var hasScreenCapturePermission: Bool {
        permissionState == .granted
    }

    var hasRequestedPermission: Bool {
        defaults.bool(forKey: requestedPermissionKey)
    }

    private let defaults = UserDefaults.standard
    private let requestedPermissionKey = "jamModeRequestedScreenCapturePermission"
    private let sampleQueue = DispatchQueue(label: "com.openbird.audio-monitor.samples")
    private let beatCooldown: CFTimeInterval = 0.24
    private let minimumBeatThreshold: Float = 0.08
    private let noiseGate: Float = 0.035

    private var stream: SCStream?
    private var activeStartTask: Task<Void, Never>?
    private var decayTimer: Timer?
    private var smoothedLevel: Float = 0
    private var movingAverageLevel: Float = 0
    private var previousProcessedLevel: Float = 0
    private var lastBeatTimestamp: CFTimeInterval = 0

    private override init() {
        super.init()
        checkPermissionStatus()
        startDecayTimer()
    }

    deinit {
        decayTimer?.invalidate()
    }

    func checkPermissionStatus() {
        let hasAccess = CGPreflightScreenCaptureAccess()
        DispatchQueue.main.async {
            if hasAccess {
                self.permissionState = .granted
                self.captureErrorMessage = nil
            } else if self.hasRequestedPermission {
                self.permissionState = .denied
            } else {
                self.permissionState = .notRequested
            }
        }
    }

    func requestPermission() {
        defaults.set(true, forKey: requestedPermissionKey)

        if CGPreflightScreenCaptureAccess() {
            DispatchQueue.main.async {
                self.permissionState = .granted
                self.captureErrorMessage = nil
            }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let granted = CGRequestScreenCaptureAccess()
            DispatchQueue.main.async {
                self.permissionState = granted ? .restartRequired : .denied
                self.captureErrorMessage = granted
                    ? "Relaunch OpenBird after granting access so Jam Mode can react to music."
                    : "Open Screen Recording settings to allow Jam Mode to read system audio levels. The microphone is not used."
            }
        }
    }

    func openSystemSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func startIfPossible() {
        guard activeStartTask == nil, !isCapturing else { return }
        guard CGPreflightScreenCaptureAccess() else {
            checkPermissionStatus()
            return
        }

        activeStartTask = Task { [weak self] in
            await self?.startCapture()
        }
    }

    func stop() {
        activeStartTask?.cancel()
        activeStartTask = nil

        guard let stream else {
            DispatchQueue.main.async {
                self.isCapturing = false
                self.audioLevel = 0
                self.beatStrength = 0
            }
            return
        }

        self.stream = nil
        Task {
            try? await stream.stopCapture()
        }

        DispatchQueue.main.async {
            self.isCapturing = false
            self.audioLevel = 0
            self.beatStrength = 0
            self.captureErrorMessage = nil
        }
        smoothedLevel = 0
        movingAverageLevel = 0
        previousProcessedLevel = 0
        lastBeatTimestamp = 0
    }

    private func startDecayTimer() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.decayLevels()
        }
        if let decayTimer {
            RunLoop.main.add(decayTimer, forMode: .common)
        }
    }

    private func decayLevels() {
        guard !isCapturing else { return }
        audioLevel *= 0.78
        beatStrength *= 0.55

        if audioLevel < 0.001 {
            audioLevel = 0
        }
        if beatStrength < 0.001 {
            beatStrength = 0
        }
    }

    private func startCapture() async {
        defer {
            activeStartTask = nil
        }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

            guard let display = content.displays.first else {
                throw CaptureError.noDisplayAvailable
            }

            let currentBundleID = Bundle.main.bundleIdentifier
            let excludedApps = content.applications.filter { $0.bundleIdentifier == currentBundleID }
            let filter = SCContentFilter(
                display: display,
                excludingApplications: excludedApps,
                exceptingWindows: []
            )

            let configuration = SCStreamConfiguration()
            configuration.capturesAudio = true
            configuration.excludesCurrentProcessAudio = true
            configuration.width = 2
            configuration.height = 2
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            configuration.queueDepth = 1
            if #available(macOS 15.0, *) {
                configuration.captureMicrophone = false
                configuration.microphoneCaptureDeviceID = nil
            }

            let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
            try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: sampleQueue)
            self.stream = stream

            try await stream.startCapture()

            DispatchQueue.main.async {
                self.permissionState = .granted
                self.isCapturing = true
                self.captureErrorMessage = nil
            }
        } catch {
            self.stream = nil
            DispatchQueue.main.async {
                self.isCapturing = false
                self.captureErrorMessage = error.localizedDescription
            }
        }
    }

    private func publish(level rawLevel: Float) {
        let processedLevel = processedLevel(from: rawLevel)
        let smoothing: Float = processedLevel > smoothedLevel ? 0.16 : 0.05
        smoothedLevel += (processedLevel - smoothedLevel) * smoothing
        movingAverageLevel += (processedLevel - movingAverageLevel) * 0.018

        let slope = max(0, processedLevel - previousProcessedLevel)
        let transient = max(0, processedLevel - max(smoothedLevel, movingAverageLevel + 0.015))
        let threshold = max(minimumBeatThreshold, movingAverageLevel * 1.55 + 0.025)
        let now = CACurrentMediaTime()

        var beatPulse: Float = 0
        if processedLevel > threshold,
           slope > 0.03,
           transient > 0.035,
           now - lastBeatTimestamp > beatCooldown {
            lastBeatTimestamp = now
            beatPulse = 1.0
        }

        previousProcessedLevel = processedLevel

        DispatchQueue.main.async {
            let visualLevel = max(Double(self.smoothedLevel), self.audioLevel * 0.9)
            let decayedBeat = self.beatStrength * 0.84
            self.audioLevel = visualLevel
            self.beatStrength = max(decayedBeat, Double(beatPulse))
        }
    }

    private func processedLevel(from rawLevel: Float) -> Float {
        let clamped = max(0, min(1, rawLevel))
        let gated = max(0, clamped - noiseGate)
        guard gated > 0 else { return 0 }

        let normalized = min(1, gated / (1 - noiseGate))
        // Compress the envelope so loud moments still pop without turning every sample into a spike.
        return pow(normalized, 0.82)
    }

    private func audioLevel(from sampleBuffer: CMSampleBuffer) -> Float? {
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }

        var lengthAtOffset = 0
        var totalLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        let status = CMBlockBufferGetDataPointer(
            dataBuffer,
            atOffset: 0,
            lengthAtOffsetOut: &lengthAtOffset,
            totalLengthOut: &totalLength,
            dataPointerOut: &dataPointer
        )

        guard status == kCMBlockBufferNoErr, let dataPointer, totalLength > 0 else { return nil }

        var bytesPerSample = 4
        var isFloat = true

        if let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer),
           let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) {
            let channels = max(1, Int(asbd.pointee.mChannelsPerFrame))
            bytesPerSample = max(1, Int(asbd.pointee.mBytesPerFrame) / channels)
            isFloat = (asbd.pointee.mFormatFlags & kAudioFormatFlagIsFloat) != 0
        }

        if isFloat && bytesPerSample == 4 {
            let floatPointer = UnsafeRawPointer(dataPointer).bindMemory(
                to: Float.self,
                capacity: totalLength / 4
            )
            return rmsLevel(floatPointer, count: totalLength / 4)
        }

        if bytesPerSample == 2 {
            let intPointer = UnsafeRawPointer(dataPointer).bindMemory(
                to: Int16.self,
                capacity: totalLength / 2
            )
            return rmsLevel(intPointer, count: totalLength / 2)
        }

        return nil
    }

    private func rmsLevel(_ pointer: UnsafePointer<Float>, count: Int) -> Float? {
        let clampedCount = min(count, 2048)
        guard clampedCount > 0 else { return nil }

        var sum: Float = 0
        for index in 0..<clampedCount {
            let sample = pointer[index]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(clampedCount))
        return pow(min(1.0, rms * 9.0), 0.6)
    }

    private func rmsLevel(_ pointer: UnsafePointer<Int16>, count: Int) -> Float? {
        let clampedCount = min(count, 2048)
        guard clampedCount > 0 else { return nil }

        var sum: Float = 0
        for index in 0..<clampedCount {
            let sample = Float(pointer[index]) / 32768.0
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(clampedCount))
        return pow(min(1.0, rms * 9.0), 0.6)
    }
}

extension SystemAudioMonitorService: SCStreamOutput {
    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .audio, let level = audioLevel(from: sampleBuffer) else { return }
        publish(level: level)
    }
}

extension SystemAudioMonitorService: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        DispatchQueue.main.async {
            self.isCapturing = false
            self.captureErrorMessage = error.localizedDescription
        }
    }
}

private enum CaptureError: LocalizedError {
    case noDisplayAvailable

    var errorDescription: String? {
        switch self {
        case .noDisplayAvailable:
            return "Jam Mode couldn't find a display to capture audio from."
        }
    }
}

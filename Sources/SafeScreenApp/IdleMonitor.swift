import AppKit
import CoreGraphics
import SafeScreenCore

@MainActor
final class IdleMonitor {
    var onIdleThresholdReached: (() -> Void)?

    private let configuration: SafeScreenConfiguration
    private let settingsStore: SettingsStore
    private let overlayController: OverlayController
    private var timer: Timer?

    init(
        configuration: SafeScreenConfiguration,
        settingsStore: SettingsStore,
        overlayController: OverlayController
    ) {
        self.configuration = configuration.normalized
        self.settingsStore = settingsStore
        self.overlayController = overlayController
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        timer?.tolerance = 0.2
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func tick() {
        guard settingsStore.protectionEnabled, !overlayController.isActive else {
            return
        }

        if currentIdleSeconds >= configuration.idleThreshold {
            onIdleThresholdReached?()
        }
    }

    var currentIdleSeconds: TimeInterval {
        CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .safeScreenAnyInput)
    }
}

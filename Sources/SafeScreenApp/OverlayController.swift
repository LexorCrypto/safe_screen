import AppKit
import CoreGraphics
import SafeScreenCore

enum OverlayReason {
    case idle
    case manual
}

@MainActor
final class OverlayController {
    private let configuration: SafeScreenConfiguration
    private var windows: [SafeScreenWindow] = []
    private var dismissalTimer: Timer?
    private var inputMonitors: [Any] = []
    private weak var previouslyActiveApplication: NSRunningApplication?

    init(configuration: SafeScreenConfiguration) {
        self.configuration = configuration.normalized
    }

    var isActive: Bool {
        !windows.isEmpty
    }

    func show(reason: OverlayReason) {
        guard !isActive else {
            return
        }

        previouslyActiveApplication = NSWorkspace.shared.frontmostApplication
        let startTime = ProcessInfo.processInfo.systemUptime
        let model = MatrixAnimationModel(configuration: configuration)

        windows = NSScreen.screens.map { screen in
            let view = MatrixView(model: model, startTime: startTime)
            view.frame = screen.frame
            let window = SafeScreenWindow(screen: screen, contentView: view)
            window.makeKeyAndOrderFront(nil)
            view.start()
            return window
        }

        NSApp.activate(ignoringOtherApps: true)
        installInputMonitors()
        startDismissalTimer()
    }

    func hide() {
        guard isActive else {
            return
        }

        dismissalTimer?.invalidate()
        dismissalTimer = nil
        inputMonitors.forEach(NSEvent.removeMonitor)
        inputMonitors.removeAll()

        for window in windows {
            (window.contentView as? MatrixView)?.stop()
            window.orderOut(nil)
        }
        windows.removeAll()

        previouslyActiveApplication?.activate(options: [])
    }

    private func installInputMonitors() {
        let mask: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .mouseMoved,
            .leftMouseDragged,
            .rightMouseDragged,
            .otherMouseDragged,
            .scrollWheel,
            .keyDown,
            .flagsChanged
        ]

        if let localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.hide()
            return event
        }) {
            inputMonitors.append(localMonitor)
        }

        if let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] _ in
            self?.hide()
        }) {
            inputMonitors.append(globalMonitor)
        }
    }

    private func startDismissalTimer() {
        dismissalTimer?.invalidate()
        dismissalTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(dismissalTick), userInfo: nil, repeats: true)
        dismissalTimer?.tolerance = 0.05
    }

    @objc private func dismissalTick() {
        let idleSeconds = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .safeScreenAnyInput)
        if idleSeconds < 0.75 {
            hide()
        }
    }
}

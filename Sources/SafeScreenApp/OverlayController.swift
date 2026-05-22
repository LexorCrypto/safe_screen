import AppKit
import SafeScreenCore

enum OverlayReason {
    case idle
    case manual
}

@MainActor
final class OverlayController {
    private let configuration: SafeScreenConfiguration
    private var windows: [SafeScreenWindow] = []
    private var inputMonitors: [Any] = []
    private weak var previouslyActiveApplication: NSRunningApplication?
    private var dismissalInputGraceUntil: TimeInterval = 0
    private var activationMouseLocation: NSPoint = .zero

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
        dismissalInputGraceUntil = reason == .manual ? startTime + 1.25 : 0
        activationMouseLocation = NSEvent.mouseLocation
        let model = MatrixAnimationModel(configuration: configuration)

        windows = NSScreen.screens.map { screen in
            let view = MatrixView(model: model, startTime: startTime)
            view.frame = screen.frame
            let window = SafeScreenWindow(screen: screen, contentView: view)
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(view)
            view.start()
            return window
        }

        NSApp.activate(ignoringOtherApps: true)
        installInputMonitors()
    }

    func hide() {
        guard isActive else {
            return
        }

        dismissalInputGraceUntil = 0
        activationMouseLocation = .zero
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
        let localMask: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .mouseMoved,
            .leftMouseDragged,
            .rightMouseDragged,
            .otherMouseDragged,
            .scrollWheel,
            .keyDown
        ]
        let globalMask = localMask.subtracting(.mouseMoved)

        if let localMonitor = NSEvent.addLocalMonitorForEvents(matching: localMask, handler: { [weak self] event in
            guard let self, self.shouldDismiss(for: event) else {
                return event
            }

            self.hide()
            return event
        }) {
            inputMonitors.append(localMonitor)
        }

        if let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: globalMask, handler: { [weak self] event in
            guard let self, self.shouldDismiss(for: event) else {
                return
            }

            self.hide()
        }) {
            inputMonitors.append(globalMonitor)
        }
    }

    private var isIgnoringDismissalInput: Bool {
        ProcessInfo.processInfo.systemUptime < dismissalInputGraceUntil
    }

    private func shouldDismiss(for event: NSEvent?) -> Bool {
        guard !isIgnoringDismissalInput else {
            return false
        }

        guard let event else { return false }

        switch event.type {
        case .mouseMoved:
            return hasMouseMovedEnough()
        case .leftMouseDown,
             .rightMouseDown,
             .otherMouseDown,
             .leftMouseDragged,
             .rightMouseDragged,
             .otherMouseDragged,
             .scrollWheel,
             .keyDown:
            return true
        default:
            return false
        }
    }

    private func hasMouseMovedEnough() -> Bool {
        let location = NSEvent.mouseLocation
        let dx = location.x - activationMouseLocation.x
        let dy = location.y - activationMouseLocation.y
        return dx * dx + dy * dy >= 64
    }
}

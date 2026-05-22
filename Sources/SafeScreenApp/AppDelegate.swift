import AppKit

@MainActor
@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsStore: SettingsStore?
    private var loginItemController: LoginItemController?
    private var overlayController: OverlayController?
    private var idleMonitor: IdleMonitor?
    private var statusMenuController: StatusMenuController?
    private var controlWindowController: ControlWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let configuration = AppConfiguration.load()
        let settingsStore = SettingsStore()
        let loginItemController = LoginItemController()
        let overlayController = OverlayController(configuration: configuration)
        let idleMonitor = IdleMonitor(
            configuration: configuration,
            settingsStore: settingsStore,
            overlayController: overlayController
        )
        let controlWindowController = ControlWindowController(
            settingsStore: settingsStore,
            loginItemController: loginItemController,
            overlayController: overlayController,
            configuration: configuration
        )
        let statusMenuController = StatusMenuController(
            settingsStore: settingsStore,
            loginItemController: loginItemController,
            overlayController: overlayController,
            configuration: configuration,
            showControlPanel: { [weak controlWindowController] in
                controlWindowController?.showPanel()
            }
        )
        controlWindowController.onSettingsChanged = { [weak statusMenuController] in
            statusMenuController?.refresh()
        }

        idleMonitor.onIdleThresholdReached = { [weak overlayController] in
            overlayController?.show(reason: .idle)
        }
        idleMonitor.start()

        self.settingsStore = settingsStore
        self.loginItemController = loginItemController
        self.overlayController = overlayController
        self.idleMonitor = idleMonitor
        self.statusMenuController = statusMenuController
        self.controlWindowController = controlWindowController

        controlWindowController.showPanel()
    }

    func applicationWillTerminate(_ notification: Notification) {
        idleMonitor?.stop()
        overlayController?.hide()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        controlWindowController?.showPanel()
        return true
    }
}

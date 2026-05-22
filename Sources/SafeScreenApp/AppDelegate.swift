import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsStore: SettingsStore?
    private var loginItemController: LoginItemController?
    private var overlayController: OverlayController?
    private var idleMonitor: IdleMonitor?
    private var statusMenuController: StatusMenuController?
    private var controlWindowController: ControlWindowController?
    private var mainMenuController: MainMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

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
        let mainMenuController = MainMenuController(
            overlayController: overlayController,
            showControlPanel: { [weak controlWindowController] in
                controlWindowController?.showPanel()
            }
        )
        mainMenuController.install()

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
        self.mainMenuController = mainMenuController

        DispatchQueue.main.async { [weak self] in
            self?.controlWindowController?.showPanel()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        idleMonitor?.stop()
        overlayController?.hide()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        controlWindowController?.showPanel()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}

import AppKit
import SafeScreenCore

@MainActor
final class StatusMenuController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let settingsStore: SettingsStore
    private let loginItemController: LoginItemController
    private let overlayController: OverlayController
    private let configuration: SafeScreenConfiguration

    private let protectionItem = NSMenuItem()
    private let loginItem = NSMenuItem()

    init(
        settingsStore: SettingsStore,
        loginItemController: LoginItemController,
        overlayController: OverlayController,
        configuration: SafeScreenConfiguration
    ) {
        self.settingsStore = settingsStore
        self.loginItemController = loginItemController
        self.overlayController = overlayController
        self.configuration = configuration
        super.init()
        configure()
    }

    private func configure() {
        statusItem.button?.image = StatusIcon.make()
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.title = " Safe"
        statusItem.button?.toolTip = "Safe Screen"

        let menu = NSMenu()
        let activateItem = NSMenuItem(title: "Activate Now", action: #selector(activateNow), keyEquivalent: "")
        activateItem.target = self
        menu.addItem(activateItem)

        let idleItem = NSMenuItem(title: "Idle threshold: \(Int(configuration.idleThreshold))s", action: nil, keyEquivalent: "")
        idleItem.isEnabled = false
        menu.addItem(idleItem)

        menu.addItem(.separator())

        protectionItem.target = self
        protectionItem.action = #selector(toggleProtection)
        menu.addItem(protectionItem)

        loginItem.target = self
        loginItem.action = #selector(toggleLoginItem)
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Safe Screen", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        refresh()
    }

    func refresh() {
        protectionItem.title = settingsStore.protectionEnabled ? "Protection: On" : "Protection: Off"
        protectionItem.state = settingsStore.protectionEnabled ? .on : .off
        loginItem.title = "Open at Login"
        loginItem.state = loginItemController.isEnabled ? .on : .off
    }

    @objc private func activateNow() {
        overlayController.show(reason: .manual)
    }

    @objc private func toggleProtection() {
        settingsStore.protectionEnabled.toggle()
        refresh()
    }

    @objc private func toggleLoginItem() {
        do {
            try loginItemController.setEnabled(!loginItemController.isEnabled)
        } catch {
            presentLoginItemError(error)
        }
        refresh()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func presentLoginItemError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Open at Login could not be changed"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}

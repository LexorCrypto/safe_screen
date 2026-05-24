import AppKit
import SafeScreenCore

@MainActor
final class StatusMenuController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let settingsStore: SettingsStore
    private let loginItemController: LoginItemController
    private let overlayController: OverlayController
    private let updateController: UpdateController
    private let configuration: SafeScreenConfiguration
    private let showControlPanel: () -> Void

    private let protectionItem = NSMenuItem()
    private let loginItem = NSMenuItem()
    private let updateItem = NSMenuItem()

    init(
        settingsStore: SettingsStore,
        loginItemController: LoginItemController,
        overlayController: OverlayController,
        updateController: UpdateController,
        configuration: SafeScreenConfiguration,
        showControlPanel: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.loginItemController = loginItemController
        self.overlayController = overlayController
        self.updateController = updateController
        self.configuration = configuration
        self.showControlPanel = showControlPanel
        super.init()
        configure()
    }

    private func configure() {
        statusItem.button?.image = StatusIcon.make()
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.title = " Safe"
        statusItem.button?.toolTip = "Safe Screen"

        let menu = NSMenu()
        let showPanelItem = NSMenuItem(title: "Открыть панель", action: #selector(showPanel), keyEquivalent: "")
        showPanelItem.target = self
        menu.addItem(showPanelItem)

        let activateItem = NSMenuItem(title: "Активировать сейчас", action: #selector(activateNow), keyEquivalent: "")
        activateItem.target = self
        menu.addItem(activateItem)

        updateItem.target = self
        updateItem.action = #selector(checkForUpdates)
        menu.addItem(updateItem)

        let idleItem = NSMenuItem(title: "Автовключение: \(Int(configuration.idleThreshold)) сек", action: nil, keyEquivalent: "")
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

        let quitItem = NSMenuItem(title: "Выход", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        refresh()
    }

    func refresh() {
        protectionItem.title = settingsStore.protectionEnabled ? "Защита: включена" : "Защита: выключена"
        protectionItem.state = settingsStore.protectionEnabled ? .on : .off
        loginItem.title = "Открывать при входе"
        loginItem.state = loginItemController.isEnabled ? .on : .off
        updateItem.title = updateController.menuItemTitle
        updateItem.isEnabled = !updateController.isBusy
    }

    @objc private func showPanel() {
        showControlPanel()
    }

    @objc private func activateNow() {
        overlayController.show(reason: .manual)
    }

    @objc private func checkForUpdates() {
        updateController.checkForUpdates()
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
        alert.messageText = "Не удалось изменить автозапуск"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}

import AppKit

@MainActor
final class MainMenuController: NSObject {
    private let overlayController: OverlayController
    private let updateController: UpdateController
    private let showControlPanel: () -> Void
    private let updateItem = NSMenuItem()

    init(
        overlayController: OverlayController,
        updateController: UpdateController,
        showControlPanel: @escaping () -> Void
    ) {
        self.overlayController = overlayController
        self.updateController = updateController
        self.showControlPanel = showControlPanel
        super.init()
    }

    func install() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Safe Screen")
        appMenuItem.submenu = appMenu

        let showPanelItem = NSMenuItem(title: "Открыть панель", action: #selector(showPanel), keyEquivalent: ",")
        showPanelItem.target = self
        appMenu.addItem(showPanelItem)

        let activateItem = NSMenuItem(title: "Активировать сейчас", action: #selector(activateNow), keyEquivalent: "a")
        activateItem.target = self
        appMenu.addItem(activateItem)

        updateItem.target = self
        updateItem.action = #selector(checkForUpdates)
        appMenu.addItem(updateItem)

        appMenu.addItem(.separator())

        let hideItem = NSMenuItem(title: "Скрыть Safe Screen", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        hideItem.target = NSApp
        appMenu.addItem(hideItem)

        appMenu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Выход из Safe Screen", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        appMenu.addItem(quitItem)

        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
        refresh()
    }

    func refresh() {
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
}

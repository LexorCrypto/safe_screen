import AppKit
import SafeScreenCore

@MainActor
final class ControlWindowController: NSWindowController {
    var onSettingsChanged: (() -> Void)?

    private let settingsStore: SettingsStore
    private let loginItemController: LoginItemController
    private let overlayController: OverlayController
    private let configuration: SafeScreenConfiguration

    private let statusLabel = NSTextField(labelWithString: "")
    private let protectionCheckbox = NSButton(checkboxWithTitle: "Защита включена", target: nil, action: nil)
    private let loginCheckbox = NSButton(checkboxWithTitle: "Открывать при входе в macOS", target: nil, action: nil)

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

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Safe Screen"
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace]
        window.center()

        super.init(window: window)
        window.contentView = makeContentView()
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func showPanel() {
        refresh()
        guard let window else { return }
        if !window.isVisible {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeContentView() -> NSView {
        let contentView = NSView()
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let icon = NSImageView(image: StatusIcon.make())
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.imageScaling = .scaleProportionallyUpOrDown

        let titleLabel = NSTextField(labelWithString: "Safe Screen работает")
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        let subtitleLabel = NSTextField(labelWithString: "Черный Matrix-экран включится после \(Int(configuration.idleThreshold)) секунд неактивности.")
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.maximumNumberOfLines = 2

        let headerTextStack = NSStackView(views: [titleLabel, subtitleLabel])
        headerTextStack.orientation = .vertical
        headerTextStack.alignment = .leading
        headerTextStack.spacing = 4

        let headerStack = NSStackView(views: [icon, headerTextStack])
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 12

        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.maximumNumberOfLines = 2

        protectionCheckbox.target = self
        protectionCheckbox.action = #selector(toggleProtection)

        loginCheckbox.target = self
        loginCheckbox.action = #selector(toggleLoginItem)

        let activateButton = NSButton(title: "Активировать сейчас", target: self, action: #selector(activateNow))
        activateButton.bezelStyle = .rounded
        activateButton.keyEquivalent = "\r"

        let hideButton = NSButton(title: "Скрыть окно", target: self, action: #selector(hideWindow))
        hideButton.bezelStyle = .rounded

        let quitButton = NSButton(title: "Выход", target: self, action: #selector(quit))
        quitButton.bezelStyle = .rounded

        let buttonStack = NSStackView(views: [activateButton, hideButton, quitButton])
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 8

        let hintLabel = NSTextField(labelWithString: "После закрытия окно можно открыть из верхнего меню macOS: Safe.")
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = .tertiaryLabelColor
        hintLabel.lineBreakMode = .byWordWrapping
        hintLabel.maximumNumberOfLines = 2

        let mainStack = NSStackView(views: [
            headerStack,
            statusLabel,
            protectionCheckbox,
            loginCheckbox,
            buttonStack,
            hintLabel
        ])
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 14

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 32),
            icon.heightAnchor.constraint(equalToConstant: 32),
            headerTextStack.widthAnchor.constraint(equalToConstant: 360),
            buttonStack.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        return contentView
    }

    private func refresh() {
        protectionCheckbox.state = settingsStore.protectionEnabled ? .on : .off
        loginCheckbox.state = loginItemController.isEnabled ? .on : .off
        statusLabel.stringValue = settingsStore.protectionEnabled
            ? "Защита активна. Можно оставить Mac подключенным к питанию, Safe Screen сам включится при простое."
            : "Защита выключена. Автоматическое включение Matrix-экрана сейчас не сработает."
    }

    @objc private func activateNow() {
        overlayController.show(reason: .manual)
    }

    @objc private func toggleProtection() {
        settingsStore.protectionEnabled = protectionCheckbox.state == .on
        refresh()
        onSettingsChanged?()
    }

    @objc private func toggleLoginItem() {
        do {
            try loginItemController.setEnabled(loginCheckbox.state == .on)
        } catch {
            presentLoginItemError(error)
        }
        refresh()
        onSettingsChanged?()
    }

    @objc private func hideWindow() {
        window?.orderOut(nil)
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

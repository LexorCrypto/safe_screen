import Foundation

final class SettingsStore {
    private enum Key {
        static let protectionEnabled = "protectionEnabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Key.protectionEnabled) == nil {
            defaults.set(true, forKey: Key.protectionEnabled)
        }
    }

    var protectionEnabled: Bool {
        get { defaults.bool(forKey: Key.protectionEnabled) }
        set { defaults.set(newValue, forKey: Key.protectionEnabled) }
    }
}

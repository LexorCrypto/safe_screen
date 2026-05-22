import Foundation
import SafeScreenCore

struct AppConfiguration {
    static func load() -> SafeScreenConfiguration {
        var configuration = SafeScreenConfiguration()
        let environment = ProcessInfo.processInfo.environment

        if let value = environment["SAFE_SCREEN_IDLE_SECONDS"].flatMap(TimeInterval.init) {
            configuration.idleThreshold = value
        }
        if let value = environment["SAFE_SCREEN_LAYOUT_SECONDS"].flatMap(TimeInterval.init) {
            configuration.layoutChangeInterval = value
        }
        if let value = environment["SAFE_SCREEN_TRANSITION_SECONDS"].flatMap(TimeInterval.init) {
            configuration.transitionDuration = value
        }

        return configuration.normalized
    }
}

import Foundation

public struct SafeScreenConfiguration: Equatable, Sendable {
    public var idleThreshold: TimeInterval
    public var layoutChangeInterval: TimeInterval
    public var transitionDuration: TimeInterval
    public var streamCount: Int
    public var minimumColumnInset: Double

    public init(
        idleThreshold: TimeInterval = 60,
        layoutChangeInterval: TimeInterval = 20,
        transitionDuration: TimeInterval = 4,
        streamCount: Int = 5,
        minimumColumnInset: Double = 28
    ) {
        self.idleThreshold = idleThreshold
        self.layoutChangeInterval = layoutChangeInterval
        self.transitionDuration = transitionDuration
        self.streamCount = streamCount
        self.minimumColumnInset = minimumColumnInset
    }

    public var normalized: SafeScreenConfiguration {
        SafeScreenConfiguration(
            idleThreshold: max(1, idleThreshold),
            layoutChangeInterval: max(1, layoutChangeInterval),
            transitionDuration: min(max(0.1, transitionDuration), max(0.1, layoutChangeInterval * 0.75)),
            streamCount: max(1, streamCount),
            minimumColumnInset: max(0, minimumColumnInset)
        )
    }
}

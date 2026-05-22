import Foundation

public struct MatrixAnimationModel: Equatable, Sendable {
    public var configuration: SafeScreenConfiguration
    public var seed: UInt64

    public init(configuration: SafeScreenConfiguration = SafeScreenConfiguration(), seed: UInt64 = 0x5341_4645_5343_524E) {
        self.configuration = configuration.normalized
        self.seed = seed
    }

    public func layout(for generation: Int, in canvasSize: MatrixCanvasSize) -> MatrixLayout {
        let config = configuration.normalized
        let size = canvasSize.normalized
        let generationSeed = seed
            ^ UInt64(bitPattern: Int64(generation &* 1_000_003))
            ^ 0xA5A5_A5A5_5A5A_5A5A
        var generator = SeededGenerator(seed: generationSeed)

        let count = config.streamCount
        let usableWidth = max(1, size.width - config.minimumColumnInset * 2)
        let bucketWidth = usableWidth / Double(count)

        let streams = (0..<count).map { index -> MatrixStream in
            let glyphSize = Double.random(in: 20...34, using: &generator)
            let maxXInBucket = max(0, bucketWidth - glyphSize)
            let bucketStart = config.minimumColumnInset + Double(index) * bucketWidth
            let x = min(
                max(config.minimumColumnInset, bucketStart + Double.random(in: 0...maxXInBucket, using: &generator)),
                max(config.minimumColumnInset, size.width - config.minimumColumnInset - glyphSize)
            )
            let speed = Double.random(in: 58...112, using: &generator)
            let phase = Double.random(in: 0...(size.height + 360), using: &generator)
            let glyphCount = Int.random(in: 22...38, using: &generator)
            return MatrixStream(
                id: generation * 10_000 + index,
                x: x,
                speed: speed,
                phase: phase,
                glyphSize: glyphSize,
                glyphCount: glyphCount
            )
        }

        return MatrixLayout(generation: generation, streams: streams)
    }

    public func renderLayers(elapsedTime: TimeInterval, canvasSize: MatrixCanvasSize) -> [MatrixRenderLayer] {
        let config = configuration.normalized
        let elapsed = max(0, elapsedTime)
        let generation = Int(floor(elapsed / config.layoutChangeInterval))
        let activeLayout = layout(for: generation, in: canvasSize)

        guard generation > 0 else {
            return [MatrixRenderLayer(layout: activeLayout, opacity: 1, verticalOffset: 0)]
        }

        let timeInsideGeneration = elapsed - Double(generation) * config.layoutChangeInterval
        guard timeInsideGeneration < config.transitionDuration else {
            return [MatrixRenderLayer(layout: activeLayout, opacity: 1, verticalOffset: 0)]
        }

        let rawProgress = timeInsideGeneration / config.transitionDuration
        let easedProgress = smoothStep(clamp(rawProgress))
        let outgoingLayout = layout(for: generation - 1, in: canvasSize)

        return [
            MatrixRenderLayer(
                layout: outgoingLayout,
                opacity: 1 - easedProgress,
                verticalOffset: easedProgress * 120
            ),
            MatrixRenderLayer(
                layout: activeLayout,
                opacity: easedProgress,
                verticalOffset: -(1 - easedProgress) * 90
            )
        ]
    }

    private func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }

    private func smoothStep(_ value: Double) -> Double {
        value * value * (3 - 2 * value)
    }
}

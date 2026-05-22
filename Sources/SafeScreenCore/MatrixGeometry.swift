import Foundation

public struct MatrixCanvasSize: Equatable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public var normalized: MatrixCanvasSize {
        MatrixCanvasSize(width: max(1, width), height: max(1, height))
    }
}

public struct MatrixStream: Equatable, Identifiable, Sendable {
    public var id: Int
    public var x: Double
    public var speed: Double
    public var phase: Double
    public var glyphSize: Double
    public var glyphCount: Int

    public init(id: Int, x: Double, speed: Double, phase: Double, glyphSize: Double, glyphCount: Int) {
        self.id = id
        self.x = x
        self.speed = speed
        self.phase = phase
        self.glyphSize = glyphSize
        self.glyphCount = glyphCount
    }
}

public struct MatrixLayout: Equatable, Sendable {
    public var generation: Int
    public var streams: [MatrixStream]

    public init(generation: Int, streams: [MatrixStream]) {
        self.generation = generation
        self.streams = streams
    }
}

public struct MatrixRenderLayer: Equatable, Sendable {
    public var layout: MatrixLayout
    public var opacity: Double
    public var verticalOffset: Double

    public init(layout: MatrixLayout, opacity: Double, verticalOffset: Double) {
        self.layout = layout
        self.opacity = opacity
        self.verticalOffset = verticalOffset
    }
}

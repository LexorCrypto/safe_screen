import AppKit
import SafeScreenCore

@MainActor
final class MatrixView: NSView {
    private static let glyphs = Array("アイウエオカキクケコサシスセソタチツテトナニヌネノマミムメモヤユヨラリルレロワヲン0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    private let model: MatrixAnimationModel
    private let startTime: TimeInterval
    private var timer: Timer?
    private let paragraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }()

    init(model: MatrixAnimationModel, startTime: TimeInterval) {
        self.model = model
        self.startTime = startTime
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1 / 30, target: self, selector: #selector(redraw), userInfo: nil, repeats: true)
        timer?.tolerance = 0.006
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    @objc private func redraw() {
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()

        let elapsed = ProcessInfo.processInfo.systemUptime - startTime
        let canvasSize = MatrixCanvasSize(width: bounds.width, height: bounds.height)
        let layers = model.renderLayers(elapsedTime: elapsed, canvasSize: canvasSize)

        for layer in layers {
            draw(layer: layer, elapsed: elapsed)
        }
    }

    private func draw(layer: MatrixRenderLayer, elapsed: TimeInterval) {
        for stream in layer.layout.streams {
            draw(stream: stream, generation: layer.layout.generation, elapsed: elapsed, layer: layer)
        }
    }

    private func draw(stream: MatrixStream, generation: Int, elapsed: TimeInterval, layer: MatrixRenderLayer) {
        let step = stream.glyphSize * 1.12
        let travel = bounds.height + step * Double(stream.glyphCount + 3)
        let headTravel = (elapsed * stream.speed + stream.phase).truncatingRemainder(dividingBy: travel)
        let font = NSFont.monospacedSystemFont(ofSize: stream.glyphSize, weight: .medium)

        for index in 0..<stream.glyphCount {
            let y = bounds.maxY - headTravel + Double(index) * step + layer.verticalOffset
            guard y > -step, y < bounds.maxY + step else {
                continue
            }

            let rowFactor = 1 - Double(index) / Double(max(1, stream.glyphCount))
            let alpha = layer.opacity * max(0.05, rowFactor * rowFactor) * 0.42
            let color = index == 0
                ? NSColor(calibratedRed: 0.78, green: 1.0, blue: 0.82, alpha: min(0.82, alpha + 0.25))
                : NSColor(calibratedRed: 0.10, green: 0.85, blue: 0.28, alpha: alpha)

            let glyph = glyph(for: generation, streamID: stream.id, row: index, elapsed: elapsed)
            let rect = NSRect(x: stream.x, y: y, width: stream.glyphSize * 1.2, height: step)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
            String(glyph).draw(in: rect, withAttributes: attributes)
        }
    }

    private func glyph(for generation: Int, streamID: Int, row: Int, elapsed: TimeInterval) -> Character {
        let tick = Int(elapsed * 8)
        let mixed = abs(generation &* 73_856_093 ^ streamID &* 19_349_663 ^ row &* 83_492_791 ^ tick)
        return Self.glyphs[mixed % Self.glyphs.count]
    }
}

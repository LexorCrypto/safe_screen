import AppKit

@MainActor
enum StatusIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let frameRect = NSRect(x: 2.0, y: 2.0, width: 14.0, height: 14.0)
        let frame = NSBezierPath(roundedRect: frameRect, xRadius: 3.4, yRadius: 3.4)
        NSColor(calibratedRed: 0.005, green: 0.035, blue: 0.018, alpha: 1).setFill()
        frame.fill()

        NSColor(calibratedRed: 0.16, green: 1.00, blue: 0.42, alpha: 0.88).setStroke()
        frame.lineWidth = 1.15
        frame.stroke()

        let screenRect = frameRect.insetBy(dx: 3.0, dy: 2.7)
        let screen = NSBezierPath(roundedRect: screenRect, xRadius: 1.7, yRadius: 1.7)
        NSGraphicsContext.saveGraphicsState()
        screen.addClip()

        let brightColor = NSColor(calibratedRed: 0.22, green: 1.00, blue: 0.50, alpha: 0.95)
        let dimColor = NSColor(calibratedRed: 0.08, green: 0.54, blue: 0.23, alpha: 0.80)

        for column in 0..<3 {
            let x = screenRect.minX + 1.1 + CGFloat(column) * 3.0
            let y = screenRect.minY + CGFloat([1.3, 0.1, 2.0][column])
            let height = CGFloat([7.4, 9.2, 6.4][column])
            let barRect = NSRect(x: x, y: y, width: 1.15, height: height)
            let bar = NSBezierPath(roundedRect: barRect, xRadius: 0.58, yRadius: 0.58)
            (column == 1 ? brightColor : dimColor).setFill()
            bar.fill()
        }

        NSGraphicsContext.restoreGraphicsState()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

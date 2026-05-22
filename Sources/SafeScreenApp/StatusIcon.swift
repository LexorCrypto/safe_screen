import AppKit

@MainActor
enum StatusIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let strokeColor = NSColor(calibratedRed: 0.25, green: 0.95, blue: 0.48, alpha: 0.95)
        let dimColor = NSColor(calibratedRed: 0.08, green: 0.42, blue: 0.20, alpha: 0.85)

        for column in 0..<4 {
            let x = 3 + CGFloat(column) * 3.4
            let height = CGFloat([10, 15, 12, 8][column])
            let rect = NSRect(x: x, y: 2, width: 1.4, height: height)
            let path = NSBezierPath(roundedRect: rect, xRadius: 0.7, yRadius: 0.7)
            (column == 1 ? strokeColor : dimColor).setFill()
            path.fill()
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

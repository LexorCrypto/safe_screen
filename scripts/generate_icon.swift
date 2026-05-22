import AppKit
import Foundation

enum IconError: Error {
    case missingOutputPath
    case pngEncodingFailed(String)
    case iconutilFailed(Int32)
}

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    throw IconError.missingOutputPath
}

let outputURL = URL(fileURLWithPath: arguments[1])
let fileManager = FileManager.default
let iconsetURL = outputURL
    .deletingLastPathComponent()
    .appendingPathComponent("SafeScreen.iconset", isDirectory: true)

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

let icons: [(base: Int, scale: Int, name: String)] = [
    (16, 1, "icon_16x16.png"),
    (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"),
    (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png")
]

for icon in icons {
    let pixels = icon.base * icon.scale
    let image = drawIcon(pixelSize: pixels)
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw IconError.pngEncodingFailed(icon.name)
    }

    try data.write(to: iconsetURL.appendingPathComponent(icon.name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", "-o", outputURL.path, iconsetURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw IconError.iconutilFailed(process.terminationStatus)
}

try? fileManager.removeItem(at: iconsetURL)

func drawIcon(pixelSize: Int) -> NSImage {
    let size = NSSize(width: pixelSize, height: pixelSize)
    let image = NSImage(size: size)
    image.lockFocus()

    let scale = CGFloat(pixelSize)
    let rect = NSRect(origin: .zero, size: size)
    NSColor.clear.setFill()
    rect.fill()

    let outerRect = rect.insetBy(dx: scale * 0.055, dy: scale * 0.055)
    let outerCorner = scale * 0.20
    let outerPath = NSBezierPath(roundedRect: outerRect, xRadius: outerCorner, yRadius: outerCorner)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.008, green: 0.020, blue: 0.014, alpha: 1),
        NSColor(calibratedRed: 0.018, green: 0.052, blue: 0.030, alpha: 1)
    ])?.draw(in: outerPath, angle: 90)

    NSColor(calibratedRed: 0.00, green: 0.52, blue: 0.20, alpha: 0.42).setStroke()
    outerPath.lineWidth = max(1, scale * 0.032)
    outerPath.stroke()

    NSColor(calibratedRed: 0.18, green: 1.00, blue: 0.43, alpha: 0.85).setStroke()
    outerPath.lineWidth = max(1, scale * 0.012)
    outerPath.stroke()

    let screenRect = outerRect.insetBy(dx: scale * 0.115, dy: scale * 0.115)
    let screenCorner = scale * 0.105
    let screenPath = NSBezierPath(roundedRect: screenRect, xRadius: screenCorner, yRadius: screenCorner)
    NSColor(calibratedRed: 0.000, green: 0.008, blue: 0.006, alpha: 0.96).setFill()
    screenPath.fill()

    NSColor(calibratedRed: 0.07, green: 0.34, blue: 0.16, alpha: 0.85).setStroke()
    screenPath.lineWidth = max(1, scale * 0.010)
    screenPath.stroke()

    NSGraphicsContext.saveGraphicsState()
    screenPath.addClip()
    drawMatrixRain(in: screenRect, scale: scale)
    NSGraphicsContext.restoreGraphicsState()

    drawShield(in: NSRect(
        x: rect.midX - scale * 0.145,
        y: outerRect.minY + scale * 0.145,
        width: scale * 0.29,
        height: scale * 0.33
    ), scale: scale)

    let topHighlight = NSBezierPath()
    topHighlight.move(to: NSPoint(x: screenRect.minX + scale * 0.065, y: screenRect.maxY - scale * 0.072))
    topHighlight.line(to: NSPoint(x: screenRect.maxX - scale * 0.065, y: screenRect.maxY - scale * 0.072))
    topHighlight.lineCapStyle = .round
    topHighlight.lineWidth = max(1, scale * 0.008)
    NSColor(calibratedRed: 0.34, green: 1.00, blue: 0.56, alpha: 0.30).setStroke()
    topHighlight.stroke()

    image.unlockFocus()
    return image
}

func drawMatrixRain(in screenRect: NSRect, scale: CGFloat) {
    let streams: [(x: CGFloat, phase: CGFloat, rows: Int)] = [
        (0.18, 0.00, 7),
        (0.34, 0.42, 8),
        (0.50, 0.18, 6),
        (0.66, 0.58, 8),
        (0.82, 0.30, 7)
    ]
    let cellWidth = max(1.5, scale * 0.036)
    let cellHeight = max(2.0, scale * 0.055)
    let step = scale * 0.077

    for (streamIndex, stream) in streams.enumerated() {
        let x = screenRect.minX + stream.x * screenRect.width - cellWidth / 2
        let headY = screenRect.maxY - scale * (0.082 + stream.phase * 0.07)

        for row in 0..<stream.rows {
            let y = headY - CGFloat(row) * step
            guard y >= screenRect.minY + scale * 0.035, y + cellHeight <= screenRect.maxY - scale * 0.030 else {
                continue
            }

            let jitter = CGFloat((row + streamIndex) % 2) * scale * 0.006
            let cellRect = NSRect(
                x: x + jitter,
                y: y,
                width: cellWidth,
                height: row % 3 == 0 ? cellHeight * 0.72 : cellHeight
            )
            let cell = NSBezierPath(
                roundedRect: cellRect,
                xRadius: cellWidth / 2,
                yRadius: cellWidth / 2
            )
            let alpha = row == 0 ? 0.88 : max(0.16, 0.58 - CGFloat(row) * 0.055)
            NSColor(calibratedRed: 0.16, green: 1.00, blue: 0.38, alpha: alpha).setFill()
            cell.fill()
        }
    }

    let softGlow = NSBezierPath(ovalIn: screenRect.insetBy(dx: -scale * 0.12, dy: scale * 0.10))
    NSColor(calibratedRed: 0.02, green: 0.45, blue: 0.18, alpha: 0.10).setFill()
    softGlow.fill()
}

func drawShield(in shieldRect: NSRect, scale: CGFloat) {
    let shield = NSBezierPath()
    shield.move(to: NSPoint(x: shieldRect.midX, y: shieldRect.maxY))
    shield.curve(
        to: NSPoint(x: shieldRect.minX + shieldRect.width * 0.12, y: shieldRect.maxY - shieldRect.height * 0.23),
        controlPoint1: NSPoint(x: shieldRect.midX - shieldRect.width * 0.20, y: shieldRect.maxY - shieldRect.height * 0.01),
        controlPoint2: NSPoint(x: shieldRect.minX + shieldRect.width * 0.19, y: shieldRect.maxY - shieldRect.height * 0.13)
    )
    shield.curve(
        to: NSPoint(x: shieldRect.midX, y: shieldRect.minY),
        controlPoint1: NSPoint(x: shieldRect.minX + shieldRect.width * 0.10, y: shieldRect.midY - shieldRect.height * 0.15),
        controlPoint2: NSPoint(x: shieldRect.minX + shieldRect.width * 0.27, y: shieldRect.minY + shieldRect.height * 0.12)
    )
    shield.curve(
        to: NSPoint(x: shieldRect.maxX - shieldRect.width * 0.12, y: shieldRect.maxY - shieldRect.height * 0.23),
        controlPoint1: NSPoint(x: shieldRect.maxX - shieldRect.width * 0.27, y: shieldRect.minY + shieldRect.height * 0.12),
        controlPoint2: NSPoint(x: shieldRect.maxX - shieldRect.width * 0.10, y: shieldRect.midY - shieldRect.height * 0.15)
    )
    shield.curve(
        to: NSPoint(x: shieldRect.midX, y: shieldRect.maxY),
        controlPoint1: NSPoint(x: shieldRect.maxX - shieldRect.width * 0.19, y: shieldRect.maxY - shieldRect.height * 0.13),
        controlPoint2: NSPoint(x: shieldRect.midX + shieldRect.width * 0.20, y: shieldRect.maxY - shieldRect.height * 0.01)
    )
    shield.close()

    NSColor(calibratedRed: 0.000, green: 0.045, blue: 0.024, alpha: 0.92).setFill()
    shield.fill()

    NSColor(calibratedRed: 0.16, green: 1.00, blue: 0.42, alpha: 0.88).setStroke()
    shield.lineWidth = max(1, scale * 0.014)
    shield.stroke()

    let check = NSBezierPath()
    check.move(to: NSPoint(x: shieldRect.minX + shieldRect.width * 0.28, y: shieldRect.minY + shieldRect.height * 0.48))
    check.line(to: NSPoint(x: shieldRect.minX + shieldRect.width * 0.44, y: shieldRect.minY + shieldRect.height * 0.34))
    check.line(to: NSPoint(x: shieldRect.minX + shieldRect.width * 0.73, y: shieldRect.minY + shieldRect.height * 0.63))
    check.lineCapStyle = .round
    check.lineJoinStyle = .round
    check.lineWidth = max(1, scale * 0.026)
    NSColor(calibratedRed: 0.21, green: 1.00, blue: 0.48, alpha: 0.92).setStroke()
    check.stroke()
}

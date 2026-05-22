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

    let rect = NSRect(origin: .zero, size: size)
    NSColor.black.setFill()
    rect.fill()

    let corner = CGFloat(pixelSize) * 0.18
    let background = NSBezierPath(roundedRect: rect.insetBy(dx: CGFloat(pixelSize) * 0.05, dy: CGFloat(pixelSize) * 0.05), xRadius: corner, yRadius: corner)
    NSColor(calibratedRed: 0.015, green: 0.035, blue: 0.02, alpha: 1).setFill()
    background.fill()

    NSColor(calibratedRed: 0.10, green: 0.82, blue: 0.30, alpha: 0.65).setStroke()
    background.lineWidth = max(1, CGFloat(pixelSize) * 0.018)
    background.stroke()

    let columnCount = 7
    let margin = CGFloat(pixelSize) * 0.18
    let columnWidth = CGFloat(pixelSize) * 0.055
    let gap = (CGFloat(pixelSize) - margin * 2 - columnWidth * CGFloat(columnCount)) / CGFloat(columnCount - 1)

    for index in 0..<columnCount {
        let x = margin + CGFloat(index) * (columnWidth + gap)
        let heightFactor = [0.55, 0.82, 0.40, 0.72, 0.92, 0.48, 0.66][index]
        let columnHeight = CGFloat(pixelSize) * heightFactor
        let y = CGFloat(pixelSize) * 0.12
        let column = NSBezierPath(
            roundedRect: NSRect(x: x, y: y, width: columnWidth, height: columnHeight),
            xRadius: columnWidth / 2,
            yRadius: columnWidth / 2
        )
        let alpha = index == 4 ? 0.95 : 0.45
        NSColor(calibratedRed: 0.12, green: 0.95, blue: 0.34, alpha: alpha).setFill()
        column.fill()
    }

    image.unlockFocus()
    return image
}

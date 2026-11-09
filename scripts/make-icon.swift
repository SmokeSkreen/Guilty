import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = root.appendingPathComponent("Guilty.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
func drawIcon(size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    let dark = NSColor(red: 0.10, green: 0.14, blue: 0.13, alpha: 1)
    let lime = NSColor(red: 0.77, green: 0.95, blue: 0.39, alpha: 1)
    dark.setFill()
    NSBezierPath(roundedRect: NSRect(x: 40, y: 40, width: 944, height: 944), xRadius: 210, yRadius: 210).fill()
    let shield = NSBezierPath()
    shield.move(to: NSPoint(x: 512, y: 840))
    shield.curve(to: NSPoint(x: 785, y: 740), controlPoint1: NSPoint(x: 620, y: 790), controlPoint2: NSPoint(x: 710, y: 755))
    shield.line(to: NSPoint(x: 785, y: 510))
    shield.curve(to: NSPoint(x: 512, y: 185), controlPoint1: NSPoint(x: 785, y: 355), controlPoint2: NSPoint(x: 640, y: 235))
    shield.curve(to: NSPoint(x: 239, y: 510), controlPoint1: NSPoint(x: 384, y: 235), controlPoint2: NSPoint(x: 239, y: 355))
    shield.line(to: NSPoint(x: 239, y: 740))
    shield.curve(to: NSPoint(x: 512, y: 840), controlPoint1: NSPoint(x: 314, y: 755), controlPoint2: NSPoint(x: 404, y: 790))
    shield.close(); lime.setFill(); shield.fill()
    // The bold gavel stays readable at Spotlight's smallest sizes.
    let transform = AffineTransform(translationByX: 510, byY: 525)
    let rotation = AffineTransform(rotationByDegrees: -38)
    let gavel = NSBezierPath(roundedRect: NSRect(x: -35, y: -170, width: 70, height: 250), xRadius: 28, yRadius: 28)
    gavel.append(NSBezierPath(roundedRect: NSRect(x: -137, y: 35, width: 274, height: 120), xRadius: 30, yRadius: 30))
    gavel.transform(using: rotation); gavel.transform(using: transform)
    dark.setFill(); gavel.fill()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}
for size in [16, 32, 128, 256, 512] {
    try drawIcon(size: size).write(to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try drawIcon(size: size * 2).write(to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
try drawIcon(size: 1024).write(to: root.appendingPathComponent("Guilty.png"))

// ICNS stores each modern icon size as a PNG payload.
func bigEndian(_ value: Int) -> Data {
    var number = UInt32(value).bigEndian
    return withUnsafeBytes(of: &number) { Data($0) }
}
var chunks = Data()
for (type, size) in [("icp4", 16), ("icp5", 32), ("icp6", 64), ("ic07", 128), ("ic08", 256), ("ic09", 512), ("ic10", 1024), ("ic11", 32), ("ic12", 64), ("ic13", 256), ("ic14", 512)] {
    let png = drawIcon(size: size)
    chunks.append(Data(type.utf8)); chunks.append(bigEndian(png.count + 8)); chunks.append(png)
}
var icns = Data("icns".utf8)
icns.append(bigEndian(chunks.count + 8)); icns.append(chunks)
try icns.write(to: root.appendingPathComponent("Guilty.icns"))

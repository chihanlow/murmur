// Draws the Murmur icon: voice bars that end in a text cursor, i.e. speech becoming text.
import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// macOS icon grid: 824pt squircle centred on a 1024 canvas.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: NSColor.black.withAlphaComponent(0.3).cgColor)
ctx.addPath(shape)
ctx.setFillColor(NSColor.black.cgColor)
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(shape)
ctx.clip()
let colors = [NSColor(srgbRed: 0.27, green: 0.22, blue: 0.80, alpha: 1).cgColor,
              NSColor(srgbRed: 0.10, green: 0.09, blue: 0.29, alpha: 1).cgColor] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 200, y: 924), end: CGPoint(x: 824, y: 100), options: [])
ctx.restoreGState()

// Four voice bars, then the cursor.
let barWidth: CGFloat = 64
let gap: CGFloat = 44
let heights: [CGFloat] = [190, 360, 270, 140]
let cursorHeight: CGFloat = 420
let totalWidth = CGFloat(heights.count) * (barWidth + gap) + 30 + 34
var x = (size - totalWidth) / 2
for h in heights {
    let bar = CGRect(x: x, y: size / 2 - h / 2, width: barWidth, height: h)
    ctx.addPath(CGPath(roundedRect: bar, cornerWidth: barWidth / 2, cornerHeight: barWidth / 2, transform: nil))
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillPath()
    x += barWidth + gap
}
x += 30
let cursor = CGRect(x: x, y: size / 2 - cursorHeight / 2, width: 34, height: cursorHeight)
ctx.addPath(CGPath(roundedRect: cursor, cornerWidth: 17, cornerHeight: 17, transform: nil))
ctx.setFillColor(NSColor(srgbRed: 0.37, green: 0.92, blue: 0.83, alpha: 1).cgColor)
ctx.fillPath()

image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))

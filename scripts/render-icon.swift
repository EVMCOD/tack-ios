#!/usr/bin/env swift
// Generates a 1024×1024 PNG icon for Tack using AppKit + CoreGraphics.
// Run with: `swift scripts/render-icon.swift`
// Output: assets/AppIcon.appiconset/AppIcon.png AND Desktop/Tack-icon.png + @2x preview

import Foundation
import AppKit
import CoreGraphics

let size: CGFloat = 1024
let outPath = "/Users/enriquevaleros/tack-ios/Tack/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let desktopPath = "/Users/enriquevaleros/Desktop/Tack-icon.png"
let previewPath = "/Users/enriquevaleros/Desktop/Tack-icon@2x.png"

let brand = (r: 0.357, g: 0.561, b: 0.976)
let brandDeep = (r: 0.255, g: 0.412, b: 0.835)
let brandNight = (r: 0.043, g: 0.055, b: 0.071)
let brandDeepNight = (r: 0.020, g: 0.027, b: 0.043)
let streak = (r: 0.984, g: 0.412, b: 0.310)

func rgb(_ c: (r: Double, g: Double, b: Double), _ a: Double = 1.0) -> NSColor {
    NSColor(srgbRed: c.r, green: c.g, blue: c.b, alpha: a)
}

// 1. Image + bitmap context
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
guard let ctx = NSGraphicsContext.current else {
    print("No graphics context"); exit(1)
}
let cg = ctx.cgContext
cg.setAllowsAntialiasing(true)
cg.setShouldAntialias(true)
cg.interpolationQuality = CGInterpolationQuality.high

let rect = NSRect(x: 0, y: 0, width: size, height: size)

// 2. Background — vertical gradient
let bgGrad = NSGradient(colors: [
    rgb(brandNight, 1.0),
    rgb(brandDeepNight, 1.0)
], atLocations: [0.0, 1.0], colorSpace: NSColorSpace.sRGB)!
bgGrad.draw(in: rect, angle: 270)

// 3. Radial accent glow (top-right)
let glowCenter = CGPoint(x: size * 0.74, y: size * 0.78)
let glowRadius: CGFloat = size * 0.62
if let srgbSpace = NSColorSpace.sRGB.cgColorSpace,
   let glowGrad = CGGradient(
        colorsSpace: srgbSpace,
        colors: [rgb(brand, 0.30).cgColor, rgb(brand, 0.0).cgColor] as CFArray,
        locations: [0.0, 1.0]
   ) {
    cg.saveGState()
    cg.drawRadialGradient(
        glowGrad,
        startCenter: glowCenter, startRadius: 0,
        endCenter: glowCenter, endRadius: glowRadius,
        options: CGGradientDrawingOptions.drawsBeforeStartLocation
    )
    cg.restoreGState()
}

// 4. Mast — vertical rounded white bar
let mastRect = NSRect(x: size * 0.46, y: size * 0.18, width: size * 0.08, height: size * 0.72)
let mast = NSBezierPath(roundedRect: mastRect, xRadius: size * 0.04, yRadius: size * 0.04)
let mastGrad = NSGradient(colors: [
    rgb((1.0, 1.0, 1.0), 0.95),
    rgb((1.0, 1.0, 1.0), 0.65)
], atLocations: [0.0, 1.0], colorSpace: NSColorSpace.sRGB)!
cg.saveGState()
mastGrad.draw(in: mast, angle: 270)
cg.restoreGState()

// 5. Sail — curved triangular shape billowing LEFT (classic sailboat silhouette)
//
// Geometry: mast at center (vertical white bar). Sail attaches on left side:
//   - top of sail at apex (slightly left of mast top)
//   - bottom of sail at base of mast
//   - leech (trailing edge) curves back to the left like a swelling wind-filled sail
//
// This orientation reads as "boat" + "forward motion" at small sizes.

let apex = NSPoint(x: size * 0.48, y: size * 0.84)
let baseBottom = NSPoint(x: size * 0.18, y: size * 0.30)
let baseTop = NSPoint(x: size * 0.50, y: size * 0.30)

let sail = NSBezierPath()
sail.move(to: baseBottom)
// Curve out (wind-curved leech) up to the top of the sail
sail.curve(to: apex,
           controlPoint1: NSPoint(x: size * 0.16, y: size * 0.62),
           controlPoint2: NSPoint(x: size * 0.30, y: size * 0.78))
// Top to baseTop (along the mast)
sail.line(to: baseTop)
// Back to start (close along the boom line)
sail.close()

// Drop shadow
let shadow = NSShadow()
shadow.shadowOffset = NSSize(width: 6, height: -10)
shadow.shadowBlurRadius = 24
shadow.shadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.45)
cg.saveGState()
shadow.set()
sail.fill()
cg.restoreGState()

// Sail gradient (lighter top → deeper bottom)
let sailGrad = NSGradient(colors: [
    rgb(brand, 1.0),
    rgb(brandDeep, 1.0)
], atLocations: [0.0, 1.0], colorSpace: NSColorSpace.sRGB)!
sailGrad.draw(in: sail, angle: 240)

// 6. Highlight stripe ON sail — thin curve along the leech (trailing edge)
let hl = NSBezierPath()
hl.move(to: NSPoint(x: size * 0.20, y: size * 0.36))
hl.curve(to: NSPoint(x: size * 0.46, y: size * 0.78),
         controlPoint1: NSPoint(x: size * 0.19, y: size * 0.58),
         controlPoint2: NSPoint(x: size * 0.32, y: size * 0.72))
hl.line(to: NSPoint(x: size * 0.48, y: size * 0.76))
hl.curve(to: NSPoint(x: size * 0.224, y: size * 0.34),
         controlPoint1: NSPoint(x: size * 0.34, y: size * 0.70),
         controlPoint2: NSPoint(x: size * 0.224, y: size * 0.56))
hl.close()
rgb((1.0, 1.0, 1.0), 0.35).setFill()
hl.fill()

// 7. Two wave lines
let wave = NSBezierPath()
wave.move(to: NSPoint(x: size * 0.12, y: size * 0.10))
wave.curve(to: NSPoint(x: size * 0.88, y: size * 0.10),
           controlPoint1: NSPoint(x: size * 0.40, y: size * 0.06),
           controlPoint2: NSPoint(x: size * 0.62, y: size * 0.14))
cg.saveGState()
rgb((1.0, 1.0, 1.0), 0.40).setStroke()
wave.lineWidth = 5
wave.lineCapStyle = .round
wave.stroke()
cg.restoreGState()

let wave2 = NSBezierPath()
wave2.move(to: NSPoint(x: size * 0.20, y: size * 0.06))
wave2.curve(to: NSPoint(x: size * 0.80, y: size * 0.06),
            controlPoint1: NSPoint(x: size * 0.45, y: size * 0.03),
            controlPoint2: NSPoint(x: size * 0.62, y: size * 0.09))
cg.saveGState()
rgb((1.0, 1.0, 1.0), 0.25).setStroke()
wave2.lineWidth = 3
wave2.lineCapStyle = .round
wave2.stroke()
cg.restoreGState()

// 8. Coral streak dot accent
let dot = NSBezierPath(ovalIn: NSRect(x: size * 0.84 - 9, y: size * 0.84 - 9, width: 18, height: 18))
rgb(streak).setFill()
dot.fill()

image.unlockFocus()

// 9. Save PNG via TIFF → bitmap → PNG path
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff) else {
    print("Couldn't get tiff")
    exit(1)
}

guard let png = bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
    print("PNG encoding failed")
    exit(1)
}

for path in [outPath, desktopPath] {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    do {
        try png.write(to: url)
        print("✓ \(path) (\(png.count / 1024) KB)")
    } catch {
        print("✗ \(path): \(error)")
    }
}

// 10. @2x preview (512×512)
let preview = NSImage(size: NSSize(width: 512, height: 512))
preview.lockFocus()
image.draw(in: NSRect(x: 0, y: 0, width: 512, height: 512),
           from: NSRect(x: 0, y: 0, width: size, height: size),
           operation: .sourceOver, fraction: 1.0)
preview.unlockFocus()

if let pTiff = preview.tiffRepresentation,
   let pBitmap = NSBitmapImageRep(data: pTiff),
   let pPNG = pBitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) {
    try? pPNG.write(to: URL(fileURLWithPath: previewPath))
    print("✓ preview: \(previewPath) (512×512)")
}

print("\n🎉 Tack icon rendered.")

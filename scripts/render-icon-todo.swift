#!/usr/bin/env swift
//
// render-icon-todo.swift
//
// Generates the Tack app icon in the Reminders / Things / Todoist aesthetic:
//   • Rounded white-paper background
//   • Three colored task stripes at top (blue, coral, gold) — lists in miniature
//   • A large accent-blue checkmark in the center
//   • Two thinner task lines (open / done) at the bottom
//
// Output:
//   ~/Desktop/Tack-icon.png        (1024 x 1024)
//   ~/Desktop/Tack-icon@2x.png     ( 512 x  512)
//   ~/tack-ios/Tack/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png  (1024)
//
// Run: swift ~/tack-ios/scripts/render-icon-todo.swift

import AppKit

let size = 1024

// ───────────────────────────────────────────────────────────
// MARK: palette (matches TK.Palette)
// ───────────────────────────────────────────────────────────
let bgTop      = NSColor(srgbRed: 0.984, green: 0.988, blue: 0.992, alpha: 1.0)
let bgBot      = NSColor(srgbRed: 0.965, green: 0.973, blue: 0.984, alpha: 1.0)
let accent     = NSColor(srgbRed: 0.357, green: 0.561, blue: 0.976, alpha: 1.0)
let accentDeep = NSColor(srgbRed: 0.255, green: 0.412, blue: 0.835, alpha: 1.0)
let coral      = NSColor(srgbRed: 0.984, green: 0.412, blue: 0.310, alpha: 1.0)
let gold       = NSColor(srgbRed: 0.961, green: 0.745, blue: 0.255, alpha: 1.0)
let ink        = NSColor(srgbRed: 0.10, green: 0.13, blue: 0.20, alpha: 1.0)
let inkSoft    = NSColor(srgbRed: 0.10, green: 0.13, blue: 0.20, alpha: 0.32)
let inkFaint   = NSColor(srgbRed: 0.10, green: 0.13, blue: 0.20, alpha: 0.18)
let inkGhost   = NSColor(srgbRed: 0.10, green: 0.13, blue: 0.20, alpha: 0.10)

// ───────────────────────────────────────────────────────────
// MARK: 1024×1024 canvas
// ───────────────────────────────────────────────────────────
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
let cg = NSGraphicsContext.current!.cgContext

// rounded square mask — every draw below is clipped to this shape
let iconPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
                            xRadius: CGFloat(size) * 0.2237, yRadius: CGFloat(size) * 0.2237)
cg.saveGState(); iconPath.addClip(); defer { cg.restoreGState() }

// ───────────────────────────────────────────────────────────
// MARK: background
// ───────────────────────────────────────────────────────────
let bg = NSGradient(colors: [bgTop, bgBot])!
bg.draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: -90)

// soft top-left blue glow
if let srgbSpace = NSColorSpace.sRGB.cgColorSpace,
   let glowCG = CGGradient(colorsSpace: srgbSpace,
                           colors: [accent.withAlphaComponent(0.18).cgColor,
                                    accent.withAlphaComponent(0.0).cgColor] as CFArray,
                           locations: [0, 1]) {
    cg.saveGState()
    cg.drawRadialGradient(
        glowCG,
        startCenter: CGPoint(x: CGFloat(size) * 0.18, y: CGFloat(size) * 0.85),
        startRadius: 0,
        endCenter:   CGPoint(x: CGFloat(size) * 0.18, y: CGFloat(size) * 0.85),
        endRadius:   CGFloat(size) * 0.55,
        options: CGGradientDrawingOptions.drawsBeforeStartLocation
    )
    cg.restoreGState()
}

// ───────────────────────────────────────────────────────────
// MARK: top accent stripes (3 colored task rows)
// ───────────────────────────────────────────────────────────
let stripes: [(color: NSColor, count: Int)] = [
    (accent, 1),  // top: blue
    (coral,  1),  // middle: coral
    (gold,   1)   // bottom: gold
]
let stripeX = CGFloat(size) * 0.16
let stripeW = CGFloat(size) * 0.68
let stripeH = CGFloat(size) * 0.075
let stripeGap = CGFloat(size) * 0.025
var stripeY = CGFloat(size) * 0.78

for s in stripes {
    // outer "track"
    let track = NSBezierPath(roundedRect:
        NSRect(x: stripeX, y: stripeY, width: stripeW, height: stripeH),
        xRadius: stripeH / 2, yRadius: stripeH / 2)
    s.color.withAlphaComponent(0.18).setFill()
    track.fill()

    // filled head (representing a task row of progress 25/50/75%)
    let headW = stripeW * [0.62, 0.42, 0.55][[accent, coral, gold].firstIndex(of: s.color)!] // static ratios
    let head  = NSBezierPath(roundedRect:
        NSRect(x: stripeX, y: stripeY, width: headW, height: stripeH),
        xRadius: stripeH / 2, yRadius: stripeH / 2)
    s.color.setFill()
    head.fill()

    stripeY -= stripeH + stripeGap
}

// ───────────────────────────────────────────────────────────
// MARK: checkmark — the hero
// ───────────────────────────────────────────────────────────
let checkSize = CGFloat(size) * 0.30
let checkX = (CGFloat(size) - checkSize) / 2
let checkY = CGFloat(size) * 0.26

// soft shadow disc behind
let shadowRect = NSRect(x: checkX - 12, y: checkY - 12, width: checkSize + 24, height: checkSize + 24)
let shadowPath = NSBezierPath(ovalIn: shadowRect)
NSColor(red: 0.357, green: 0.561, blue: 0.976, alpha: 0.20).setFill()
shadowPath.fill()

// accent disc
let discRect = NSRect(x: checkX, y: checkY, width: checkSize, height: checkSize)
let disc = NSBezierPath(ovalIn: discRect)
let discGrad = NSGradient(colors: [accent, accentDeep])!
discGrad.draw(in: discRect, angle: -90)

// white checkmark
let stroke: CGFloat = checkSize * 0.10
let cx = discRect.midX, cy = discRect.midY
let r = checkSize * 0.30
let p1 = NSPoint(x: cx - r,         y: cy - r * 0.10)
let p2 = NSPoint(x: cx - r * 0.30,  y: cy - r * 0.65)
let p3 = NSPoint(x: cx + r * 0.95,  y: cy + r * 0.50)
let check = NSBezierPath()
check.move(to: p1)
check.line(to: p2)
check.line(to: p3)
NSColor.white.setStroke()
check.lineWidth = stroke
check.lineCapStyle = .round
check.lineJoinStyle = .round
check.stroke()

// tiny inner-light gradient on disc for shine
let shineRect = NSRect(x: checkX + checkSize * 0.18,
                      y: checkY + checkSize * 0.55,
                      width: checkSize * 0.7,
                      height: checkSize * 0.18)
let shine = NSBezierPath(roundedRect: shineRect, xRadius: shineRect.height/2, yRadius: shineRect.height/2)
NSColor(white: 1.0, alpha: 0.18).setFill()
shine.fill()

// ───────────────────────────────────────────────────────────
// MARK: subtle "T" wordmark at very bottom
// ───────────────────────────────────────────────────────────
// small dot trio (the streak-stats signature) bottom-right
let dotR: CGFloat = CGFloat(size) * 0.020
let dotY = CGFloat(size) * 0.10
for (i, c) in [accent, coral, gold].enumerated() {
    let dx = CGFloat(size) * 0.43 + CGFloat(i) * dotR * 3
    let dot = NSBezierPath(ovalIn: NSRect(x: dx, y: dotY, width: dotR * 2, height: dotR * 2))
    c.setFill(); dot.fill()
}

img.unlockFocus()

// ───────────────────────────────────────────────────────────
// MARK: encode PNGs and write
// ───────────────────────────────────────────────────────────
guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png1024 = rep.representation(using: .png, properties: [.compressionFactor: 0.95]) else {
    FileHandle.standardError.write("Failed to encode PNG\n".data(using: .utf8)!)
    exit(1)
}

let targets: [(String, Data)] = [
    ("/Users/enriquevaleros/Desktop/Tack-icon.png", png1024),
    ("/Users/enriquevaleros/tack-ios/Tack/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png", png1024),
]
for (path, data) in targets {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                              withIntermediateDirectories: true)
    do { try data.write(to: url); print("✓ \(path)") }
    catch { print("✗ \(path): \(error)") }
}

// 512 × 512 preview
let half = NSImage(size: NSSize(width: 512, height: 512))
half.lockFocus()
NSGraphicsContext.current?.cgContext.interpolationQuality = .high
img.draw(in: NSRect(origin: .zero, size: half.size),
         from: .zero,
         operation: .copy,
         fraction: 1.0)
half.unlockFocus()
if let hTiff = half.tiffRepresentation,
   let hRep = NSBitmapImageRep(data: hTiff),
   let hPNG = hRep.representation(using: .png, properties: [.compressionFactor: 0.95]) {
    let dest = "/Users/enriquevaleros/Desktop/Tack-icon@2x.png"
    try? hPNG.write(to: URL(fileURLWithPath: dest))
    print("✓ \(dest) (512×512)")
}

print("\n🎉 Todo icon rendered.")

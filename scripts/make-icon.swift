#!/usr/bin/env swift
// Generate the iOS app icon — a white "T" centered on a green tile.
//
// Run by hand after changing the design, not by the build:
//
//     swift scripts/make-icon.swift
//
// It writes taskchamp/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png,
// which is committed.
//
// This is a deliberate twin of ~/taskwarrior_macos/Scripts/make-icon.swift so the
// iOS and macOS apps share one icon. The color and the letter geometry are copied
// from there; a change to the design belongs in both copies. The one difference
// is the tile: macOS icons draw their own rounded tile inside a transparent
// margin, but iOS wants an opaque, full-bleed square and applies its own mask.
// So here the tile *is* the canvas, and the mark, which is measured in tile
// units, lands at the same proportions it has on the Mac.

import AppKit

let size = 1024

// Mark geometry, in units of the tile. x from the left edge, y from the bottom.
let markLeft: CGFloat = 0.22
let markRight: CGFloat = 0.78
let markTop: CGFloat = 0.77
let markBottom: CGFloat = 0.23
let strokeWidth: CGFloat = 0.129

let tileColor = CGColor(srgbRed: 0x26 / 255.0, green: 0xA6 / 255.0, blue: 0x5D / 255.0, alpha: 1)
let markColor = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)

// noneSkipLast gives an opaque bitmap, so the PNG has no alpha channel. App icons
// with alpha are rejected by asset validation.
guard let ctx = CGContext(
    data: nil,
    width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("could not make a \(size)x\(size) context") }

let side = CGFloat(size)
ctx.setFillColor(tileColor)
ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))

func rect(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> CGRect {
    CGRect(x: x0 * side, y: y0 * side, width: (x1 - x0) * side, height: (y1 - y0) * side)
}

// Crossbar and stem overlap at the top rather than butting, so no seam shows.
let stemLeft = 0.5 - strokeWidth / 2
ctx.setFillColor(markColor)
ctx.addRect(rect(markLeft, markTop - strokeWidth, markRight, markTop))
ctx.addRect(rect(stemLeft, markBottom, stemLeft + strokeWidth, markTop))
ctx.fillPath(using: .winding)

guard let image = ctx.makeImage() else { fatalError("could not render the icon") }

let repoRoot = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent() // scripts/
    .deletingLastPathComponent() // repo root
let output = repoRoot.appendingPathComponent(
    "taskchamp/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
)

guard let dest = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("could not open \(output.path) for writing")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("could not write \(output.path)") }

print("✓ wrote \(output.path)")

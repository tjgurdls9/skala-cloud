// Reproducible builder for skala-container-implementation-review.pdf.
// Run from the worktree:
//   swiftc -module-cache-path /tmp/skala-swift-module-cache output/pdf/build_report.swift -o /tmp/skala-build-report
//   /tmp/skala-build-report
//
// The builder reads output/pdf/report-source.md and uses Apple Core Text
// with AppleSDGothicNeo-Regular for Korean glyphs.
import Foundation
import CoreGraphics
import CoreText

let pageW: CGFloat = 595
let pageH: CGFloat = 842
let root = FileManager.default.currentDirectoryPath
let sourcePath = root + "/output/pdf/report-source.md"
let outputPath = root + "/output/pdf/skala-container-implementation-review.pdf"

func color(_ hex: UInt32) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let navy = color(0x102A43)
let blue = color(0x1976D2)
let teal = color(0x0F766E)
let orange = color(0xD97706)
let ink = color(0x243B53)
let muted = color(0x627D98)
let border = color(0xD9E2EC)
let paleBlue = color(0xEAF3FF)
let paleTeal = color(0xE7F7F4)
let paleOrange = color(0xFFF4E5)
let paleGrey = color(0xF5F7FA)

func font(_ name: String, _ size: CGFloat) -> CTFont {
    CTFontCreateWithName(name as CFString, size, nil)
}

func attributed(_ text: String, size: CGFloat, fontName: String = "AppleSDGothicNeo-Regular", foreground: CGColor = ink, alignment: CTTextAlignment = .left) -> NSAttributedString {
    var align = alignment
    var spacing: CGFloat = 3
    return withUnsafePointer(to: &align) { alignPtr in
        withUnsafePointer(to: &spacing) { spacingPtr in
            let settings = [
                CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout<CTTextAlignment>.size, value: alignPtr),
                CTParagraphStyleSetting(spec: .lineSpacingAdjustment, valueSize: MemoryLayout<CGFloat>.size, value: spacingPtr)
            ]
            let para = CTParagraphStyleCreate(settings, settings.count)
            return NSAttributedString(string: text, attributes: [
                kCTFontAttributeName as NSAttributedString.Key: font(fontName, size),
                kCTForegroundColorAttributeName as NSAttributedString.Key: foreground,
                kCTParagraphStyleAttributeName as NSAttributedString.Key: para
            ])
        }
    }
}

func measure(_ text: String, width: CGFloat, size: CGFloat, fontName: String = "AppleSDGothicNeo-Regular") -> CGFloat {
    let fs = CTFramesetterCreateWithAttributedString(attributed(text, size: size, fontName: fontName))
    var fit = CFRange()
    let result = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: text.utf16.count), nil, CGSize(width: width, height: 10000), &fit)
    return max(ceil(result.height), size + 4)
}

func drawText(_ ctx: CGContext, _ text: String, x: CGFloat, top: CGFloat, width: CGFloat, size: CGFloat, fontName: String = "AppleSDGothicNeo-Regular", foreground: CGColor = ink, alignment: CTTextAlignment = .left, height: CGFloat? = nil) -> CGFloat {
    let h = height ?? measure(text, width: width, size: size, fontName: fontName)
    let fs = CTFramesetterCreateWithAttributedString(attributed(text, size: size, fontName: fontName, foreground: foreground, alignment: alignment))
    let path = CGPath(rect: CGRect(x: x, y: pageH - top - h, width: width, height: h), transform: nil)
    CTFrameDraw(CTFramesetterCreateFrame(fs, CFRange(location: 0, length: text.utf16.count), path, nil), ctx)
    return h
}

func box(_ ctx: CGContext, x: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat, fill: CGColor? = nil, stroke: CGColor? = nil) {
    let r = CGRect(x: x, y: pageH - top - height, width: width, height: height)
    if let fill { ctx.setFillColor(fill); ctx.fill(r) }
    if let stroke { ctx.setStrokeColor(stroke); ctx.setLineWidth(0.7); ctx.stroke(r) }
}

func line(_ ctx: CGContext, x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, stroke: CGColor = border) {
    ctx.setStrokeColor(stroke); ctx.setLineWidth(0.6)
    ctx.move(to: CGPoint(x: x1, y: pageH - y1)); ctx.addLine(to: CGPoint(x: x2, y: pageH - y2)); ctx.strokePath()
}

func drawTable(_ ctx: CGContext, _ rows: [[String]], top: CGFloat) -> CGFloat {
    guard !rows.isEmpty else { return 0 }
    let width: CGFloat = 493
    let count = rows[0].count
    let widths: [CGFloat] = count == 3 ? [width * 0.20, width * 0.55, width * 0.25] : Array(repeating: width / CGFloat(count), count: count)
    var heights: [CGFloat] = []
    for (i, row) in rows.enumerated() {
        var height: CGFloat = i == 0 ? 25 : 25
        for (j, value) in row.enumerated() {
            height = max(height, measure(value, width: widths[j] - 12, size: i == 0 ? 7.8 : 7.2) + 10)
        }
        heights.append(height)
    }
    var y = top
    for (i, row) in rows.enumerated() {
        let h = heights[i]
        box(ctx, x: 51, top: y, width: width, height: h, fill: i == 0 ? navy : (i % 2 == 1 ? paleGrey : CGColor(gray: 1, alpha: 1)))
        var x: CGFloat = 51
        for (j, value) in row.enumerated() {
            drawText(ctx, value, x: x + 6, top: y + 5, width: widths[j] - 12, size: i == 0 ? 7.8 : 7.2, foreground: i == 0 ? CGColor(gray: 1, alpha: 1) : ink, height: h - 8)
            if j < count - 1 { line(ctx, x1: x + widths[j], y1: y, x2: x + widths[j], y2: y + h) }
            x += widths[j]
        }
        line(ctx, x1: 51, y1: y + h, x2: 544, y2: y + h)
        y += h
    }
    box(ctx, x: 51, top: top, width: width, height: y - top, stroke: border)
    return y - top
}

func header(_ ctx: CGContext, page: Int) {
    box(ctx, x: 0, top: 0, width: pageW, height: 37, fill: navy)
    drawText(ctx, "SKALA | 컨테이너 실습 구현 검토 보고서", x: 51, top: 14, width: 350, size: 7.5, foreground: CGColor(gray: 1, alpha: 1), height: 12)
    line(ctx, x1: 51, y1: 815, x2: 544, y2: 815)
    drawText(ctx, "2026.08.26  ·  " + String(page), x: 390, top: 820, width: 154, size: 7, foreground: muted, alignment: .right, height: 11)
}

func begin(_ ctx: CGContext) {
    ctx.beginPDFPage([kCGPDFContextMediaBox: CGRect(x: 0, y: 0, width: pageW, height: pageH)] as CFDictionary)
}

guard let source = try? String(contentsOfFile: sourcePath, encoding: .utf8) else { fatalError("missing report-source.md") }
let pages = source.components(separatedBy: "\n---\n")
guard let consumer = CGDataConsumer(url: URL(fileURLWithPath: outputPath) as CFURL) else { fatalError("cannot create PDF consumer") }
var media = CGRect(x: 0, y: 0, width: pageW, height: pageH)
guard let ctx = CGContext(consumer: consumer, mediaBox: &media, nil) else { fatalError("cannot create PDF context") }

for (pageIndex, rawPage) in pages.enumerated() {
    begin(ctx)
    if pageIndex == 0 {
        box(ctx, x: 0, top: 0, width: pageW, height: pageH, fill: navy)
        box(ctx, x: 51, top: 90, width: 493, height: 3, fill: blue)
        drawText(ctx, "IMPLEMENTATION REVIEW  /  2026.08", x: 51, top: 118, width: 400, size: 10, foreground: color(0x7DD3FC), height: 18)
        drawText(ctx, "SKALA 컨테이너 실습\n구현 검토 및 추진안", x: 51, top: 166, width: 490, size: 27, foreground: CGColor(gray: 1, alpha: 1), height: 90)
        drawText(ctx, "집중실습 1-9, 3-tier Compose, 이미지 경량화,\nKubernetes 보강 자료를 기준으로 한 실행 순서와 검증안", x: 51, top: 280, width: 480, size: 11.5, foreground: color(0xD9F0FF), height: 51)
        drawText(ctx, "검토 대상", x: 51, top: 488, width: 150, size: 8, foreground: muted, height: 15)
        drawText(ctx, "01.focused-labs · 02.kubernetes · k8s_yaml1 · shop-api", x: 51, top: 508, width: 490, size: 10, foreground: color(0xD9F0FF), height: 20)
        drawText(ctx, "문서 성격", x: 51, top: 557, width: 150, size: 8, foreground: muted, height: 15)
        drawText(ctx, "권고 보고서 / 실행 전 PM 검토용", x: 51, top: 577, width: 490, size: 10, foreground: color(0xD9F0FF), height: 20)
        box(ctx, x: 51, top: 690, width: 493, height: 1, fill: color(0x2C587A))
        drawText(ctx, "한 줄 결론", x: 51, top: 721, width: 100, size: 9, foreground: color(0x7DD3FC), height: 15)
        let conclusion = rawPage.components(separatedBy: "한 줄 결론:").dropFirst().joined(separator: "한 줄 결론:").trimmingCharacters(in: .whitespacesAndNewlines)
        drawText(ctx, conclusion, x: 51, top: 748, width: 493, size: 10, foreground: CGColor(gray: 1, alpha: 1), height: 55)
    } else {
        header(ctx, page: pageIndex + 1)
        let lines = rawPage.components(separatedBy: .newlines)
        var y: CGFloat = 62
        var i = 0
        while i < lines.count {
            let value = lines[i]
            if value.hasPrefix("# ") {
                drawText(ctx, String(value.dropFirst(2)), x: 51, top: y, width: 493, size: 19, foreground: navy, height: 25); y += 35
            } else if value.hasPrefix("## ") {
                drawText(ctx, String(value.dropFirst(3)), x: 51, top: y, width: 493, size: 12.5, foreground: teal, height: 19); y += 28
            } else if value.hasPrefix("| ") {
                var rows: [[String]] = []
                while i < lines.count && lines[i].hasPrefix("| ") {
                    let cells = lines[i].split(separator: "|", omittingEmptySubsequences: true).map { $0.trimmingCharacters(in: .whitespaces) }
                    if !cells.allSatisfy({ $0.allSatisfy({ $0 == "-" || $0 == " " }) }) { rows.append(cells) }
                    i += 1
                }
                y += drawTable(ctx, rows, top: y) + 16; continue
            } else if value.hasPrefix("- ") {
                y += drawText(ctx, "•  " + String(value.dropFirst(2)), x: 51, top: y, width: 493, size: 8.9) + 5
            } else if value.hasPrefix("> ") {
                let text = String(value.dropFirst(2))
                let h = measure(text, width: 473, size: 9.5) + 16
                box(ctx, x: 51, top: y, width: 493, height: h, fill: paleTeal, stroke: teal)
                drawText(ctx, text, x: 61, top: y + 8, width: 473, size: 9.5, foreground: navy, height: h - 16); y += h + 14
            } else if !value.trimmingCharacters(in: .whitespaces).isEmpty {
                y += drawText(ctx, value, x: 51, top: y, width: 493, size: 9.0) + 8
            } else {
                y += 5
            }
            i += 1
        }
    }
    ctx.endPDFPage()
}
ctx.closePDF()
print(outputPath)


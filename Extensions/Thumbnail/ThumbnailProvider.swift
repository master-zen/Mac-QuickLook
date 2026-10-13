import AppKit
import Foundation
import QuickLookThumbnailing

final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        do {
            let summary = try FileSummary.read(request.fileURL)
            let size = request.maximumSize
            let reply = QLThumbnailReply(contextSize: size, currentContextDrawing: {
                NSColor(calibratedRed: 0.09, green: 0.14, blue: 0.22, alpha: 1).setFill()
                NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 12, yRadius: 12).fill()
                let titleSize = max(10, min(21, size.width / 8))
                let primary: [NSAttributedString.Key: Any] = [
                    .foregroundColor: NSColor.white,
                    .font: NSFont.systemFont(ofSize: titleSize, weight: .semibold)
                ]
                let secondary: [NSAttributedString.Key: Any] = [
                    .foregroundColor: NSColor(calibratedWhite: 0.80, alpha: 1),
                    .font: NSFont.systemFont(ofSize: max(8, titleSize * 0.58))
                ]
                let title = summary.kind.rawValue
                (title as NSString).draw(in: NSRect(x: 10, y: size.height * 0.52, width: max(1, size.width - 20), height: titleSize * 2.0), withAttributes: primary)
                let label = summary.details.last ?? summary.kind.fileExtension.uppercased()
                (label as NSString).draw(in: NSRect(x: 10, y: size.height * 0.25, width: max(1, size.width - 20), height: titleSize * 1.5), withAttributes: secondary)
                let colors = summary.swatches.compactMap { swatch -> NSColor? in
                    guard let hex = swatch.hex, hex.count == 7, let colorNumber = Int(hex.dropFirst(), radix: 16) else { return nil }
                    return NSColor(calibratedRed: CGFloat((colorNumber >> 16) & 0xFF) / 255,
                                   green: CGFloat((colorNumber >> 8) & 0xFF) / 255,
                                   blue: CGFloat(colorNumber & 0xFF) / 255, alpha: 1)
                }
                if !colors.isEmpty {
                    let width = max(1, (size.width - 20) / CGFloat(colors.count))
                    for (index, color) in colors.enumerated() {
                        color.setFill()
                        NSRect(x: 10 + CGFloat(index) * width, y: 10, width: width, height: max(4, size.height * 0.13)).fill()
                    }
                }
                if summary.track.count > 1 {
                    let points = TrackGeometry.normalized(summary.track)
                    let route = NSBezierPath()
                    route.lineWidth = max(1, size.width / 65)
                    route.lineCapStyle = .round
                    route.lineJoinStyle = .round
                    for (index, point) in points.enumerated() {
                        let target = NSPoint(x: point.x * size.width, y: (1 - point.y) * size.height * 0.45 + size.height * 0.08)
                        if index == 0 || point.breakBefore { route.move(to: target) } else { route.line(to: target) }
                    }
                    NSColor(calibratedRed: 0.22, green: 0.86, blue: 0.68, alpha: 1).setStroke()
                    route.stroke()
                }
                return true
            })
            handler(reply, nil)
        } catch {
            handler(nil, error)
        }
    }
}

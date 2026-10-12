import AppKit
import Foundation
import QuickLookThumbnailing

final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        do {
            let summary = try FileSummary.inspect(request.fileURL)
            let size = request.maximumSize
            let reply = QLThumbnailReply(contextSize: size, currentContextDrawing: {
                NSColor(calibratedRed: 0.10, green: 0.17, blue: 0.27, alpha: 1).setFill()
                NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 12, yRadius: 12).fill()
                let font = NSFont.boldSystemFont(ofSize: max(11, min(26, size.width / 5)))
                let options: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
                (summary.kind.rawValue.uppercased() as NSString).draw(
                    in: NSRect(x: 10, y: 10, width: max(1, size.width - 20), height: max(25, size.height - 20)),
                    withAttributes: options
                )
                return true
            })
            handler(reply, nil)
        } catch {
            handler(nil, error)
        }
    }
}

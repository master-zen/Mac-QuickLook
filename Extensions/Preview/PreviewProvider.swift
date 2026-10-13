import Foundation
import QuickLookUI
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest, completionHandler handler: @escaping (QLPreviewReply?, Error?) -> Void) {
        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 840, height: 640)) { _ in
            let summary = try FileSummary.read(request.fileURL)
            return PreviewHTML.render(summary)
        }
        reply.title = request.fileURL.lastPathComponent
        handler(reply, nil)
    }
}

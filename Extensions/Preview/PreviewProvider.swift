import Foundation
import QuickLookUI
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest, completionHandler handler: @escaping (QLPreviewReply?, Error?) -> Void) {
        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 840, height: 630)) { _ in
            try FileSummary.inspect(request.fileURL).html()
        }
        reply.title = request.fileURL.lastPathComponent
        handler(reply, nil)
    }
}

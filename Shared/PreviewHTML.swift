import Foundation

enum PreviewHTML {
    static func escape(_ input: String) -> String {
        input.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    static func render(_ summary: FileSummary) -> Data {
        let details = summary.details.map { "<li>\(escape($0))</li>" }.joined()
        var visual = ""
        if summary.track.count > 1 {
            let points = TrackGeometry.normalized(summary.track)
            let path = points.enumerated().map { index, point in
                let x = String(format: "%.2f", point.x * 800)
                let y = String(format: "%.2f", point.y * 400)
                return "\(index == 0 || point.breakBefore ? "M" : "L")\(x),\(y)"
            }.joined(separator: " ")
            visual = "<figure class=track><svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 800 400\" role=\"img\" aria-label=\"GPS track outline\"><path d=\"\(path)\" fill=\"none\" stroke=\"#21a38e\" stroke-width=\"4\" stroke-linejoin=\"round\" stroke-linecap=\"round\"/></svg><figcaption>Offline route outline · no base map or network access</figcaption></figure>"
        }
        if !summary.swatches.isEmpty {
            let blocks = summary.swatches.map { swatch in
                let paint = swatch.hex.map { "style=\"background:\($0)\"" } ?? ""
                return "<article><div class=swatch \(paint)></div><span>\(escape(swatch.name))</span><small>\(escape(swatch.model))</small></article>"
            }.joined()
            visual += "<section class=grid>\(blocks)</section>"
        }
        let content = visual + (summary.text.isEmpty ? "" : "<pre>\(escape(summary.text))</pre>")
        let document = """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width,initial-scale=1">
          <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'">
          <style>
            :root{color-scheme:light dark;font-family:-apple-system,BlinkMacSystemFont,sans-serif}
            body{margin:0;padding:28px;line-height:1.5;color:#1e232c;background:#fff}
            h1{font-size:21px;font-weight:650;overflow-wrap:anywhere;margin:0 0 4px}
            .tag{color:#607083;font-size:13px}
            ul{padding-left:19px;color:#536073;font-size:13px;line-height:1.75}
            pre{font:12px/1.6 ui-monospace,SFMono-Regular,Menlo,monospace;white-space:pre-wrap;overflow-wrap:anywhere;background:#f4f5f7;padding:18px;border-radius:10px}
            .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(105px,1fr));gap:12px;margin:14px 0}
            .track{margin:18px 0 12px;background:#f4f6f8;border:1px solid #dce1e6;border-radius:12px;padding:12px}
            .track svg{display:block;width:100%;max-height:320px}
            .track figcaption{font-size:11px;color:#667489;margin-top:8px}
            article{border:1px solid #ddd;border-radius:10px;overflow:hidden;padding-bottom:10px;display:flex;flex-direction:column}
            .swatch{height:76px;background:repeating-linear-gradient(45deg,#ddd,#ddd 8px,#eee 8px,#eee 16px);margin-bottom:7px}
            article span,article small{padding:0 9px;overflow-wrap:anywhere}
            article span{font-size:12px}article small{color:#667;font-size:10px}
            @media(prefers-color-scheme:dark){body{background:#1d1e22;color:#efeff2}.tag,ul{color:#b4bbca}pre{background:#292b30}article{border-color:#45464c}.track{background:#292b30;border-color:#45464c}}
          </style>
        </head>
        <body><h1>\(escape(summary.fileName))</h1><div class="tag">\(escape(summary.kind.rawValue))</div><ul>\(details)</ul>\(content)</body>
        </html>
        """
        return Data(document.utf8)
    }
}

import Foundation
import PDFKit

// Usage: pdftext3 <outdir> <pdf>...
// Rebuilds each page in reading order from text positions: fragments are grouped into visual
// lines by their vertical position, then ordered left to right.
struct Frag { let x0: CGFloat; let x1: CGFloat; let top: CGFloat; let h: CGFloat; let s: String }

let args = CommandLine.arguments
let outDir = URL(fileURLWithPath: args[1])
for path in args.dropFirst(2) {
    let url = URL(fileURLWithPath: path)
    guard let doc = PDFDocument(url: url) else { print("UNREADABLE \(path)"); continue }
    var text = ""
    for p in 0..<doc.pageCount {
        let page = doc.page(at: p)!
        let box = page.bounds(for: .mediaBox)
        var frags: [Frag] = []
        for line in page.selection(for: box)?.selectionsByLine() ?? [] {
            let r = line.bounds(for: page)
            let s = (line.string ?? "").replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
            if s.isEmpty || r.height > 20 { continue }  // skip the tall vote widget
            // Skip the browser's print header/footer, which can share a line with real content.
            if s.contains("fuck-tcf") || s.hasPrefix("https://") || s.range(of: #"^\d+/\d+/\d+, \d+:\d+"#, options: .regularExpression) != nil { continue }
            frags.append(Frag(x0: r.minX, x1: r.maxX, top: box.height - r.maxY, h: r.height, s: s))
        }
        frags.sort { $0.top < $1.top }
        var lines: [[Frag]] = []
        for f in frags {
            if let last = lines.last?.first, abs(last.top - f.top) <= 3 {
                lines[lines.count - 1].append(f)
            } else {
                lines.append([f])
            }
        }
        text += "\n===== PAGE \(p + 1) =====\n"
        for var line in lines {
            line.sort { $0.x0 < $1.x0 }
            var out = line[0].s
            for (prev, cur) in zip(line, line.dropFirst()) {
                out += (cur.x0 - prev.x1 > 1.5 ? " " : "") + cur.s
            }
            text += out + "\n"
        }
    }
    try text.write(to: outDir.appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".txt"), atomically: true, encoding: .utf8)
}

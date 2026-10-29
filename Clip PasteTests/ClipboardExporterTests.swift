import AppKit
import ImageIO
import Testing
@testable import Clip_Paste

@MainActor
struct ClipboardExporterTests {
    private func image(alpha: CGFloat = 0.5) throws -> NSImage {
        let context = try #require(CGContext(
            data: nil, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: alpha))
        context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
        let cgImage = try #require(context.makeImage())
        return NSImage(cgImage: cgImage, size: NSSize(width: 64, height: 64))
    }

    private func firstPixel(in data: Data) throws -> [UInt8] {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let context = try #require(CGContext(
            data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let bytes = try #require(context.data).assumingMemoryBound(to: UInt8.self)
        return Array(UnsafeBufferPointer(start: bytes, count: 4))
    }

    @Test(arguments: ImageFileFormat.allCases)
    func imageFormatsProduceDecodableFiles(format: ImageFileFormat) throws {
        let data = try ClipboardExporter.imageData(from: image(), format: format, quality: 0.9)
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        #expect(CGImageSourceGetType(source) as String? == format.typeIdentifier)
        let decoded = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(decoded.width == 64)
        #expect(decoded.height == 64)
    }

    @Test func pngKeepsTransparency() throws {
        let data = try ClipboardExporter.imageData(from: image(), format: .png, quality: 0.9)
        let pixel = try firstPixel(in: data)
        #expect(abs(Int(pixel[3]) - 128) < 3)
    }

    @Test func jpegCompositesTransparencyOntoWhite() throws {
        let data = try ClipboardExporter.imageData(from: image(alpha: 0), format: .jpeg, quality: 1)
        let pixel = try firstPixel(in: data)
        #expect(pixel[0] > 242)
        #expect(pixel[1] > 242)
        #expect(pixel[2] > 242)
    }

    @Test func plainTextIsUTF8() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        pasteboard.setString("Hello, café 👋\nSecond line", forType: .string)
        let result = try #require(try ClipboardExporter.text(from: pasteboard, format: .plainText))
        #expect(String(data: result.data, encoding: .utf8) == "Hello, café 👋\nSecond line")
        #expect(result.plainText == "Hello, café 👋\nSecond line")
    }

    @Test func rtfPreservesFormattingAndLinks() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        let original = NSAttributedString(string: "Formatted text", attributes: [
            .font: NSFont.boldSystemFont(ofSize: 18),
            .link: URL(string: "https://example.com")!
        ])
        let rtf = try original.data(
            from: NSRange(location: 0, length: original.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        pasteboard.setData(rtf, forType: .rtf)
        let result = try #require(try ClipboardExporter.text(from: pasteboard, format: .rtf))
        let decoded = try #require(NSAttributedString(rtf: result.data, documentAttributes: nil))
        #expect(decoded.string == original.string)
        let font = try #require(decoded.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)
        #expect(font.fontDescriptor.symbolicTraits.contains(.bold))
        #expect(decoded.attribute(.link, at: 0, effectiveRange: nil) != nil)
        #expect(result.plainText == original.string)
    }

    @Test func htmlIsPreservedWithoutRendering() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        let html = "<html><body><b>Hello</b><img src=\"https://example.invalid/image.png\"></body></html>"
        pasteboard.setString(html, forType: .html)
        let result = try #require(try ClipboardExporter.text(from: pasteboard, format: .html))
        #expect(String(data: result.data, encoding: .utf8) == html)
    }

    @Test func plainTextCanBeSavedAsRTF() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        pasteboard.setString("Plain {text} \\ café", forType: .string)
        let result = try #require(try ClipboardExporter.text(from: pasteboard, format: .rtf))
        let decoded = try #require(NSAttributedString(rtf: result.data, documentAttributes: nil))
        #expect(decoded.string == "Plain {text} \\ café")
    }

    @Test func plainTextHTMLIsEscaped() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        pasteboard.setString("<script>alert('hello')</script> & text", forType: .string)
        let result = try #require(try ClipboardExporter.text(from: pasteboard, format: .html))
        let html = try #require(String(data: result.data, encoding: .utf8))
        #expect(!html.contains("<script>"))
        #expect(html.contains("&lt;script&gt;"))
        #expect(html.contains("&amp;"))
    }

    @Test func emptyPasteboardHasNoTextExport() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        #expect(try ClipboardExporter.text(from: pasteboard, format: .plainText) == nil)
        #expect(try ClipboardExporter.text(from: pasteboard, format: .rtf) == nil)
        #expect(try ClipboardExporter.text(from: pasteboard, format: .html) == nil)
    }
}

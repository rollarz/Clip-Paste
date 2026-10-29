import AppKit
import ImageIO

struct TextExport {
    let data: Data
    let plainText: String
}

enum ClipboardExportError: LocalizedError {
    case imageConversionFailed
    case imageFormatUnavailable(ImageFileFormat)

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "The clipboard image could not be converted."
        case .imageFormatUnavailable(let format):
            return "This Mac could not encode the image as \(format.displayName). Try another image format in Settings."
        }
    }
}

@MainActor
enum ClipboardExporter {
    static func imageData(from image: NSImage, format: ImageFileFormat, quality: Double) throws -> Data {
        guard var cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ClipboardExportError.imageConversionFailed
        }

        // JPEG cannot store transparency; composite onto white deliberately.
        if format == .jpeg {
            guard let context = CGContext(
                data: nil, width: cgImage.width, height: cgImage.height,
                bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else { throw ClipboardExportError.imageConversionFailed }
            let rect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
            context.setFillColor(CGColor(gray: 1, alpha: 1))
            context.fill(rect)
            context.draw(cgImage, in: rect)
            guard let flattened = context.makeImage() else { throw ClipboardExportError.imageConversionFailed }
            cgImage = flattened
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, format.typeIdentifier as CFString, 1, nil) else {
            throw ClipboardExportError.imageFormatUnavailable(format)
        }
        let properties: CFDictionary? = format.isLossy
            ? [kCGImageDestinationLossyCompressionQuality: min(1, max(0, quality))] as CFDictionary
            : nil
        CGImageDestinationAddImage(destination, cgImage, properties)
        guard CGImageDestinationFinalize(destination) else {
            throw ClipboardExportError.imageFormatUnavailable(format)
        }
        return data as Data
    }

    static func text(from pasteboard: NSPasteboard, format: TextFileFormat) throws -> TextExport? {
        let richText: NSAttributedString?
        if let rtf = pasteboard.data(forType: .rtf), let attributed = NSAttributedString(rtf: rtf, documentAttributes: nil) {
            richText = attributed
        } else if let rtfd = pasteboard.data(forType: .rtfd) {
            richText = NSAttributedString(rtfd: rtfd, documentAttributes: nil)
        } else {
            richText = nil
        }
        let plainText = pasteboard.string(forType: .string) ?? richText?.string

        // Preserve supplied HTML without rendering it or fetching remote images/styles.
        if format == .html, let html = pasteboard.string(forType: .html) {
            return TextExport(data: Data(html.utf8), plainText: plainText ?? "")
        }
        guard let plainText else { return nil }
        if format == .plainText {
            return TextExport(data: Data(plainText.utf8), plainText: plainText)
        }

        let attributed = richText ?? NSAttributedString(string: plainText)
        let documentType: NSAttributedString.DocumentType = format == .rtf ? .rtf : .html
        let data = try attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: documentType]
        )
        return TextExport(data: data, plainText: plainText)
    }
}

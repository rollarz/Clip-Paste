import Foundation
import UniformTypeIdentifiers

enum ImageFileFormat: String, CaseIterable, Identifiable {
    case png, jpeg, tiff, heic

    var id: String { rawValue }
    var displayName: String { rawValue.uppercased() }
    var pathExtension: String { self == .jpeg ? "jpg" : rawValue }
    var isLossy: Bool { self == .jpeg || self == .heic }

    var typeIdentifier: String {
        switch self {
        case .png: return UTType.png.identifier
        case .jpeg: return UTType.jpeg.identifier
        case .tiff: return UTType.tiff.identifier
        case .heic: return UTType.heic.identifier
        }
    }
}

enum TextFileFormat: String, CaseIterable, Identifiable {
    case plainText, rtf, html

    var id: String { rawValue }
    var pathExtension: String { self == .plainText ? "txt" : rawValue }

    var displayName: String {
        switch self {
        case .plainText: return "Plain text (.txt)"
        case .rtf: return "Rich text (.rtf)"
        case .html: return "HTML (.html)"
        }
    }
}

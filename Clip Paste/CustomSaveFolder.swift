import Foundation

enum CustomSaveFolder {
    enum FolderError: LocalizedError {
        case notSelected

        var errorDescription: String? {
            "Choose a custom save folder in Settings before saving outside Finder."
        }
    }

    static func bookmark(for url: URL) throws -> Data {
        try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    static func resolve(_ data: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI],
            relativeTo: nil, bookmarkDataIsStale: &isStale
        )
        return (url, isStale)
    }

    static func selectedURL() throws -> URL {
        guard let data = Preferences.customSaveFolderBookmark else { throw FolderError.notSelected }
        let resolved = try resolve(data)
        if resolved.isStale {
            let accessed = resolved.url.startAccessingSecurityScopedResource()
            defer { if accessed { resolved.url.stopAccessingSecurityScopedResource() } }
            Preferences.customSaveFolderBookmark = try bookmark(for: resolved.url)
        }
        return resolved.url
    }
}

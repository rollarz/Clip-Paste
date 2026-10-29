import Foundation
import Testing
@testable import Clip_Paste

struct CustomSaveFolderTests {
    @Test func bookmarkRemembersCustomFolder() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let data = try CustomSaveFolder.bookmark(for: directory)
        let resolved = try CustomSaveFolder.resolve(data)
        #expect(resolved.url.resolvingSymlinksInPath() == directory.resolvingSymlinksInPath())
    }

    @Test func invalidBookmarkFails() {
        #expect(throws: (any Error).self) {
            try CustomSaveFolder.resolve(Data("invalid bookmark".utf8))
        }
    }
}

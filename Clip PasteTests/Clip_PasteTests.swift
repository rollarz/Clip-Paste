import Foundation
import Testing
@testable import Clip_Paste

struct Clip_PasteTests {
    private func withTemporaryDirectory(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory)
    }

    @Test(arguments: ["txt", "png"])
    func preservesExistingFiles(pathExtension: String) throws {
        try withTemporaryDirectory { directory in
            let original = directory.appendingPathComponent("Clipboard").appendingPathExtension(pathExtension)
            let originalData = Data("original".utf8)
            try originalData.write(to: original)

            let saved = try ClipboardFileWriter.write(
                Data("new".utf8), to: directory, baseName: "Clipboard", pathExtension: pathExtension
            )

            #expect(saved.lastPathComponent == "Clipboard (2).\(pathExtension)")
            #expect(try Data(contentsOf: original) == originalData)
            #expect(try Data(contentsOf: saved) == Data("new".utf8))
            #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).count == 2)
        }
    }

    @Test func skipsOccupiedSuffixesAndDirectories() throws {
        try withTemporaryDirectory { directory in
            let occupiedDirectory = directory.appendingPathComponent("Note.txt")
            try FileManager.default.createDirectory(at: occupiedDirectory, withIntermediateDirectories: false)
            let occupiedFile = directory.appendingPathComponent("Note (2).txt")
            try Data("keep".utf8).write(to: occupiedFile)

            let saved = try ClipboardFileWriter.write(
                Data("new".utf8), to: directory, baseName: "Note", pathExtension: "txt"
            )

            #expect(saved.lastPathComponent == "Note (3).txt")
            #expect(try occupiedDirectory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true)
            #expect(try Data(contentsOf: occupiedFile) == Data("keep".utf8))
            #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).count == 3)
        }
    }

    @Test func preservesDanglingSymbolicLinks() throws {
        try withTemporaryDirectory { directory in
            let link = directory.appendingPathComponent("Note.txt")
            let target = directory.appendingPathComponent("missing.txt")
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)

            let saved = try ClipboardFileWriter.write(
                Data("new".utf8), to: directory, baseName: "Note", pathExtension: "txt"
            )

            #expect(saved.lastPathComponent == "Note (2).txt")
            #expect(try FileManager.default.destinationOfSymbolicLink(atPath: link.path) == target.path)
            #expect(!FileManager.default.fileExists(atPath: target.path))
        }
    }

    @Test func preservesPastesWithTheSameTimestamp() throws {
        try withTemporaryDirectory { directory in
            let date = Date(timeIntervalSince1970: 1_700_000_000)
            let firstContext = FilenameTemplateContext(date: date, clipboardText: "first", clipboardName: nil, counter: 1)
            let secondContext = FilenameTemplateContext(date: date, clipboardText: "second", clipboardName: nil, counter: 2)
            let template = "Note {date} at {time}"
            let firstName = FilenameTemplate.expand(template: template, context: firstContext)
            let secondName = FilenameTemplate.expand(template: template, context: secondContext)
            #expect(firstName == secondName)

            let first = try ClipboardFileWriter.write(
                Data("first".utf8), to: directory, baseName: firstName, pathExtension: "txt"
            )
            let second = try ClipboardFileWriter.write(
                Data("second".utf8), to: directory, baseName: secondName, pathExtension: "txt"
            )

            #expect(first != second)
            #expect(try Data(contentsOf: first) == Data("first".utf8))
            #expect(try Data(contentsOf: second) == Data("second".utf8))
        }
    }

    @Test func concurrentWritesKeepEveryPayload() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }

        let count = 24
        let urls = try await withThrowingTaskGroup(of: URL.self) { group in
            for index in 0..<count {
                group.addTask {
                    try ClipboardFileWriter.write(
                        Data("payload \(index)".utf8), to: directory, baseName: "Note", pathExtension: "txt"
                    )
                }
            }
            var results: [URL] = []
            for try await url in group {
                results.append(url)
            }
            return results
        }

        #expect(Set(urls).count == count)
        let contents = try Set(urls.map { try String(contentsOf: $0, encoding: .utf8) })
        #expect(contents == Set((0..<count).map { "payload \($0)" }))
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).count == count)
    }

    @Test func failedPublishRemovesTemporaryFile() throws {
        try withTemporaryDirectory { directory in
            let original = directory.appendingPathComponent("keep.txt")
            try Data("keep".utf8).write(to: original)

            #expect(throws: (any Error).self) {
                try ClipboardFileWriter.write(
                    Data("new".utf8), to: directory,
                    baseName: String(repeating: "a", count: 300), pathExtension: "txt"
                )
            }

            #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path) == ["keep.txt"])
            #expect(try Data(contentsOf: original) == Data("keep".utf8))
        }
    }

    @Test func missingDirectoryFails() throws {
        try withTemporaryDirectory { directory in
            #expect(throws: (any Error).self) {
                try ClipboardFileWriter.write(
                    Data("new".utf8), to: directory.appendingPathComponent("missing"),
                    baseName: "Note", pathExtension: "txt"
                )
            }
            let entries = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            #expect(entries.isEmpty)
        }
    }
}

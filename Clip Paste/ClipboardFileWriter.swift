import Foundation
import Darwin

enum ClipboardFileWriter {
    /// Publishes a complete file without replacing an existing item, even if
    /// another paste claims the same filename while this write is in progress.
    @discardableResult
    static func write(
        _ data: Data,
        to directory: URL,
        baseName: String,
        pathExtension: String
    ) throws -> URL {
        let fileManager = FileManager.default
        let temporaryURL = directory.appendingPathComponent(".clip-paste-\(UUID().uuidString)")
        try data.write(to: temporaryURL, options: .atomic)
        defer { try? fileManager.removeItem(at: temporaryURL) }

        var number = 1
        while true {
            let name = number == 1 ? baseName : "\(baseName) (\(number))"
            let destination = directory.appendingPathComponent(name).appendingPathExtension(pathExtension)
            // FileManager.moveItem checks for existence before renaming, which
            // can still replace a file created by a concurrent paste. RENAME_EXCL
            // checks and publishes in one operation without replacing any item.
            if renamex_np(temporaryURL.path, destination.path, UInt32(RENAME_EXCL)) == 0 {
                return destination
            }
            let errorCode = errno
            if errorCode == EEXIST {
                number += 1
            } else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errorCode), userInfo: [
                    NSFilePathErrorKey: destination.path
                ])
            }
        }
    }
}

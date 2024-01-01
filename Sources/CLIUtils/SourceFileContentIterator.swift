import Foundation

public struct File {
    /// If missing, it means the content comes from stdin.
    public let fileName: String?
    public let content: [UInt8]

    public init(
        fileName: String? = nil,
        content: [UInt8]
    ) {
        self.fileName = fileName
        self.content = content
    }
}

/// An efficient file iterator that lazily iterates over files in directories.
public struct SourceFileContentIterator: IteratorProtocol {
    private let fileNames: [String]
    private var directoryIterators: [IndexingIterator<[URL]>]
    private var currentDirectoryIndex = 0
    private var fileIndex = 0

    public init(sourcePaths: any Sequence<String>) {
        var files = [String]()
        var directories = [String]()

        let fileManager = FileManager.default
        for path in sourcePaths {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    directories.append(path)
                } else {
                    files.append(path)
                }
            }
        }

        self.init(fileNames: files, directories: directories)
    }
    
    public init(
        fileNames: [String],
        directories: [String]
    ) {
        self.fileNames = fileNames
        self.directoryIterators = directories.map { directory in
            let fileURLs = FileManager.default.enumerator(
                at: URL(fileURLWithPath: directory),
                includingPropertiesForKeys: nil
            )?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" } ?? []

            return fileURLs.makeIterator()
        }
    }

    public mutating func next() -> File? {
        // First try to get the next file from the fileNames array
        if fileIndex < fileNames.count {
            let fileName = fileNames[fileIndex]
            fileIndex += 1
            return file(withPath: fileName)
        }

        // Iterate over the current directory
        while currentDirectoryIndex < directoryIterators.count {
            if let nextURL = directoryIterators[currentDirectoryIndex].next() {
                return file(withPath: nextURL.path)
            } else {
                // If the current directory is exhausted, move to the next directory
                currentDirectoryIndex += 1
            }
        }

        return nil
    }

    private func file(withPath path: String) -> File? {
        do {
            let fileURL = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: fileURL)
            return File(fileName: path, content: [UInt8](data))
        } catch {
            return nil
        }
    }
}

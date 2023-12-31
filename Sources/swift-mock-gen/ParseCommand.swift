//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import CLIUtils
import Foundation

struct ParseArguments: ParsableArguments {
    @Argument(
        help: "The source files and/or directories that should be parsed; use stdin if omitted",
        completion: .file()
    )
    var sourcePaths: [String] = []

    @Option(name: [.long], help: "If provided, parse the source text instead of reading source file")
    var source: String?

    @Option(
        name: [.long, .short],
        help: "If provided, writes generated mocks to the output directory in lieu of stdout.",
        completion: .directory
    )
    var outputDir: String?

    @Flag(
        name: [.short],
        help: "Enables verbose debug outputs"
    )
    var verbose: Bool = false
}

/// A command  that has arguments to parse source code
protocol ParseCommand {
  var arguments: ParseArguments { get }
}

protocol TextOutputStreamableSink {
    func stream(_ content: any TextOutputStreamable) throws
}

final class StdoutSink: TextOutputStreamableSink {
    func stream(_ content: TextOutputStreamable) throws {
        print(content)
    }
}

final class FileStreamSink: TextOutputStreamableSink {
    private(set) var stream: FileHandlerOutputStream

    init(stream: FileHandlerOutputStream) {
        self.stream = stream
    }

    func stream(_ content: TextOutputStreamable) throws {
        content.write(to: &stream)
    }
}

extension ParseCommand {
    /// The contents of the source files that should be parsed, each in UTF-8 bytes.
    func sourceFiles() -> any IteratorProtocol<File> {
        if let source = arguments.source {
            return SourceFileContentIterator(fileNames: [source], directories: [])
        } else if arguments.sourcePaths.isEmpty {
            return StdinIterator()
        } else {
            let dedupedSourcePaths = Set(arguments.sourcePaths)
            return SourceFileContentIterator(sourcePaths: dedupedSourcePaths)
        }
    }

    /// Writes a `TextOutputStreamable` content to the designated sink.
    ///
    /// This method reads from arguments and checks `outputDir` property. If exists, it will output
    /// to the directory as files. Otherwise it outputs to stdout.
    /// - Parameters:
    ///   - fileName: The file name. If missing, it assumes "Mock.swift".
    ///   - writeBlock: A closure in which the first argument is a sink object providing an interface to stream content.
    func withFileHandler(_ fileName: String?, writeBlock: (TextOutputStreamableSink) throws -> Void) throws -> Void {
        guard let outputDir = arguments.outputDir else {
            try writeBlock(StdoutSink())
            return
        }

        // Ensure the output directory exists
        let outputDirURL = URL(fileURLWithPath: outputDir)
        if !FileManager.default.fileExists(atPath: outputDirURL.path) {
            try FileManager.default.createDirectory(at: outputDirURL, withIntermediateDirectories: true, attributes: nil)
        }

        let outputFileName: String
        if let fileName = fileName {
            // This file name is a relative path that gets passed in.
            let url = URL(fileURLWithPath: fileName)
            let fileBaseName = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension.isEmpty ? "swift" : url.pathExtension

            // Append -Mock to the file name
            outputFileName = "\(fileBaseName)Mock.\(fileExtension)"
        } else {
            // Default file name with -Mock appended
            outputFileName = "Mock.swift"
        }

        let outputUrl = URL(fileURLWithPath: outputDir).appendingPathComponent(outputFileName)

        if arguments.verbose {
            print("swift-mock-gen: writing to \(outputUrl)")
        }

        if !FileManager.default.fileExists(atPath: outputUrl.path) {
            FileManager.default.createFile(atPath: outputUrl.path, contents: nil, attributes: nil)
        }

        let fileHandle = try FileHandle(forWritingTo: outputUrl)

        try writeBlock(FileStreamSink(stream: FileHandlerOutputStream(fileHandle)))

        fileHandle.closeFile()
    }
}

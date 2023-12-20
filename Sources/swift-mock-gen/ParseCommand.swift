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
}

/// A command  that has arguments to parse source code
protocol ParseCommand {
  var arguments: ParseArguments { get }
}

extension ParseCommand {
    /// The contents of the source files that should be parsed, each in UTF-8 bytes.
    func sourceFiles() -> any IteratorProtocol<File> {
        if let source = arguments.source {
            return SourceFileContentIterator(fileNames: [source], directories: [])
        } else if arguments.sourcePaths.isEmpty {
            return StdinIterator()
        } else {
            return SourceFileContentIterator(sourcePaths: arguments.sourcePaths)
        }
    }
    
    /// Writes a `TextOutputStreamable` content to the designated output.
    ///
    /// This method reads from arguments and checks `outputDir` property. If exists, it will output
    /// to the directory as files. Otherwise it outputs to stdout.
    /// - Parameters:
    ///   - output: The content of the output.
    ///   - fileName: The file name. If missing, it assumes "Mock.swift".
    func write(_ content: any TextOutputStreamable, to fileName: String?) throws {
        if let outputDir = arguments.outputDir {
            // Ensure the output directory exists
            let outputDirURL = URL(fileURLWithPath: outputDir)
            if !FileManager.default.fileExists(atPath: outputDirURL.path) {
                try FileManager.default.createDirectory(at: outputDirURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let outputFileName: String
            if let fileName = fileName {
                // Extract the file name from the path
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

            if !FileManager.default.fileExists(atPath: outputUrl.path) {
                FileManager.default.createFile(atPath: outputUrl.path, contents: nil, attributes: nil)
            }

            let fileHandle = try FileHandle(forWritingTo: outputUrl)
            var stream = FileHandlerOutputStream(fileHandle)
            content.write(to: &stream)

            fileHandle.closeFile()
        } else {
            print(content)
        }
    }
}

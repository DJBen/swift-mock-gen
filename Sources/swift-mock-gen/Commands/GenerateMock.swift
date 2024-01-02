import ArgumentParser
import CLIUtils
import CodeGenerationFactories
import SwiftParser
import SwiftSyntax

struct GenerateMock: ParsableCommand, ParseCommand, MockGenCommand {
    static var configuration = CommandConfiguration(
        commandName: "gen-alt",
        abstract: """
        Generate mock for given protocols in the provided source files.
        Note that this option is still in experimentation and may not compile.
        """
    )

    @OptionGroup
    var arguments: ParseArguments

    @OptionGroup
    var mockGenArguments: MockGenArguments

    @Flag(name: .long, inversion: .prefixedNo, help: "Surround with #if DEBUG directives. This ensures the mock only be included in DEBUG targets.")
    var surroundWithPoundIfDebug: Bool = false

    func run() throws {
        var sourceFiles = sourceFiles()
        while let sourceFile = sourceFiles.next() {
            try sourceFile.content.withUnsafeBufferPointer { sourceBuffer in
                let tree = Parser.parse(source: sourceBuffer)
                for codeBlockItemSyntax in tree.statements {
                    if let protocolDecl = codeBlockItemSyntax.item.as(ProtocolDeclSyntax.self) {
                        if mockGenArguments.excludeProtocols.contains(protocolDecl.name.trimmed.text) {
                            continue
                        }
                        let mockClass = try SourceFactory().classDecl(
                            protocolDecl: protocolDecl,
                            surroundWithPoundIfDebug: surroundWithPoundIfDebug
                        )
                        try withFileHandler(sourceFile.fileName) { sink in
                            try sink.stream(mockClass.formatted())
                        }
                    }
                }
            }
        }
    }
}

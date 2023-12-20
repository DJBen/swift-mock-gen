import ArgumentParser
import CodeGenerationFactories
import SwiftParser
import SwiftSyntax

struct GenerateMock: ParsableCommand, ParseCommand, MockGenCommand {
    static var configuration = CommandConfiguration(
        commandName: "gen-alt",
        abstract: "Generate mock for given protocols in the provided source files."
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
                        if mockGenArguments.excludeProtocols.contains(protocolDecl.name.text) {
                            continue
                        }
                        let mockClass = try SourceFactory().classDecl(
                            protocolDecl: protocolDecl,
                            surroundWithPoundIfDebug: surroundWithPoundIfDebug
                        )
                        try write(mockClass.formatted(), fromSourceFile: sourceFile.fileName)
                    }
                }
            }
        }
    }
}

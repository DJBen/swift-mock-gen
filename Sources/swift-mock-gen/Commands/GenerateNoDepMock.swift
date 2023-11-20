import ArgumentParser
import CodeGenerationFactories
import SwiftParser
import SwiftSyntax

struct GenerateNoDepMock: ParsableCommand, ParseCommand {
    static var configuration = CommandConfiguration(
        commandName: "gen",
        abstract: "Generate mock for given protocols in the provided source files. The generated mock needs no dependencies."
    )

    @OptionGroup
    var arguments: ParseArguments

    @Flag(
        name: .long,
        inversion: .prefixedNo,
        help: "Surround with #if DEBUG directives. This ensures the mock only be included in DEBUG targets."
    )
    var surroundWithPoundIfDebug: Bool = false

    @Flag(
        name: .long,
        help: "Copy the original imports from the source file."
    )
    var copyImports: Bool = false

    func run() throws {
        try sourceFileContents.withUnsafeBufferPointer { sourceBuffer in
            let tree = Parser.parse(source: sourceBuffer)
            let imports: [ImportDeclSyntax] = if copyImports {
                tree.statements.map { codeBlockItemSyntax in
                    if let importDecl = codeBlockItemSyntax.item.as(ImportDeclSyntax.self) {
                        return [importDecl]
                    }
                    return []
                }.reduce([], +)
            } else {
                []
            }

            try tree.statements.forEach { codeBlockItemSyntax in
                if let protocolDecl = codeBlockItemSyntax.item.as(ProtocolDeclSyntax.self) {
                    let mockClass = try NoDepSourceFactory().classDecl(
                        protocolDecl: protocolDecl,
                        surroundWithPoundIfDebug: surroundWithPoundIfDebug,
                        importDeclsToCopy: imports
                    )
                    print(mockClass.formatted())
                }
            }
        }
    }
}

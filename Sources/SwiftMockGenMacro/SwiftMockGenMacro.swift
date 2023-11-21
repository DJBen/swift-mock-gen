import SwiftSyntax
import SwiftSyntaxMacros
import CodeGenerationFactories

public enum SwiftMockGenMacro: PeerMacro {
    private static let sourceFactory = NoDepSourceFactory()
    private static let extractor = Extractor()

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let protocolDecl = try extractor.extractProtocolDecl(from: declaration)
        return try sourceFactory.decls(
            protocolDecl: protocolDecl,
            surroundWithPoundIfDebug: true,
            importDeclsToCopy: []
        )
    }
}

public enum GeneratMockMacroError: Error {
    case onlyApplicableToProtocol
}

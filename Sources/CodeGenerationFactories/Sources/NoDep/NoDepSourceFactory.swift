import SwiftSyntax
import SwiftSyntaxBuilder

public struct NoDepSourceFactory {
    let mockClassFactory: NoDepMockClassFactory

    public init(
        mockClassFactory: NoDepMockClassFactory = NoDepMockClassFactory()
    ) {
        self.mockClassFactory = mockClassFactory
    }

    public func decls(
        protocolDecl: ProtocolDeclSyntax,
        surroundWithPoundIfDebug: Bool,
        excludeProtocols: [String],
        importDeclsToCopy: [ImportDeclSyntax],
        customGenericTypes: [String: String],
        customSnippet: String?,
        onlyGenerateForPublicProtocols: Bool,
        verbose: Bool
    ) throws -> [DeclSyntax] {
        if excludeProtocols.contains(protocolDecl.name.trimmed.text) {
            if verbose {
                print("Skipping \(protocolDecl.name.trimmed.text)")
            }
            return []
        }
        
        if onlyGenerateForPublicProtocols && !protocolDecl.modifiers.isPublic {
            return []
        }

        let classDecl = try mockClassFactory.classDecl(
            protocolDecl: protocolDecl,
            customGenericTypes: customGenericTypes,
            customSnippet: customSnippet
        )
        var decls = [DeclSyntax]()

        for importDecl in importDeclsToCopy {
            decls.append(DeclSyntax(importDecl))
        }

        let wrappedClassDecl = if surroundWithPoundIfDebug {
            DeclSyntax(
                IfConfigDeclSyntax(
                    clauses: IfConfigClauseListSyntax(itemsBuilder: {
                        IfConfigClauseSyntax(
                            poundKeyword: .poundIfToken(),
                            condition: DeclReferenceExprSyntax(baseName: .identifier("DEBUG")),
                            elements: .decls(MemberBlockItemListSyntax(itemsBuilder: {
                                MemberBlockItemSyntax(decl: classDecl)
                            }))
                        )
                    })
                )
                .with(\.leadingTrivia, .newlines(2))
            )
        } else {
            DeclSyntax(
                classDecl.with(\.leadingTrivia, .newlines(2)).with(\.trailingTrivia, .newline)
            )
        }

        decls.append(
            wrappedClassDecl
        )

        return decls
    }
}

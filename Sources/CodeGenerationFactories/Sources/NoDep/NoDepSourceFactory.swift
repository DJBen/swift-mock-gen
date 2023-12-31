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
        importDeclsToCopy: [ImportDeclSyntax],
        customGenericTypes: [String: String]
    ) throws -> [DeclSyntax] {
        let classDecl = try mockClassFactory.classDecl(
            protocolDecl: protocolDecl,
            customGenericTypes: customGenericTypes
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

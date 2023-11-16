import SwiftSyntax
import SwiftSyntaxBuilder

public struct NoDepSourceFactory {
    let mockClassFactory: NoDepMockClassFactory

    public init(
        mockClassFactory: NoDepMockClassFactory = NoDepMockClassFactory()
    ) {
        self.mockClassFactory = mockClassFactory
    }

    public func classDecl(
        protocolDecl: ProtocolDeclSyntax,
        surroundWithPoundIfDebug: Bool
    ) throws -> some SyntaxProtocol {
        let classDecl = try mockClassFactory.classDecl(
            protocolDecl: protocolDecl
        )
        return SourceFileSyntax {
            "import Foundation"

            if surroundWithPoundIfDebug {
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
            } else {
                classDecl
            }
        }
    }
}

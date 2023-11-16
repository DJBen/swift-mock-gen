import SwiftSyntax
import SwiftSyntaxBuilder

public struct SourceFactory {
    let mockClassFactory: MockClassFactory

    public init(
        mockClassFactory: MockClassFactory = MockClassFactory()
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
            "import MockSupport"
            "import XCTest"

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

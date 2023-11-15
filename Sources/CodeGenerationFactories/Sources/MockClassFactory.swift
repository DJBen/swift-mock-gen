import SwiftSyntax
import SwiftSyntaxBuilder

public struct MockClassFactory {
    private let funcClassMemberImplFactory: FunctionClassMemberImplFactory
    private let funcExpectImplFactory: FunctionExpectImplFactory
    private let funcMockImplFactory: FunctionMockImplFactory
    private let funcStubImplFactory: FunctionStubImplFactory
    private let funcVerifyImplFactory: FunctionVerifyImplFactory

    public init(
        funcClassMemberImplFactory: FunctionClassMemberImplFactory = FunctionClassMemberImplFactory(),
        funcExpectImplFactory: FunctionExpectImplFactory = FunctionExpectImplFactory(),
        funcMockImplFactory: FunctionMockImplFactory = FunctionMockImplFactory(),
        funcStubImplFactory: FunctionStubImplFactory = FunctionStubImplFactory(),
        funcVerifyImplFactory: FunctionVerifyImplFactory = FunctionVerifyImplFactory()
    ) {
        self.funcClassMemberImplFactory = funcClassMemberImplFactory
        self.funcExpectImplFactory = funcExpectImplFactory
        self.funcMockImplFactory = funcMockImplFactory
        self.funcStubImplFactory = funcStubImplFactory
        self.funcVerifyImplFactory = funcVerifyImplFactory
    }

    public func classDecl(
        protocolDecl: ProtocolDeclSyntax
    ) throws -> some DeclSyntaxProtocol {
        // Name rule:
        // - If ending with `-ing`, replace with `-or` and append `Mock`.
        // - If ending with `-Protocol`, remove and append `Mock`.
        // - Otherwise, append `Mock` without any changes.
        let name = {
            var trimmedText = protocolDecl.name.trimmed.text
            if trimmedText.hasSuffix("ing") {
                trimmedText.removeLast(3)
                trimmedText.append("or")
            } else if trimmedText.hasSuffix("Protocol") {
                trimmedText.removeLast("Protocol".lengthOfBytes(using: .utf8))
            }
            trimmedText.append("Mock")
            return trimmedText
        }()

        let isObjcProtocol = protocolDecl.attributes.hasObjc || protocolDecl.isNSObjectProtocol

        return try ClassDeclSyntax(
            modifiers: DeclModifierListSyntax {
                // Append the same scope modifier to the class (public, internal, ...)
                if let scopeModifier = protocolDecl.modifiers.scopeModifier {
                    scopeModifier.trimmed
                }
            },
            name: "\(raw: name)",
            inheritanceClause: InheritanceClauseSyntax {
                if isObjcProtocol {
                    InheritedTypeListSyntax {
                        InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("NSObject")))
                    }
                }
                InheritedTypeListSyntax {
                    InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("\(protocolDecl.name)")))
                }
            }
        ) {
            // Add intializer only for non-NSObject class and only when protocol is public
            if !isObjcProtocol && protocolDecl.modifiers.isPublic {
                InitializerDeclSyntax(
                    modifiers: DeclModifierListSyntax {
                        // Append scope modifier to the function (public, internal, ...)
                        if let scopeModifier = protocolDecl.modifiers.scopeModifier {
                            scopeModifier.trimmed
                        }
                    },
                    signature: FunctionSignatureSyntax(parameterClause: FunctionParameterClauseSyntax(parameters: FunctionParameterListSyntax(itemsBuilder: {})))
                ) {}
            }
            
            for member in protocolDecl.memberBlock.members {
                if let protocolFunctionDeclaration = member.decl.as(FunctionDeclSyntax.self) {
                    for decl in try funcClassMemberImplFactory.declarations(
                        protocolDecl: protocolDecl,
                        protocolFunctionDeclaration: protocolFunctionDeclaration
                    ) {
                        MemberBlockItemSyntax(decl: decl)
                    }

                    try funcMockImplFactory.declaration(
                        protocolDecl: protocolDecl,
                        protocolFunctionDeclaration: protocolFunctionDeclaration
                    )

                    try funcStubImplFactory.declaration(
                        protocolDecl: protocolDecl,
                        protocolFunctionDeclaration: protocolFunctionDeclaration
                    )

                    try funcExpectImplFactory.declaration(
                        protocolDecl: protocolDecl,
                        protocolFunctionDeclaration: protocolFunctionDeclaration
                    )

                    try funcVerifyImplFactory.declaration(
                        protocolDecl: protocolDecl,
                        protocolFunctionDeclaration: protocolFunctionDeclaration
                    )
                }
            }
        }
    }
}

import SwiftSyntax
import SwiftSyntaxBuilder

public struct NoDepMockClassFactory {
    private let functionInvocationImplFactory: FunctionInvocationImplFactory
    private let funcMockImplFactory: FunctionMockNoDepImplFactory
    private let functionHandlerImplFactory: FunctionHandlerNoDepImplFactory
    private let variableImplFactory: VariableImplFactory

    public init(
        functionInvocationImplFactory: FunctionInvocationImplFactory = FunctionInvocationImplFactory(),
        funcMockImplFactory: FunctionMockNoDepImplFactory = FunctionMockNoDepImplFactory(),
        functionHandlerImplFactory: FunctionHandlerNoDepImplFactory = FunctionHandlerNoDepImplFactory(),
        variableImplFactory: VariableImplFactory = VariableImplFactory()
    ) {
        self.functionInvocationImplFactory = functionInvocationImplFactory
        self.funcMockImplFactory = funcMockImplFactory
        self.functionHandlerImplFactory = functionHandlerImplFactory
        self.variableImplFactory = variableImplFactory
    }

    public func classDecl(
        protocolDecl: ProtocolDeclSyntax
    ) throws -> some DeclSyntaxProtocol {
        // Name rule:
        // - If ending with `-Protocol`, remove and append `Mock`.
        // - Otherwise, append `Mock` without any changes.
        let name = {
            var trimmedText = protocolDecl.name.trimmed.text
            if trimmedText.hasSuffix("Protocol") {
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

            let funcDecls = protocolDecl.memberBlock.members.compactMap { member -> FunctionDeclSyntax? in
                return member.decl.as(FunctionDeclSyntax.self)
            }
            let deduper = FuncNameDeduper(
                protocolDecl: protocolDecl,
                funcDecls: funcDecls
            )

            for member in protocolDecl.memberBlock.members {
                if let protocolFunctionDecl = member.decl.as(VariableDeclSyntax.self) {
                    for decl in try variableImplFactory.decls(
                        protocolDecl: protocolDecl,
                        protocolVariableDecl: protocolFunctionDecl
                    ) {
                        MemberBlockItemSyntax(decl: decl)
                    }
                } else if let protocolFunctionDecl = member.decl.as(FunctionDeclSyntax.self) {
                    for decl in try functionInvocationImplFactory.decls(
                        protocolDecl: protocolDecl,
                        protocolFunctionDecl: protocolFunctionDecl,
                        funcUniqueName: deduper.name(for: protocolFunctionDecl)
                    ) {
                        MemberBlockItemSyntax(decl: decl)
                    }

                    try functionHandlerImplFactory.declaration(
                        protocolDecl: protocolDecl,
                        protocolFunctionDecl: protocolFunctionDecl,
                        funcUniqueName: deduper.name(for: protocolFunctionDecl)
                    )

                    try funcMockImplFactory.declaration(
                        protocolDecl: protocolDecl,
                        protocolFunctionDecl: protocolFunctionDecl,
                        funcUniqueName: deduper.name(for: protocolFunctionDecl)
                    )
                }
            }
        }
    }
}

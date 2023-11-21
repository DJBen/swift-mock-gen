import SwiftSyntax
import SwiftSyntaxBuilder

public struct FunctionHandlerNoDepImplFactory {
    public init() {}

    public func declaration(
        protocolDecl: ProtocolDeclSyntax,
        protocolFunctionDecl: FunctionDeclSyntax,
        funcUniqueName: String
    ) throws -> VariableDeclSyntax {
        // Append protocol scope modifier to the function (public, internal, ...)
        var modifiers = protocolFunctionDecl.modifiers
        modifiers.clearScopeModifier()
        if let scopeModifier = protocolDecl.modifiers.scopeModifier {
            modifiers.append(scopeModifier.trimmed)
        }

        return VariableDeclSyntax(
            attributes: [],
            modifiers: modifiers,
            .var,
            name: PatternSyntax("handler_\(raw: funcUniqueName)"),
            type: TypeAnnotationSyntax(
                type: OptionalTypeSyntax(
                    wrappedType: TupleTypeSyntax(
                        elements: TupleTypeElementListSyntax(
                            itemsBuilder: {
                                TupleTypeElementSyntax(
                                    type: protocolFunctionDecl.signature.toVariableDeclFunctionType()
                                )
                            }
                        )
                    )
                )
            )
        )
        .with(\.leadingTrivia, [.newlines(2)])
    }
}

extension FunctionSignatureSyntax {
    func toVariableDeclFunctionType() -> FunctionTypeSyntax {
        FunctionTypeSyntax(
            parameters: TupleTypeElementListSyntax(itemsBuilder: {
                for param in parameterClause.parameters {
                    TupleTypeElementSyntax(type: param.type)
                }
            }),
            effectSpecifiers: effectSpecifiers.map {
                TypeEffectSpecifiersSyntax(
                    asyncSpecifier: $0.asyncSpecifier,
                    throwsSpecifier: $0.throwsSpecifier
                )
            },
            returnClause: returnClause ?? ReturnClauseSyntax(type: IdentifierTypeSyntax(name: .identifier("Void")))
        )
    }
}

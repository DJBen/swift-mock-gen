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
        var modifiers = protocolFunctionDecl.modifiers.clearingScopeModifier().removingOptionalModifier()
        if let scopeModifier = protocolDecl.modifiers.scopeModifier {
            modifiers.append(scopeModifier.trimmed)
        }

        return VariableDeclSyntax(
            attributes: AttributeListSyntax {
                if protocolFunctionDecl.attributes.hasObjc {
                    "@objc"
                }
            },
            modifiers: modifiers,
            .var,
            name: PatternSyntax("handler_\(raw: funcUniqueName)"),
            type: TypeAnnotationSyntax(
                type: OptionalTypeSyntax(
                    wrappedType: TupleTypeSyntax(
                        elements: TupleTypeElementListSyntax(
                            itemsBuilder: {
                                TupleTypeElementSyntax(
                                    type: protocolFunctionDecl.toVariableDeclFunctionType(
                                        funcDecl: protocolFunctionDecl
                                    )
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

extension FunctionDeclSyntax {
    /// Turn the function signature to a variable return type.
    /// - Returns: The type converted to a variable style.
    func toVariableDeclFunctionType(
        funcDecl: FunctionDeclSyntax
    ) -> FunctionTypeSyntax {
        FunctionTypeSyntax(
            parameters: TupleTypeElementListSyntax {
                for param in signature.parameterClause.parameters {
                    if let identifierType = param.type.as(IdentifierTypeSyntax.self), let protocolConstraintType = genericParametersMap[identifierType.name.trimmed.text] {
                        TupleTypeElementSyntax(
                            type: SomeOrAnyTypeSyntax(
                                someOrAnySpecifier: .keyword(.any),
                                constraint: protocolConstraintType
                            )
                        )
                    } else {
                        TupleTypeElementSyntax(type: param.type.eraseTypeWithinFunctionGenerics(funcDecl: funcDecl))
                    }
                }
            },
            effectSpecifiers: signature.effectSpecifiers.map {
                TypeEffectSpecifiersSyntax(
                    asyncSpecifier: $0.asyncSpecifier,
                    throwsSpecifier: $0.throwsSpecifier
                )
            },
            returnClause: signature.returnClause ?? ReturnClauseSyntax(type: IdentifierTypeSyntax(name: .identifier("Void")))
        )
    }
}

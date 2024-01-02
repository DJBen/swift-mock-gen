import SwiftSyntax
import SwiftSyntaxBuilder

public struct GenericParamsDeclsFactory {
    public init() {}

    public func decls(
        protocolDecl: ProtocolDeclSyntax
    ) -> (GenericParameterClauseSyntax?, [TypeAliasDeclSyntax]) {
        let protocolScopeModifiers = DeclModifierListSyntax {
            // Append scope modifier to the function (public, internal, ...)
            if let scopeModifier = protocolDecl.modifiers.scopeModifier {
                scopeModifier.trimmed
            }
        }

        var genericInheritanceCount = 0
        var typealiasDecls = [TypeAliasDeclSyntax]()
        var genericParameters = [GenericParameterSyntax]()

        for member in protocolDecl.memberBlock.members {
            if let associatedTypeDecl = member.decl.as(AssociatedTypeDeclSyntax.self) {

                // If there is an `associatetype A = B`, synthesize a typealias without synthesizing a generic parameter.
                if let initializer = associatedTypeDecl.initializer {
                    typealiasDecls.append(
                        TypeAliasDeclSyntax(
                            modifiers: protocolScopeModifiers,
                            name: associatedTypeDecl.name,
                            initializer: initializer
                        )
                    )
                }

                if let inheritanceClause = associatedTypeDecl.inheritanceClause {
                    typealiasDecls.append(
                        TypeAliasDeclSyntax(
                            modifiers: protocolScopeModifiers,
                            name: associatedTypeDecl.name,
                            initializer: TypeInitializerClauseSyntax(value: IdentifierTypeSyntax(name: .identifier("P\(genericInheritanceCount + 1)")))
                        )
                    )

                    genericParameters.append(
                        GenericParameterSyntax(
                            name: .identifier("P\(genericInheritanceCount + 1)"),
                            colon: .colonToken(),
                            inheritedType: inheritanceClause.inheritedTypes.toCompositionOrIdentifierType()
                        )
                    )

                    genericInheritanceCount += 1
                }
            }
        }

        return (
            genericParameters.isEmpty ? nil : GenericParameterClauseSyntax(parameters: GenericParameterListSyntax(genericParameters)),
            typealiasDecls
        )
    }
}

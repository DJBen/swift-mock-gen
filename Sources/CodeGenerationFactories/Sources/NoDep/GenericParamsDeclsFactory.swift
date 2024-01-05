import SwiftSyntax
import SwiftSyntaxBuilder

public struct GenericParamsDeclsFactory {
    public struct Result {
        /// The generic parameters that should be put into the class header
        public let genericParameterClause: GenericParameterClauseSyntax?

        /// The generic where syntax that should be put at the end of the class header declaration
        public let genericWhereClauseSyntax: GenericWhereClauseSyntax?

        /// Typealias declarations that should be put into the class.
        public let typealiasDecls: [TypeAliasDeclSyntax]
    }

    public init() {}

    public func decls(
        protocolDecl: ProtocolDeclSyntax,
        customGenericTypes: [String: String]
    ) -> Result {
        let protocolScopeModifiers = DeclModifierListSyntax {
            // Append scope modifier to the function (public, internal, ...)
            if let scopeModifier = protocolDecl.modifiers.scopeModifier {
                scopeModifier.trimmed
            }
        }

        var genericInheritanceCount = 0
        var typealiasDecls = [TypeAliasDeclSyntax]()
        var genericParameters = [GenericParameterSyntax]()
        var requirements = [GenericRequirementSyntax]()
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
                } else if let inheritanceClause = associatedTypeDecl.inheritanceClause {

                    if let customType = customGenericTypes[associatedTypeDecl.name.trimmed.text] {
                        
                        // If a custom type for a generic type is provided, we set the typealias without synthesizing a generic type.
                        typealiasDecls.append(
                            TypeAliasDeclSyntax(
                                modifiers: protocolScopeModifiers,
                                name: associatedTypeDecl.name,
                                initializer: TypeInitializerClauseSyntax(value: IdentifierTypeSyntax(name: .identifier(customType)))
                            )
                        )
                    } else {
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
                            ).trimmed
                        )

                        if let whereClause = associatedTypeDecl.genericWhereClause {
                            requirements.append(contentsOf: whereClause.requirements.map {
                                $0.replacingBaseType(
                                    IdentifierTypeSyntax(name: .identifier("P\(genericInheritanceCount + 1)"))
                                )
                            })
                        }

                        genericInheritanceCount += 1
                    }
                } else {
                    // A plain associated type like `associatedtype UserID`
                    genericParameters.append(
                        GenericParameterSyntax(
                            name: associatedTypeDecl.name
                        )
                    )
                }
            }
        }

        // Insert trailing comma to generic parameters
        if genericParameters.count > 1 {
            for index in 0..<genericParameters.count - 1 {
                genericParameters[index] = GenericParameterSyntax(
                    name: genericParameters[index].name,
                    colon: genericParameters[index].colon,
                    inheritedType: genericParameters[index].inheritedType,
                    trailingComma: .commaToken()
                )
            }
        }

        return Result(
            genericParameterClause: genericParameters.isEmpty ? nil : GenericParameterClauseSyntax(parameters: GenericParameterListSyntax(genericParameters)),
            genericWhereClauseSyntax: requirements.isEmpty ? nil : GenericWhereClauseSyntax {
                GenericRequirementListSyntax {
                    for requirement in requirements {
                        requirement
                    }
                }
            },
            typealiasDecls: typealiasDecls
        )
    }
}

extension GenericRequirementSyntax {
    func replacingBaseType(_ newBaseType: IdentifierTypeSyntax) -> GenericRequirementSyntax {
        switch requirement {
        case .sameTypeRequirement(let sameTypeRequirementSyntax):
            if let memberType = sameTypeRequirementSyntax.leftType.as(MemberTypeSyntax.self) {
                return GenericRequirementSyntax(
                    requirement: .sameTypeRequirement(
                        SameTypeRequirementSyntax(
                            leftType: MemberTypeSyntax(
                                baseType: newBaseType,
                                name: memberType.name
                            ),
                            equal: sameTypeRequirementSyntax.equal,
                            rightType: sameTypeRequirementSyntax.rightType
                        )
                    )
                )
            }
            return self
        default:
            return self
        }
    }
}

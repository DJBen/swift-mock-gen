import SwiftSyntax
import SwiftSyntaxBuilder

public struct FunctionInvocationImplFactory {
    public init() {}

    public func decls(
        protocolDecl: ProtocolDeclSyntax,
        protocolFunctionDecl: FunctionDeclSyntax,
        funcUniqueName: String
    ) throws -> [DeclSyntax] {
        let modifiers = DeclModifierListSyntax {
            if let scopeModifier = protocolDecl.modifiers.scopeModifier {
                scopeModifier.trimmed
            }
        }

        let parameters = protocolFunctionDecl.signature.parameterClause.parameters

        return [
            DeclSyntax(
                StructDeclSyntax(
                    modifiers: modifiers,
                    name: "Invocation_\(raw: funcUniqueName)",
                    memberBlock: try MemberBlockSyntax {
                        for funcParamSyntax in parameters {
                            let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                            if funcParamSyntax.type.isFunctionTypeSyntax {
                                try VariableDeclSyntax(
                                    "\(raw: modifiers) let \(raw: name): Void"
                                )
                            } else {
                                let genericParametersMap = protocolFunctionDecl.genericParametersMap
                                let type = funcParamSyntax.removingEscaping().type
                                if let identifierType = type.as(IdentifierTypeSyntax.self), let protocolConstraintType = genericParametersMap[identifierType.name.trimmed.text] {
                                    let anyType = SomeOrAnyTypeSyntax(
                                        someOrAnySpecifier: .keyword(.any),
                                        constraint: protocolConstraintType
                                    ).formatted()
                                    try VariableDeclSyntax("\(raw: modifiers) let \(raw: name): \(anyType)")
                                } else {
                                    try VariableDeclSyntax("\(raw: modifiers) let \(raw: name): \(type)")
                                }
                            }
                        }
                    }
                )
            ),
            DeclSyntax(
                VariableDeclSyntax(
                    attributes: [],
                    modifiers: DeclModifierListSyntax {
                        if protocolFunctionDecl.modifiers.isStatic {
                            DeclModifierSyntax(name: .keyword(.static))
                        }
                        if protocolDecl.modifiers.isPublic {
                            DeclModifierSyntax(name: .keyword(.public))
                        }
                        DeclModifierSyntax(
                            name: .keyword(.private), 
                            detail: DeclModifierDetailSyntax(detail: .identifier("set"))
                        )
                    },
                    bindingSpecifier: .keyword(.var),
                    bindings: PatternBindingListSyntax {
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: "invocations_\(raw: funcUniqueName)"),
                            initializer: InitializerClauseSyntax(value: ExprSyntax("[Invocation_\(raw: funcUniqueName)]()"))
                        )

                    }
                )
            )
        ]
    }
}

extension FunctionParameterSyntax {
    func removingEscaping() -> FunctionParameterSyntax {
        if let attributedType = type.as(AttributedTypeSyntax.self) {
            var copyType = type.as(AttributedTypeSyntax.self)!
            copyType.attributes = attributedType.attributes.filter({ attr in
                if case .attribute(let attr) = attr, let id = attr.attributeName.as(IdentifierTypeSyntax.self) {
                    return id.name.text != "escaping"
                }
                return true
            })
            var copySelf = self
            copySelf.type = TypeSyntax(copyType)
            return copySelf
        } else {
            return self
        }
    }
}

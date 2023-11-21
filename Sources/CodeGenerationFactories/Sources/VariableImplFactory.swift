import SwiftSyntax
import SwiftSyntaxBuilder

public struct VariableImplFactory {
    public init() {}

    public func decls(
        protocolDecl: ProtocolDeclSyntax,
        protocolVariableDecl: VariableDeclSyntax
    ) throws -> [any DeclSyntaxProtocol] {
        if let binding = protocolVariableDecl.bindings.first {
            return [
                /**
                 public var id: String? {
                 get {
                 getCount_id += 1
                 return underlying_id
                 }
                 set {
                 setCount_id += 1
                 underlying_id = newValue
                 }
                 }
                 */
                VariableDeclSyntax(
                    attributes: [],
                    modifiers: DeclModifierListSyntax {
                        // Append scope modifier to the function (public, internal, ...)
                        if let scopeModifier = protocolDecl.modifiers.scopeModifier {
                            scopeModifier.trimmed
                        }
                    },
                    bindingSpecifier: .keyword(.var),
                    bindingsBuilder: {
                        PatternBindingSyntax(
                            pattern: binding.pattern,
                            typeAnnotation: binding.typeAnnotation,
                            accessorBlock: AccessorBlockSyntax(
                                accessors: .accessors(
                                    [
                                        AccessorDeclSyntax(accessorSpecifier: .keyword(.get)) {
                                            CodeBlockItemListSyntax {
                                                "getCount_\(binding.pattern) += 1"
                                                "return underlying_\(binding.pattern)"
                                            }
                                        }
                                    ] + (binding.accessorBlock?.protocolVarIsGetSet ?? false ? [
                                        AccessorDeclSyntax(accessorSpecifier: .keyword(.set)) {
                                            CodeBlockItemListSyntax {
                                                "setCount_\(binding.pattern) += 1"
                                                "underlying_\(binding.pattern) = newValue"
                                            }
                                        }
                                    ] : [])
                                )
                            )
                        )
                    }
                )
                .with(\.leadingTrivia, [.newlines(2)]),

                // public var underlying_id: String!
                VariableDeclSyntax(
                    attributes: [],
                    modifiers: protocolVariableDecl.modifiers.removingSetterModifier().trimmed,
                    bindingSpecifier: .keyword(.var),
                    bindingsBuilder: {
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("underlying_\(binding.pattern)")),
                            typeAnnotation: binding.typeAnnotation.map {
                                TypeAnnotationSyntax(type: $0.trimmed.type.toImplicitOptional())
                            }
                        )
                    }
                ),

                // public private(set) var getCount_id: Int = 0
                VariableDeclSyntax(
                    attributes: [],
                    modifiers: {
                        var getSetCountModifiers = protocolVariableDecl.modifiers.removingSetterModifier().trimmed

                        getSetCountModifiers.append(
                            DeclModifierSyntax(
                                name: .keyword(.private),
                                detail: DeclModifierDetailSyntax(DeclModifierDetailSyntax(detail: TokenSyntax.identifier("set")))
                            )
                        )

                        return getSetCountModifiers
                    }(),
                    bindingSpecifier: .keyword(.var),
                    bindingsBuilder: {
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("getCount_\(binding.pattern)")),
                            typeAnnotation: TypeAnnotationSyntax(type: TypeSyntax("Int")),
                            initializer: InitializerClauseSyntax(value: ExprSyntax(literal: 0))
                        )
                    }
                ),

                // public private(set) var setCount_id: Int = 0
                VariableDeclSyntax(
                    attributes: [],
                    modifiers: {
                        var getSetCountModifiers = protocolVariableDecl.modifiers.removingSetterModifier().trimmed

                        getSetCountModifiers.append(
                            DeclModifierSyntax(
                                name: .keyword(.private),
                                detail: DeclModifierDetailSyntax(DeclModifierDetailSyntax(detail: TokenSyntax.identifier("set")))
                            )
                        )

                        return getSetCountModifiers
                    }(),
                    bindingSpecifier: .keyword(.var),
                    bindingsBuilder: {
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("setCount_\(binding.pattern)")),
                            typeAnnotation: TypeAnnotationSyntax(type: TypeSyntax("Int")),
                            initializer: InitializerClauseSyntax(value: ExprSyntax(literal: 0))
                        )
                    }
                )
            ]
        } else {
            return []
        }
    }
}

extension DeclModifierListSyntax {
    /// Given a modifier list, removing the scope modifier that is specific to "set".
    /// e.g public private(set) becomes public.
    /// - Returns: A modifier list after modifier specific to 'set' is removed.
    func removingSetterModifier() -> DeclModifierListSyntax {
        filter({
            $0.detail?.detail.text != "set"
        })
    }
}

extension TypeSyntax {
    func toImplicitOptional() -> ImplicitlyUnwrappedOptionalTypeSyntax {
        if let optional = self.as(OptionalTypeSyntax.self) {
            return ImplicitlyUnwrappedOptionalTypeSyntax(wrappedType: optional.wrappedType)
        } else if let function = self.as(FunctionTypeSyntax.self) {
            // Need to wrap function with parens
            return ImplicitlyUnwrappedOptionalTypeSyntax(
                wrappedType: TupleTypeSyntax(
                    elements: TupleTypeElementListSyntax(
                        itemsBuilder: {
                            TupleTypeElementSyntax(type: function)
                        }
                    )
                )
            )
        } else if let someOrAny = self.as(SomeOrAnyTypeSyntax.self) {
            // Wrap some X or any X types with parens
            return ImplicitlyUnwrappedOptionalTypeSyntax(
                wrappedType: TupleTypeSyntax(
                    elements: TupleTypeElementListSyntax(
                        itemsBuilder: {
                            TupleTypeElementSyntax(type: someOrAny)
                        }
                    )
                )
            )
        } else {
            return ImplicitlyUnwrappedOptionalTypeSyntax(wrappedType: self)
        }
    }
}

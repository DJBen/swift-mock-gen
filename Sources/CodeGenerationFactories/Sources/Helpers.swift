import SwiftSyntax

extension AttributeListSyntax {
    /// Whether attribute has @objc annotation.
    var hasObjc: Bool {
        contains { attr in
            switch attr {
            case .attribute(let attrSyntax):
                return attrSyntax.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "objc"
            case .ifConfigDecl(_):
                return false
            }
        }
    }
}

extension ProtocolDeclSyntax {
    var isNSObjectProtocol: Bool {
        inheritanceClause?.inheritedTypes.contains(
            where: { $0.type.as(IdentifierTypeSyntax.self)?.name.text == "NSObjectProtocol" }
        ) ?? false
    }
}

extension DeclModifierListSyntax {
    var scopeModifier: DeclModifierSyntax? {
        first(where: {
            $0.name.text == TokenSyntax.keyword(.public).text ||
            $0.name.text == TokenSyntax.keyword(.private).text ||
            $0.name.text == TokenSyntax.keyword(.fileprivate).text ||
            $0.name.text == TokenSyntax.keyword(.internal).text ||
            $0.name.text == TokenSyntax.keyword(.open).text
        })
    }

    var isPublic: Bool {
        contains(where: {
            $0.name.text == TokenSyntax.keyword(.public).text
        })
    }

    func clearingScopeModifier() -> DeclModifierListSyntax {
        filter {
            $0.name.text != TokenSyntax.keyword(.public).text ||
            $0.name.text != TokenSyntax.keyword(.private).text ||
            $0.name.text != TokenSyntax.keyword(.fileprivate).text ||
            $0.name.text != TokenSyntax.keyword(.internal).text ||
            $0.name.text != TokenSyntax.keyword(.open).text
        }
    }

    /// Given a modifier list, removing the scope modifier that is specific to "set".
    /// e.g public private(set) becomes public.
    /// - Returns: A modifier list after modifier specific to 'set' is removed.
    func removingSetterModifier() -> DeclModifierListSyntax {
        filter({
            $0.detail?.detail.text != "set"
        })
    }

    func removingWeakModifier() -> DeclModifierListSyntax {
        filter({
            $0.name.text != "weak"
        })
    }

    func removingOptionalModifier() -> DeclModifierListSyntax {
        filter({
            $0.name.text != "optional"
        })
    }
}

extension AccessorBlockSyntax {
    var protocolVarIsGetSet: Bool {
        switch accessors {
        case .accessors(let accessorDecl):
            return accessorDecl.contains(where: { $0.accessorSpecifier.text == TokenSyntax.keyword(.get).text }) &&
            accessorDecl.contains(where: { $0.accessorSpecifier.text == TokenSyntax.keyword(.set).text })
        case .getter(_):
            // A protocol cannot have a getter impl syntax.
            return false
        }
    }
}

extension TypeSyntax {
    /// Whether it is a function type syntax or attributed syntax that has an underlying function type syntax.
    /// e.g. `@escaping () -> Void` or `(Int, String) -> Void`
    var isFunctionTypeSyntax: Bool {
        if self.is(FunctionTypeSyntax.self) {
            return true
        }
        if let attr = self.as(AttributedTypeSyntax.self) {
            return attr.baseType.is(FunctionTypeSyntax.self)
        }
        if let tuple = self.as(TupleTypeSyntax.self) {
            if tuple.elements.count == 1, let firstElement = tuple.elements.first {
                return firstElement.type.isFunctionTypeSyntax
            }
            return false
        }
        return false
    }

    var underlyingFunctionTypeSyntax: FunctionTypeSyntax? {
        if let funcTypeSyntax = self.as(FunctionTypeSyntax.self) {
            return funcTypeSyntax
        }
        if let attr = self.as(AttributedTypeSyntax.self), let funcTypeSyntax = attr.baseType.as(FunctionTypeSyntax.self) {
            return funcTypeSyntax
        }
        return nil
    }
}

extension VariableDeclSyntax {
    var hasAtObjcAttribute: Bool {
        attributes.contains { attr in
            switch attr {
            case .attribute(let attrSyntax):
                return attrSyntax.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "objc"
            default:
                return false
            }
        }
    }

    var hasWeakModifier: Bool {
        modifiers.contains { modifier in
            switch modifier.name.tokenKind {
            case .keyword(let value):
                return value == .weak
            default:
                return false
            }
        }
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

    func toOptional() -> OptionalTypeSyntax {
        if let optional = self.as(OptionalTypeSyntax.self) {
            return optional
        } else if let implicitOptional = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return OptionalTypeSyntax(wrappedType: implicitOptional.wrappedType)
        }  else if let function = self.as(FunctionTypeSyntax.self) {
            // Need to wrap function with parens
            return OptionalTypeSyntax(
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
            return OptionalTypeSyntax(
                wrappedType: TupleTypeSyntax(
                    elements: TupleTypeElementListSyntax(
                        itemsBuilder: {
                            TupleTypeElementSyntax(type: someOrAny)
                        }
                    )
                )
            )
        } else {
            return OptionalTypeSyntax(wrappedType: self)
        }
    }
}


extension TypeAnnotationSyntax {
    func toOptional() -> TypeAnnotationSyntax {
        TypeAnnotationSyntax(
            leadingTrivia: leadingTrivia,
            colon: colon,
            type: type.toOptional(),
            trailingTrivia: trailingTrivia
        )
    }
}

extension InheritedTypeListSyntax {
    /// Convert from `associatedtype Subject: ExecutorSubject, FloatingPoint` to `<P1: ExecutorSubject & FloatingPoint>`
    func toCompositionOrIdentifierType() -> any TypeSyntaxProtocol {
        if count > 1 {
            return CompositionTypeSyntax(
                elements: CompositionTypeElementListSyntax {
                    for inheritedType in self {
                        CompositionTypeElementSyntax(type: inheritedType.type)
                    }
                }
            ).trimmed
        } else {
            return first!.type
        }
    }
}

extension FunctionDeclSyntax {
    /// Returns a list of generic parameters with constraints
    /// e.g. `func renderer<Item: FloatingPoint>` returns ["Item": "FloatingPoint"]
    var genericParametersMap: [String: any TypeSyntaxProtocol] {
        let paramMapPairs: [(String, any TypeSyntaxProtocol)] = genericParameterClause?.parameters.compactMap { param in
            if param.colon != nil, let inheritedType = param.inheritedType {
                return (param.name.trimmed.text, inheritedType)
            }
            return nil
        } ?? []
        return paramMapPairs.reduce(into: [String: any TypeSyntaxProtocol](), { $0[$1.0] = $1.1 })
    }
}

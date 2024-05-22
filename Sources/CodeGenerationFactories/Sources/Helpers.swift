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
            where: {
                $0.type.as(IdentifierTypeSyntax.self)?.name.text == "NSObjectProtocol" || $0.type.as(IdentifierTypeSyntax.self)?.name.text == "NSObject"
            }
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

    var isStatic: Bool {
        contains(where: {
            $0.name.text == TokenSyntax.keyword(.static).text
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

extension GenericArgumentClauseSyntax {
    func containsAnySameGenericParameterType(_ genericParameterClause: GenericParameterClauseSyntax) -> Bool {
        for otherParam in genericParameterClause.parameters {
            for argument in arguments {
                if let identifierType = argument.argument.as(IdentifierTypeSyntax.self) {
                    if identifierType.name.trimmed.text == otherParam.name.trimmed.text {
                        return true
                    }
                    if let innerGenericArgumentClause = identifierType.genericArgumentClause {
                        if innerGenericArgumentClause.containsAnySameGenericParameterType(genericParameterClause) {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
}

extension TypeSyntaxProtocol {
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


    var isFunctionTypeSyntax: Bool {
        underlyingFunctionTypeSyntax != nil
    }

    /// The underlying function type syntax or attributed syntax that has an underlying function type syntax.
    /// e.g. `@escaping () -> Void` or `(Int, String) -> Void`
    var underlyingFunctionTypeSyntax: FunctionTypeSyntax? {
        if let funcTypeSyntax = self.as(FunctionTypeSyntax.self) {
            return funcTypeSyntax
        }
        if let attr = self.as(AttributedTypeSyntax.self) {
            return attr.baseType.underlyingFunctionTypeSyntax
        }
        if let tuple = self.as(TupleTypeSyntax.self) {
            if tuple.elements.count == 1, let firstElement = tuple.elements.first {
                return firstElement.type.underlyingFunctionTypeSyntax
            }
            return nil
        }
        return nil
    }

    /// Erase the type if it is contained within a function's generic argument.
    /// It should follow the rules:
    /// - if generic type is within some type, then the entire type is erased, e.g. `SomeType<GenericType>`
    /// will be erased to `Any`.
    /// - If generic type inherits some other type e.g. `ModelIdentifier: Hashable>`, and
    /// the type isn't in a type's generic clause, the erasure will become `any <InheritedType>` like `any Hashable`.
    /// - within a function or tuple, only the affected type will be erased.
    func eraseTypeWithinFunctionGenerics(
        funcDecl: FunctionDeclSyntax
    ) -> any TypeSyntaxProtocol {
        eraseTypeIfContainingFunctionGenerics(
            funcDecl: funcDecl,
            matchWithinGenerics: false
        )
    }

    private func eraseTypeIfContainingFunctionGenerics(
        funcDecl: FunctionDeclSyntax,
        matchWithinGenerics: Bool
    ) -> any TypeSyntaxProtocol{
        guard let funcGenerics = funcDecl.genericParameterClause else {
            return self
        }

        if let optionalWrapped = self.as(OptionalTypeSyntax.self) {
            let type = optionalWrapped.wrappedType.eraseTypeIfContainingFunctionGenerics(
                funcDecl: funcDecl,
                matchWithinGenerics: matchWithinGenerics
            )
            if type.is(SomeOrAnyTypeSyntax.self) {
                // wrap `any <..>` with parens
                return OptionalTypeSyntax(
                    wrappedType: TupleTypeSyntax(elements: TupleTypeElementListSyntax {
                        TupleTypeElementSyntax(type: type)
                    })
                )
            }
            return OptionalTypeSyntax(
                wrappedType: type
            )
        } else if var funcType = self.as(FunctionTypeSyntax.self) {
            funcType.parameters = TupleTypeElementListSyntax {
                for param in funcType.parameters {
                    if matchWithinGenerics {
                        TupleTypeElementSyntax(
                            type: IdentifierTypeSyntax(name: .identifier("Any"))
                        )
                    } else {
                        TupleTypeElementSyntax(
                            type: param.type.eraseTypeIfContainingFunctionGenerics(
                                funcDecl: funcDecl,
                                matchWithinGenerics: matchWithinGenerics
                            )
                        )
                    }
                }
            }
            if matchWithinGenerics {
                funcType.returnClause.type = TypeSyntax(IdentifierTypeSyntax(name: .identifier("Any")))
            } else {
                let returnType = funcType.returnClause.type.eraseTypeIfContainingFunctionGenerics(
                    funcDecl: funcDecl,
                    matchWithinGenerics: matchWithinGenerics
                )
                funcType.returnClause.type = TypeSyntax(returnType)
            }
            return funcType
        } else if let tupleType = self.as(TupleTypeSyntax.self) {
            return TupleTypeSyntax(
                elements: TupleTypeElementListSyntax {
                    for element in tupleType.elements {
                        if matchWithinGenerics {
                            TupleTypeElementSyntax(
                                type: IdentifierTypeSyntax(name: .identifier("Any"))
                            )
                        } else {
                            TupleTypeElementSyntax(
                                type: element.type.eraseTypeIfContainingFunctionGenerics(
                                    funcDecl: funcDecl,
                                    matchWithinGenerics: matchWithinGenerics
                                )
                            )
                        }
                    }
                }
            )
        } else if var attributedType = self.as(AttributedTypeSyntax.self) {
            attributedType.baseType = TypeSyntax(
                attributedType.baseType.eraseTypeIfContainingFunctionGenerics(
                    funcDecl: funcDecl,
                    matchWithinGenerics: matchWithinGenerics
                )
            )
            return attributedType
        }

        guard var identifierType = self.as(IdentifierTypeSyntax.self) else {
            return self
        }

        // If type is in the function generics list, 
        // - if generics does not inherit anything, erase to Any
        // - otherwise, erase to `any <InheritedProtocol>
        if let funcGeneric = funcGenerics.parameters.first(where: { $0.name.trimmed.text == identifierType.name.trimmed.text }) {

            if matchWithinGenerics {
                return IdentifierTypeSyntax(name: .identifier("Any"))
            }

            if let funcGenericInheritedType = funcGeneric.inheritedType {
                return SomeOrAnyTypeSyntax(
                    someOrAnySpecifier: .keyword(.any).with(\.trailingTrivia, .space),
                    constraint: funcGenericInheritedType
                )
            } else {
                return IdentifierTypeSyntax(name: .identifier("Any"))
            }
        }

        // If type has generic parameter that is in the function generics list, erase to any
        if let genericClause = identifierType.genericArgumentClause {
            var genericArgumentList: GenericArgumentListSyntax = []
            for (index, argument) in genericClause.arguments.enumerated() {
                let erasedType = argument.argument.eraseTypeIfContainingFunctionGenerics(
                    funcDecl: funcDecl,
                    matchWithinGenerics: true
                )
                if erasedType.formatted().description != argument.argument.formatted().description && erasedType.formatted().description.contains(/\bAny\b/) {
                    return IdentifierTypeSyntax(name: .identifier("Any"))
                }
                genericArgumentList.append(
                    GenericArgumentSyntax(
                        argument: argument.argument.eraseTypeIfContainingFunctionGenerics(
                            funcDecl: funcDecl,
                            matchWithinGenerics: true
                        ),
                        trailingComma: index + 1 >= genericClause.arguments.count ? nil : .commaToken()
                    )
                )
            }

            identifierType.genericArgumentClause = GenericArgumentClauseSyntax(arguments: genericArgumentList)
            return identifierType
        }

        return self
    }
}

private struct TypeErasureResult {
    let type: any TypeSyntaxProtocol
    let matchWithinGenerics: Bool


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

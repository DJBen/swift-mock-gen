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

    mutating func clearScopeModifier() {
        self = filter {
            $0.name.text != TokenSyntax.keyword(.public).text ||
            $0.name.text != TokenSyntax.keyword(.private).text ||
            $0.name.text != TokenSyntax.keyword(.fileprivate).text ||
            $0.name.text != TokenSyntax.keyword(.internal).text ||
            $0.name.text != TokenSyntax.keyword(.open).text
        }
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

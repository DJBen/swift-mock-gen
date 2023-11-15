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
            $0.name.kind == TokenSyntax.keyword(.public).kind ||
            $0.name.kind == TokenSyntax.keyword(.private).kind ||
            $0.name.kind == TokenSyntax.keyword(.fileprivate).kind ||
            $0.name.kind == TokenSyntax.keyword(.internal).kind ||
            $0.name.kind == TokenSyntax.keyword(.open).kind
        })
    }

    var isPublic: Bool {
        contains(where: {
            $0.name.kind == TokenSyntax.keyword(.public).kind
        })
    }

    mutating func clearScopeModifier() {
        self = filter {
            $0.name.kind != TokenSyntax.keyword(.public).kind ||
            $0.name.kind != TokenSyntax.keyword(.private).kind ||
            $0.name.kind != TokenSyntax.keyword(.fileprivate).kind ||
            $0.name.kind != TokenSyntax.keyword(.internal).kind ||
            $0.name.kind != TokenSyntax.keyword(.open).kind
        }
    }
}

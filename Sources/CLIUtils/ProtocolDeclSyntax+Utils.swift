import SwiftSyntax

extension ProtocolDeclSyntax {
    /// All protocols to which that the current protocol conforms
    /// For example, using declaration `protocol ServiceProtocol: NSObjectProtocol, ProtocolA, ProtocolB {}`,
    /// `NSObjectProtocol`, `ProtocolA` and `ProtocolB` will be returned.
    public var conformedProtocols: [String] {
        inheritanceClause?.inheritedTypes.compactMap {
            $0.type.as(IdentifierTypeSyntax.self)?.name.text
        } ?? []
    }

    /// All protocols to which that the current protocol conforms, excluding `NSObjectProtocol`.
    /// For example, using declaration `protocol ServiceProtocol: NSObjectProtocol, ProtocolA, ProtocolB {}`,
    /// `ProtocolA` and `ProtocolB` will be returned.
    public var conformedNonNSObjectProtocols: [String] {
        conformedProtocols.filter { $0 != "NSObjectProtocol" }
    }

    /// Meld the member into another protocol declarations, keeping the syntax and formatting of another.
    ///
    /// This is especially useful in generating mocks of a protocol that inherits another.
    /// e.g. `protocol C: A, B`. We can meld `A` into `C` and `B` into `C` respectively.
    public func melding(into protocolDecl: ProtocolDeclSyntax) -> ProtocolDeclSyntax {
        ProtocolDeclSyntax(
            attributes: protocolDecl.attributes.trimmed,
            modifiers: protocolDecl.modifiers.trimmed,
            protocolKeyword: protocolDecl.protocolKeyword.trimmed,
            name: protocolDecl.name.trimmed,
            primaryAssociatedTypeClause: protocolDecl.primaryAssociatedTypeClause?.trimmed,
            inheritanceClause: protocolDecl.inheritanceClause?.trimmed,
            genericWhereClause: protocolDecl.genericWhereClause?.trimmed,
            memberBlock: MemberBlockSyntax(members: {
                var members = memberBlock.members.trimmed
                members.append(contentsOf: protocolDecl.memberBlock.members.trimmed)
                return members
            }())
        )
    }
}


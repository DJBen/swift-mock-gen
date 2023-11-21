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
                                try VariableDeclSyntax("\(raw: modifiers) let \(raw: name): \(funcParamSyntax.removingEscaping().type)")
                            }
                        }
                    }
                )
            ),
            DeclSyntax(
                try VariableDeclSyntax("private (set) var invocations_\(raw: funcUniqueName) = [Invocation_\(raw: funcUniqueName)]()")
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

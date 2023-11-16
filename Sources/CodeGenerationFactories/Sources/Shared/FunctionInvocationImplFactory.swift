import SwiftSyntax
import SwiftSyntaxBuilder

public struct FunctionInvocationImplFactory {
    public init() {}

    func decls(
        protocolDecl: ProtocolDeclSyntax,
        protocolFunctionDeclaration: FunctionDeclSyntax
    ) throws -> [DeclSyntax] {
        let modifiers = DeclModifierListSyntax {
            if let scopeModifier = protocolDecl.modifiers.scopeModifier {
                scopeModifier.trimmed
            }
        }

        let parameters = protocolFunctionDeclaration.signature.parameterClause.parameters

        return [
            DeclSyntax(
                StructDeclSyntax(
                    modifiers: modifiers,
                    name: "Invocation_\(protocolFunctionDeclaration.name)",
                    memberBlock: try MemberBlockSyntax {
                        for funcParamSyntax in parameters {
                            let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                            if funcParamSyntax.type.isFunctionTypeSyntax {
                                try VariableDeclSyntax(
                                    "\(raw: modifiers) let \(raw: name): Void"
                                )
                            } else {
                                try VariableDeclSyntax("\(raw: modifiers) let \(raw: name): \(funcParamSyntax.type)")
                            }
                        }
                    }
                )
            ),
            DeclSyntax(
                try VariableDeclSyntax("private (set) var invocations_\(protocolFunctionDeclaration.name) = [Invocation_\(protocolFunctionDeclaration.name)]()")
            )
        ]
    }
}

import SwiftSyntax
import SwiftSyntaxBuilder

public struct FunctionClassMemberImplFactory {
    public init() {}

    func declarations(
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
                    modifiers: modifiers.trimmed,
                    name: "Stub_\(protocolFunctionDeclaration.name)",
                    memberBlock: try MemberBlockSyntax {
                        for funcParamSyntax in parameters {
                            let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                            if let funcTypeSyntax = funcParamSyntax.type.underlyingFunctionTypeSyntax {
                                let count = funcTypeSyntax.parameters.count
                                if count == 0 {
                                    try VariableDeclSyntax("let \(raw: name): InvokeBlock?")
                                } else {
                                    try VariableDeclSyntax("let \(raw: name): InvokeBlock\(raw: count)<\(funcTypeSyntax.parameters.trimmed)>?")
                                }
                            } else {
                                try VariableDeclSyntax("let \(raw: name): Matching<\(funcParamSyntax.type)>")
                            }
                        }

                        if let returnClause = protocolFunctionDeclaration.signature.returnClause {
                            try VariableDeclSyntax("let returnValue: \(returnClause.type)")
                        }

                        try FunctionDeclSyntax("func matches(_ invocation: Invocation_\(protocolFunctionDeclaration.name)) -> Bool") {
                            let predicateMatches = parameters.filter {
                                !$0.type.isFunctionTypeSyntax
                            }
                            .map { param in
                                let name = (param.secondName ?? param.firstName).trimmed
                                return "\(name).predicate(invocation.\(name))"
                            }
                            .joined(separator: " && ")

                            StmtSyntax("return \(raw: predicateMatches)")
                        }
                    }
                )
            ),
            DeclSyntax(
                StructDeclSyntax(
                    modifiers: modifiers,
                    name: "Invocation_\(protocolFunctionDeclaration.name)",
                    memberBlock: try MemberBlockSyntax {
                        for funcParamSyntax in parameters {
                            let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                            if funcParamSyntax.type.isFunctionTypeSyntax {
                                try VariableDeclSyntax("let \(raw: name): Void")
                            } else {
                                try VariableDeclSyntax("let \(raw: name): \(funcParamSyntax.type)")
                            }
                        }
                    }
                )
            ),
            DeclSyntax(
                try VariableDeclSyntax("private (set) var expectations_\(protocolFunctionDeclaration.name): [(Stub_\(protocolFunctionDeclaration.name), Expectation?)] = []")
            ),
            DeclSyntax(
                try VariableDeclSyntax("private (set) var invocations_\(protocolFunctionDeclaration.name) = [Invocation_\(protocolFunctionDeclaration.name)] ()")
            )
        ]
    }
}

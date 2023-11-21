import SwiftSyntax
import SwiftSyntaxBuilder

public struct FunctionClassMemberImplFactory {
    private let functionInvocationImplFactory: FunctionInvocationImplFactory

    public init(
        functionInvocationImplFactory: FunctionInvocationImplFactory = FunctionInvocationImplFactory()
    ) {
        self.functionInvocationImplFactory = functionInvocationImplFactory
    }

    public func declarations(
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
                    modifiers: modifiers.trimmed,
                    name: "Stub_\(protocolFunctionDecl.name)",
                    memberBlock: try MemberBlockSyntax {
                        for funcParamSyntax in parameters {
                            let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                            if let funcTypeSyntax = funcParamSyntax.type.underlyingFunctionTypeSyntax {
                                let count = funcTypeSyntax.parameters.count
                                if count == 0 {
                                    try VariableDeclSyntax("let \(raw: name): ()?")
                                } else {
                                    try VariableDeclSyntax("let \(raw: name): (\(funcTypeSyntax.parameters.trimmed))?")
                                }
                            } else {
                                try VariableDeclSyntax("let \(raw: name): Matching<\(funcParamSyntax.type)>")
                            }
                        }

                        if let returnClause = protocolFunctionDecl.signature.returnClause {
                            try VariableDeclSyntax("let returnValue: \(returnClause.type)")
                        }

                        try FunctionDeclSyntax("func matches(_ invocation: Invocation_\(protocolFunctionDecl.name)) -> Bool") {
                            let nonFunctionalParams = parameters.filter {
                                !$0.type.isFunctionTypeSyntax
                            }
                            if nonFunctionalParams.isEmpty {
                                StmtSyntax("return true")
                            } else {
                                let predicateMatches = nonFunctionalParams.map { param in
                                    let name = (param.secondName ?? param.firstName).trimmed
                                    return "\(name).predicate(invocation.\(name))"
                                }
                                .joined(separator: " && ")

                                StmtSyntax("return \(raw: predicateMatches)")
                            }
                        }
                    }
                )
            ),
            DeclSyntax(
                try VariableDeclSyntax("private (set) var expectations_\(protocolFunctionDecl.name): [(Stub_\(protocolFunctionDecl.name), Expectation?)] = []")
            ),
        ] + (try functionInvocationImplFactory.decls(
            protocolDecl: protocolDecl,
            protocolFunctionDecl: protocolFunctionDecl,
            funcUniqueName: funcUniqueName
        ))
    }
}

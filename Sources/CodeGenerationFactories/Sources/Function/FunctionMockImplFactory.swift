import SwiftSyntax
import SwiftSyntaxBuilder

/// FunctionMockImplFactory designs to generate function implementations for the generated mocked class.
public struct FunctionMockImplFactory {
    public init() {}

    public func declaration(
        protocolDecl: ProtocolDeclSyntax,
        protocolFunctionDecl: FunctionDeclSyntax
    ) throws -> FunctionDeclSyntax {
        // Append scope modifier to the function (public, internal, ...)
        var modifiers = protocolFunctionDecl.modifiers.clearingScopeModifier().removingOptionalModifier()
        if let scopeModifier = protocolDecl.modifiers.scopeModifier {
            modifiers.append(scopeModifier.trimmed)
        }
        return try FunctionDeclSyntax(
            attributes: protocolFunctionDecl.attributes.trimmed,
            modifiers: modifiers.trimmed,
            funcKeyword: protocolFunctionDecl.funcKeyword.trimmed,
            name: protocolFunctionDecl.name,
            genericParameterClause: protocolFunctionDecl.genericParameterClause,
            signature: protocolFunctionDecl.signature,
            genericWhereClause: protocolFunctionDecl.genericWhereClause,
            bodyBuilder: {
                let parameters = protocolFunctionDecl.signature.parameterClause.parameters
                let expectationsVariableName = "expectations_\(protocolFunctionDecl.name)"

                let invocationInitializerParams = parameters.map { (funcParamSyntax: FunctionParameterSyntax) in
                    let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                    if funcParamSyntax.type.isFunctionTypeSyntax {
                        return "\(name): ()"
                    } else {
                        return "\(name): \(name)"
                    }
                }.joined(separator: ",\n")
                DeclSyntax("""
                let invocation = Invocation_\(protocolFunctionDecl.name)(
                \(raw: invocationInitializerParams)
                )
                """)
                ExprSyntax("invocations_\(protocolFunctionDecl.name).append(invocation)")

                let codeBlockItemListSyntax = try CodeBlockItemListSyntax {
                    let blockNamesAndParams = parameters.compactMap {
                        if let functionTypeSyntax = $0.type.underlyingFunctionTypeSyntax {
                            return (($0.secondName ?? $0.firstName).text, functionTypeSyntax)
                        } else {
                            return nil
                        }
                    }
                    for (name, funcParam) in blockNamesAndParams {
                        if funcParam.parameters.isEmpty {
                            try IfExprSyntax("if let _ = stub.\(raw: name)") {
                                ExprSyntax("\(raw: name)()")
                            }
                        } else {
                            try IfExprSyntax("if let invoke_\(raw: name) = stub.\(raw: name)") {
                                let params = (0..<funcParam.parameters.count).map {
                                    "invoke_\(name).\($0)"
                                }.joined(separator: ", ")
                                ExprSyntax("\(raw: name)(\(raw: params))")
                            }
                        }
                    }
                    if let _ = protocolFunctionDecl.signature.returnClause {
                        ReturnStmtSyntax(expression: ExprSyntax("stub.returnValue"))
                    }
                }

                try ForStmtSyntax(
                    "for (stub, _) in \(raw: expectationsVariableName).reversed()"
                ) {
                    let nonFunctionalParams = parameters.filter { !$0.type.isFunctionTypeSyntax }
                    if nonFunctionalParams.isEmpty {
                        codeBlockItemListSyntax
                    } else {
                        let ifStmtCondition: [String] = nonFunctionalParams.map { (funcParamSyntax: FunctionParameterSyntax) in
                            let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                            return "stub.\(name).predicate(\(name))"
                        }
                        try IfExprSyntax("if \(raw: ifStmtCondition.joined(separator: " && "))") {
                            codeBlockItemListSyntax
                        }
                    }
                }

                if let _ = protocolFunctionDecl.signature.returnClause {
                    // Generate a parameter list for the fatalError
                    // Invocations don't include function types, so we omit them.
                    // e.g. performRequest(request: \(request), reportId: \(reportId), includeLogs: \(includeLogs), onSuccess:…, onPermanentFailure:…)
                    let fatalErrorParams = parameters.map { (funcParamSyntax: FunctionParameterSyntax) in
                        let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                        if funcParamSyntax.type.isFunctionTypeSyntax {
                            return "\(name): …"
                        } else {
                            return "\(name): \\(\(name))"
                        }
                    }.joined(separator: ", ")

                    ExprSyntax(#"""
                    fatalError("Unexpected invocation of \#(protocolFunctionDecl.name)(\#(raw: fatalErrorParams)). Could not continue without a return value. Did you stub it?")
                    """#)
                }
            }
        )
        .with(\.leadingTrivia, [.newlines(2)])
    }
}

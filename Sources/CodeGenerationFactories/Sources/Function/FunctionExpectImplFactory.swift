import SwiftSyntax
import SwiftSyntaxBuilder

/// FunctionExpectImplFactory designs to generate expectation methods into the generated mocked class.
/// 
/// The signature is of the following format.
/// ```swift
/// expect_functionName(
///    #non-block arg#: Matching<ArgType>,
///    ...
///    #block arg#: (BlockArg1, ...)?,
///    andReturn value: #return type of func#, // only if return type is non-Void
///    expectation: Expectation?
/// )
/// ```
public struct FunctionExpectImplFactory {
    public init() {}

    func declaration(
        protocolDecl: ProtocolDeclSyntax,
        protocolFunctionDecl: FunctionDeclSyntax
    ) throws -> FunctionDeclSyntax {
        let parameters = protocolFunctionDecl.signature.parameterClause.parameters

        var functionSigParams = parameters.map { (funcParamSyntax: FunctionParameterSyntax) in
            let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
            let type = funcParamSyntax.type.trimmed
            if let funcTypeSyntax = type.underlyingFunctionTypeSyntax {
                let count = funcTypeSyntax.parameters.count
                if count == 0 {
                    return "\(name): ()?"
                } else {
                    return "\(name): (\(funcTypeSyntax.parameters.trimmed))?"
                }
            } else {
                return "\(name): Matching<\(type)>"
            }
        }
        if let returnClause = protocolFunctionDecl.signature.returnClause {
            if returnClause.type.isFunctionTypeSyntax {
                functionSigParams.append("andReturn value: @escaping \(returnClause.type.trimmed)")
            } else {
                functionSigParams.append("andReturn value: \(returnClause.type.trimmed)")
            }
        }
        functionSigParams.append("expectation: Expectation?")

        return FunctionDeclSyntax(
            attributes: [],
            modifiers: DeclModifierListSyntax {
                // Append scope modifier to the function (public, internal, ...)
                if let scopeModifier = protocolDecl.modifiers.scopeModifier {
                    scopeModifier.trimmed
                }
            },
            funcKeyword: protocolFunctionDecl.funcKeyword.trimmed,
            name: "expect_\(protocolFunctionDecl.name)",
            genericParameterClause: protocolFunctionDecl.genericParameterClause,
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax {
                        for param in functionSigParams {
                            FunctionParameterSyntax("\(raw: param)")
                        }
                    }
                )
            ),
            genericWhereClause: protocolFunctionDecl.genericWhereClause,
            bodyBuilder: {
                var params = parameters.map { (funcParamSyntax: FunctionParameterSyntax) in
                    let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                    return "\(name): \(name)"
                }
                if let _ = protocolFunctionDecl.signature.returnClause {
                    let _ = params.append("returnValue: value")
                }
                let paramString = params.joined(separator: ",\n")
                DeclSyntax(
                #"""
                let stub = Stub_\#(protocolFunctionDecl.name)(
                \#(raw: paramString)
                )
                """#
                )
                ExprSyntax(#"expectations_\#(protocolFunctionDecl.name).append((stub, expectation))"#)
            }
        )
        .with(\.leadingTrivia, [.newlines(2)])
    }
}

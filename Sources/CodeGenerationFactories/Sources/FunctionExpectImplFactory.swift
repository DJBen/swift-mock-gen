import SwiftSyntax
import SwiftSyntaxBuilder

/// FunctionExpectImplFactory designs to generate expectation methods into the generated mocked class.
/// 
/// The signature is of the following format.
/// ```swift
/// expect_functionName(
///    #non-block arg#: Matching<ArgType>,
///    ...
///    #block arg#: InvokeBlock#NumArg#<BlockArg1, ...>?,
///    andReturn value: #return type of func#, // only if return type is non-Void
///    expectation: Expectation?
/// )
/// ```
public struct FunctionExpectImplFactory {
    public init() {}

    func declaration(
        protocolDecl: ProtocolDeclSyntax,
        protocolFunctionDeclaration: FunctionDeclSyntax
    ) throws -> FunctionDeclSyntax {
        let parameters = protocolFunctionDeclaration.signature.parameterClause.parameters

        var functionSigParams = parameters.map { (funcParamSyntax: FunctionParameterSyntax) in
            let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
            let type = funcParamSyntax.type
            if let funcTypeSyntax = funcParamSyntax.type.underlyingFunctionTypeSyntax {
                let count = funcTypeSyntax.parameters.count
                if count == 0 {
                    return "\(name): InvokeBlock?"
                } else {
                    return "\(name): InvokeBlock\(count)<\(funcTypeSyntax.parameters.trimmed)>?"
                }
            } else {
                return "\(name): Matching<\(type)>"
            }
        }
        if let _ = protocolFunctionDeclaration.signature.returnClause {
            functionSigParams.append("andReturn value: String")
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
            funcKeyword: protocolFunctionDeclaration.funcKeyword.trimmed,
            name: "expect_\(protocolFunctionDeclaration.name)",
            genericParameterClause: protocolFunctionDeclaration.genericParameterClause,
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax {
                        for param in functionSigParams {
                            FunctionParameterSyntax("\(raw: param)")
                        }
                    }
                )
            ),
            genericWhereClause: protocolFunctionDeclaration.genericWhereClause,
            bodyBuilder: {
                var params = parameters.map { (funcParamSyntax: FunctionParameterSyntax) in
                    let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                    return "\(name): \(name)"
                }
                let _ = params.append("returnValue: value")
                let paramString = params.joined(separator: ",\n")
                DeclSyntax(
                #"""
                let stub = Stub_performRequest(
                \#(raw: paramString)
                )
                """#
                )
                ExprSyntax(#"expectations_performRequest.append((stub, expectation))"#)
            }
        )
        .with(\.leadingTrivia, [.newlines(2)])
    }
}

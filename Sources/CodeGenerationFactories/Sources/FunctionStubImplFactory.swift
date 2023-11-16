import SwiftSyntax
import SwiftSyntaxBuilder

/// FunctionStubImplFactory designs to generate stub methods into the generated mocked class.
/// The stub method is a shorthand of the `expect_` methods from `FunctionExpectImplFactory`, albeit without any expectations.
///
/// The signature is of the following format.
/// ```swift
/// stub_performRequest(
///    #non-block arg#: Matching<ArgType>,
///    ...
///    #block arg#: (BlockArg1, ...)?,
///    andReturn value: #return type of func#,
/// )
/// ```
public struct FunctionStubImplFactory {
    public init() {}

    func declaration(
        protocolDecl: ProtocolDeclSyntax,
        protocolFunctionDeclaration: FunctionDeclSyntax
    ) throws -> FunctionDeclSyntax {
        let parameters = protocolFunctionDeclaration.signature.parameterClause.parameters

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
        if let returnClause = protocolFunctionDeclaration.signature.returnClause {
            if returnClause.type.isFunctionTypeSyntax {
                functionSigParams.append("andReturn value: @escaping \(returnClause.type.trimmed)")
            } else {
                functionSigParams.append("andReturn value: \(returnClause.type.trimmed)")
            }
        }

        return FunctionDeclSyntax(
            attributes: [],
            modifiers: DeclModifierListSyntax {
                // Append scope modifier to the function (public, internal, ...)
                if let scopeModifier = protocolDecl.modifiers.scopeModifier {
                    scopeModifier.trimmed
                }
            },
            funcKeyword: protocolFunctionDeclaration.funcKeyword.trimmed,
            name: "stub_\(protocolFunctionDeclaration.name)",
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
                if let _ = protocolFunctionDeclaration.signature.returnClause {
                    let _ = params.append("andReturn: value")
                }
                let _ = params.append("expectation: nil")
                let paramString = params.joined(separator: ",\n")
                ExprSyntax(
                #"""
                expect_\#(raw: protocolFunctionDeclaration.name)(
                \#(raw: paramString)
                )
                """#
                )
            }
        )
        .with(\.leadingTrivia, [.newlines(2)])
    }
}
import SwiftSyntax
import SwiftSyntaxBuilder

/// FunctionVerifyImplFactory designs to generate verify methods into the generated mocked class.
///
/// The signature is of the following format.
/// ```swift
/// verify_performRequest()
/// ```
public struct FunctionVerifyImplFactory {
    public init() {}

    func declaration(
        protocolDecl: ProtocolDeclSyntax,
        protocolFunctionDeclaration: FunctionDeclSyntax
    ) throws -> FunctionDeclSyntax {
        let parameters = protocolFunctionDeclaration.signature.parameterClause.parameters

        let expecationVerifyParams = parameters.map { (funcParamSyntax: FunctionParameterSyntax) in
            let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
            if funcParamSyntax.type.isFunctionTypeSyntax {
                var syntax = funcParamSyntax.trimmed
                syntax.trailingComma = nil
                return "\(syntax)"
            } else {
                return "\(name): \\#(stub.\(name).description)"
            }
        }
        .joined(separator: ", ")


        let unexpectedInvocationParams = parameters.map { (funcParamSyntax: FunctionParameterSyntax) in
            let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
            if funcParamSyntax.type.isFunctionTypeSyntax {
                return "\(name): …"
            } else {
                return "\(name): \\(invocation.\(name))"
            }
        }
        .joined(separator: ", ")

        return FunctionDeclSyntax(
            attributes: [],
            modifiers: DeclModifierListSyntax {
                // Append scope modifier to the function (public, internal, ...)
                if let scopeModifier = protocolDecl.modifiers.scopeModifier {
                    scopeModifier.trimmed
                }
            },
            funcKeyword: protocolFunctionDeclaration.funcKeyword.trimmed,
            name: "verify_\(protocolFunctionDeclaration.name)",
            genericParameterClause: protocolFunctionDeclaration.genericParameterClause,
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax { [] }
                )
            ),
            genericWhereClause: protocolFunctionDeclaration.genericWhereClause,
            bodyBuilder: {
                DeclSyntax(#"var invocations = invocations_\#(protocolFunctionDeclaration.name)"#)

                StmtSyntax(
                ##"""
                for (stub, expectation) in expectations_\##(protocolFunctionDeclaration.name).reversed() {
                    var matchedCalls = 0
                    var index = 0
                    while index < invocations.count {
                        if stub.matches(invocations[index]) {
                            invocations.remove(at: index)
                            matchedCalls += 1
                        } else {
                            index += 1
                        }
                    }
                    expectation?.callCountPredicate.verify(
                        methodSignature:#"\##(protocolFunctionDeclaration.name)(\##(raw: expecationVerifyParams))"#,
                        callCount: matchedCalls
                    )
                }
                """##
                )

                StmtSyntax(
                #"""
                for invocation in invocations {
                    XCTFail("These invocations are made but not expected: \#(protocolFunctionDeclaration.name)(\#(raw: unexpectedInvocationParams))")
                }
                """#
                )
            }
        )
        .with(\.leadingTrivia, [.newlines(2)])
    }
}

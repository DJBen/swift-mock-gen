import SwiftSyntax
import SwiftSyntaxBuilder

public struct FunctionMockNoDepImplFactory {
    public init() {}

    public func declaration(
        protocolDecl: ProtocolDeclSyntax,
        protocolFunctionDecl: FunctionDeclSyntax,
        funcUniqueName: String
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
                let invocationInitializerParams = parameters.compactMap { (funcParamSyntax: FunctionParameterSyntax) in
                    let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                    if funcParamSyntax.type.isFunctionTypeSyntax {
                        return nil
                    } else {
                        return "\(name): \(name)"
                    }
                }.joined(separator: ",\n")
                DeclSyntax("""
                let invocation = Invocation_\(raw: funcUniqueName)(
                \(raw: invocationInitializerParams)
                )
                """)
                ExprSyntax("invocations_\(raw: funcUniqueName).append(invocation)")

                try IfExprSyntax("if let handler = handler_\(raw: funcUniqueName)") {
                    let expr: any ExprSyntaxProtocol = {
                        var expr: any ExprSyntaxProtocol = FunctionCallExprSyntax(
                            calledExpression: DeclReferenceExprSyntax(baseName: .identifier("handler")),
                            leftParen: .leftParenToken(),
                            arguments: LabeledExprListSyntax {
                                for param in parameters {
                                    let name = (param.secondName ?? param.firstName).text

                                    // If the argument type is a function type, check if any of the params
                                    // within the function has been erased.
                                    // If so, we need to force cast back to the original type.
                                    if let funcSyntax = param.type.underlyingFunctionTypeSyntax {
                                        let hasErasedType = funcSyntax.parameters.contains { funcParam in
                                            let erasedType = funcParam.type.eraseTypeWithinFunctionGenerics(funcDecl: protocolFunctionDecl)
                                            return funcParam.type.formatted().description != erasedType.formatted().description
                                        }
                                        if hasErasedType {
                                            for (index, funcParam) in funcSyntax.parameters.enumerated() {
                                                let erasedType = funcParam.type.eraseTypeWithinFunctionGenerics(funcDecl: protocolFunctionDecl)

                                                LabeledExprSyntax(
                                                    expression: ClosureExprSyntax {
                                                        FunctionCallExprSyntax(
                                                            calledExpression: DeclReferenceExprSyntax(baseName: .identifier("completion")),
                                                            leftParen: .leftParenToken(),
                                                            rightParen: .rightParenToken()
                                                        ) {
                                                            if funcParam.type.formatted().description == erasedType.formatted().description {
                                                                LabeledExprSyntax(
                                                                    expression: DeclReferenceExprSyntax(baseName: .dollarIdentifier("$\(index)"))
                                                                )
                                                            } else {
                                                                // $0 as! <Type>
                                                                LabeledExprSyntax(
                                                                    expression: SequenceExprSyntax {
                                                                        DeclReferenceExprSyntax(baseName: .dollarIdentifier("$\(index)"))

                                                                        UnresolvedAsExprSyntax(
                                                                            asKeyword: .keyword(.as),
                                                                            questionOrExclamationMark: .exclamationMarkToken()
                                                                        )

                                                                        TypeExprSyntax(type: funcParam.type)
                                                                    }
                                                                )
                                                            }

                                                        }
                                                    }
                                                )
                                            }
                                        } else {
                                            LabeledExprSyntax(
                                                expression: DeclReferenceExprSyntax(
                                                    baseName: .identifier(name)
                                                )
                                            )
                                        }
                                    } else {
                                        LabeledExprSyntax(
                                            expression: DeclReferenceExprSyntax(
                                                baseName: .identifier(name)
                                            )
                                        )
                                    }
                                }
                            },
                            rightParen: .rightParenToken()
                        )
                        if let _ = protocolFunctionDecl.signature.effectSpecifiers?.asyncSpecifier {
                            expr = AwaitExprSyntax(expression: expr)
                        }
                        if let _ = protocolFunctionDecl.signature.effectSpecifiers?.throwsSpecifier {
                            expr = TryExprSyntax(expression: expr)
                        }
                        return expr
                    }()
                    if let _ = protocolFunctionDecl.signature.returnClause {
                        ReturnStmtSyntax(expression: expr)
                    } else {
                        expr
                    }
                }
                if let _ = protocolFunctionDecl.signature.returnClause {
                    #"fatalError("Please set handler_\#(protocolFunctionDecl.name)")"#
                }
            }
        )
        .with(\.leadingTrivia, [.newlines(2)])
    }
}

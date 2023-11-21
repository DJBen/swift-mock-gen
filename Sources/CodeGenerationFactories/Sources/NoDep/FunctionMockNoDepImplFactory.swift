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
        var modifiers = protocolFunctionDecl.modifiers
        modifiers.clearScopeModifier()
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
                let invocationInitializerParams = parameters.map { (funcParamSyntax: FunctionParameterSyntax) in
                    let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                    if funcParamSyntax.type.isFunctionTypeSyntax {
                        return "\(name): ()"
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
                    let invocationParams = parameters.compactMap { (funcParamSyntax: FunctionParameterSyntax) in
                        let name = (funcParamSyntax.secondName ?? funcParamSyntax.firstName).text
                        return name
                    }.joined(separator: ", ")

                    let expr: any ExprSyntaxProtocol = {
                        var expr: any ExprSyntaxProtocol = ExprSyntax("handler(\(raw: invocationParams))")
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

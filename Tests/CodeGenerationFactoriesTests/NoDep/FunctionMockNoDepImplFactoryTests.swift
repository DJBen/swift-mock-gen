import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class FunctionMockNoDepImplFactoryTests: XCTestCase {
    func test_handler1() throws {
        let result = try FunctionMockNoDepImplFactory().declaration(
            protocolDecl: TestCases.Case2.protocolDecl,
            protocolFunctionDecl: try FunctionDeclSyntax(
                "func initialize(name: String, secondName: String?)"
            ),
            funcUniqueName: "initialize"
        )

        assertBuildResult(
            result,
            #"""


            public func initialize(name: String, secondName: String?) {
                let invocation = Invocation_initialize(
                    name: name,
                    secondName: secondName
                )
                invocations_initialize.append(invocation)
                if let handler = handler_initialize {
                    handler(name, secondName)
                }
            }
            """#
        )
    }

    func test_handler2() throws {
        let result = try FunctionMockNoDepImplFactory().declaration(
            protocolDecl: TestCases.Case2.protocolDecl,
            protocolFunctionDecl: try FunctionDeclSyntax(
                "func fetchConfig() async throws -> [String: String]"
            ),
            funcUniqueName: "fetchConfig"
        )

        assertBuildResult(
            result,
            #"""


            public func fetchConfig() async throws -> [String: String] {
                let invocation = Invocation_fetchConfig(

                )
                invocations_fetchConfig.append(invocation)
                if let handler = handler_fetchConfig {
                    return try await handler()
                }
                fatalError("Please set handler_fetchConfig")
            }
            """#
        )
    }

    func test_handler3() throws {
        let result = try FunctionMockNoDepImplFactory().declaration(
            protocolDecl: TestCases.Case2.protocolDecl,
            protocolFunctionDecl: try FunctionDeclSyntax(
                "func fetchData(_ name: (String, count: Int)) async -> (() -> Void)"
            ),
            funcUniqueName: "fetchData"
        )

        assertBuildResult(
            result,
            #"""


            public func fetchData(_ name: (String, count: Int)) async -> (() -> Void) {
                let invocation = Invocation_fetchData(
                    name: name
                )
                invocations_fetchData.append(invocation)
                if let handler = handler_fetchData {
                    return await handler(name)
                }
                fatalError("Please set handler_fetchData")
            }
            """#
        )
    }

    func test_dedupeMethodSignature() throws {
        let result = try FunctionMockNoDepImplFactory().declaration(
            protocolDecl: TestCases.Case3.protocolDecl,
            protocolFunctionDecl: try FunctionDeclSyntax(
                "func reportError(_ error: Error, description: String)"
            ),
            funcUniqueName: "reportErrorDescription"
        )

        assertBuildResult(
            result,
            #"""


            public func reportError(_ error: Error, description: String) {
                let invocation = Invocation_reportErrorDescription(
                    error: error,
                    description: description
                )
                invocations_reportErrorDescription.append(invocation)
                if let handler = handler_reportErrorDescription {
                    handler(error, description)
                }
            }
            """#
        )
    }
    
    func test_handlerNaming() throws {
        let result = try FunctionMockNoDepImplFactory().declaration(
            protocolDecl: try ProtocolDeclSyntax(
                #"""
                public protocol ServiceProtocol {
                    func doThing(handler: ()-> Void)
                }
                """#
            ),
            protocolFunctionDecl: try FunctionDeclSyntax(
                """
                func doThing(handler: ()-> Void)
                """
            ),
            funcUniqueName: "doThing"
        )

        assertBuildResult(
            result,
            #"""
            
            
            public func doThing(handler: () -> Void) {
                let invocation = Invocation_doThing(
            
                )
                invocations_doThing.append(invocation)
                if let funcHandler = handler_doThing {
                    funcHandler(handler)
                }
            }
            """#
        )
    }
}


import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class FunctionMockNoDepImplFactoryTests: XCTestCase {
    func testDeclarations() throws {
        let result = try FunctionMockNoDepImplFactory().declaration(
            protocolDecl: TestCases.Case2.protocolDecl,
            protocolFunctionDecl: try FunctionDeclSyntax(
                "func initialize(name: String, secondName: String?)"
            )
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
            )
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
            )
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
}

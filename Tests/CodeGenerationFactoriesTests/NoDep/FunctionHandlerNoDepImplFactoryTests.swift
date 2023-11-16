
import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class FunctionHandlerNoDepImplFactoryTests: XCTestCase {
    func testDeclarations() throws {
        let result = try FunctionHandlerNoDepImplFactory().declaration(
            protocolDecl: TestCases.Case2.protocolDecl,
            protocolFunctionDecl: try FunctionDeclSyntax(
                "func initialize(name: String, secondName: String?)"
            )
        )

        assertBuildResult(
            result,
            #"""


            public var handler_initialize: ((String, String?) -> Void)?
            """#
        )
    }

    func test_handler2() throws {
        let result = try FunctionHandlerNoDepImplFactory().declaration(
            protocolDecl: TestCases.Case2.protocolDecl,
            protocolFunctionDecl: try FunctionDeclSyntax(
                "func fetchConfig() async throws -> [String: String]"
            )
        )

        assertBuildResult(
            result,
            #"""


            public var handler_fetchConfig: (() async throws -> [String: String])?
            """#
        )
    }

    func test_handler3() throws {
        let result = try FunctionHandlerNoDepImplFactory().declaration(
            protocolDecl: TestCases.Case2.protocolDecl,
            protocolFunctionDecl: try FunctionDeclSyntax(
                "func fetchData(_ name: (String, count: Int)) async -> (() -> Void)"
            )
        )

        assertBuildResult(
            result,
            #"""


            public var handler_fetchData: (((String, count: Int)) async -> (() -> Void))?
            """#
        )
    }
}

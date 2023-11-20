
import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class FunctionHandlerNoDepImplFactoryTests: XCTestCase {
    func test_hander1() throws {
        let result = try FunctionHandlerNoDepImplFactory().declaration(
            protocolDecl: TestCases.Case2.protocolDecl,
            protocolFunctionDecl: try FunctionDeclSyntax(
                "func initialize(name: String, secondName: String?)"
            ),
            funcUniqueName: "initialize"
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
            ),
            funcUniqueName: "fetchConfig"
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
            ),
            funcUniqueName: "fetchData"
        )

        assertBuildResult(
            result,
            #"""


            public var handler_fetchData: (((String, count: Int)) async -> (() -> Void))?
            """#
        )
    }

    func test_dedupeMethodSignature() throws {
        let result = try FunctionHandlerNoDepImplFactory().declaration(
            protocolDecl: TestCases.Case2.protocolDecl,
            protocolFunctionDecl: try FunctionDeclSyntax(
                "func reportError(_ error: Error, description: String)"
            ),
            funcUniqueName: "reportErrorDescription"
        )

        assertBuildResult(
            result,
            #"""


            public var handler_reportErrorDescription: ((Error, String) -> Void)?
            """#
        )
    }
}

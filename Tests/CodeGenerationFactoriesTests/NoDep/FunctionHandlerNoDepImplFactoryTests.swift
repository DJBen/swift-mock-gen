
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

    func test_objcFunction_handlerShouldHaveObjc() throws {
        let result = try FunctionHandlerNoDepImplFactory().declaration(
            protocolDecl: TestCases.Case1.protocolDecl,
            protocolFunctionDecl: try FunctionDeclSyntax(
                """
                @objc
                func performRequest(
                    request: URLRequest,
                    reportId: String,
                    includeLogs: Bool,
                    onSuccess: @escaping () -> Void,
                    onPermanentFailure: @escaping (Error, String) -> Void
                ) -> String
                """
            ),
            funcUniqueName: "performRequest"
        )

        assertBuildResult(
            result,
            #"""


            @objc public var handler_performRequest: ((URLRequest, String, Bool, @escaping () -> Void, @escaping (Error, String) -> Void) -> String)?
            """#
        )
    }
    
    func test_handlerNaming() throws {
        let result = try FunctionHandlerNoDepImplFactory().declaration(
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
            
            
            public var handler_doThing: ((() -> Void) -> Void)?
            """#
        )
    }
}


import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import TestSupport

final class FunctionExpectImplFactoryTests: XCTestCase {
    func testDeclaration() throws {
        let result = try FunctionExpectImplFactory().declaration(
            protocolDecl: TestCases.Case1.protocolDecl,
            protocolFunctionDeclaration: TestCases.Case1.functionDecl
        )

        assertBuildResult(
            result,
            #"""


            public func expect_performRequest(request: Matching<URLRequest>, reportId: Matching<String>, includeLogs: Matching<Bool>, onSuccess: InvokeBlock?, onPermanentFailure: InvokeBlock2<Error, String>?, andReturn value: String, expectation: Expectation?) {
                let stub = Stub_performRequest(
                    request: request,
                    reportId: reportId,
                    includeLogs: includeLogs,
                    onSuccess: onSuccess,
                    onPermanentFailure: onPermanentFailure,
                    returnValue: value
                )
                expectations_performRequest.append((stub, expectation))
            }
            """#
        )
    }
}

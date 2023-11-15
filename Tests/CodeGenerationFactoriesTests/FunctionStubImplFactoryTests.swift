
import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import TestSupport

final class FunctionStubImplFactoryTests: XCTestCase {
    func testDeclaration() throws {
        let result = try FunctionStubImplFactory().declaration(
            protocolDecl: TestCases.Case1.protocolDecl,
            protocolFunctionDeclaration: TestCases.Case1.functionDecl
        )

        assertBuildResult(
            result,
            #"""

            
            public func stub_performRequest(request: Matching<URLRequest>, reportId: Matching<String>, includeLogs: Matching<Bool>, onSuccess: InvokeBlock?, onPermanentFailure: InvokeBlock2<Error, String>?, andReturn value: String) {
                expect_performRequest(
                    request: request,
                    reportId: reportId,
                    includeLogs: includeLogs,
                    onSuccess: onSuccess,
                    onPermanentFailure: onPermanentFailure,
                    andReturn: value,
                    expectation: nil
                )
            }
            """#
        )
    }
}

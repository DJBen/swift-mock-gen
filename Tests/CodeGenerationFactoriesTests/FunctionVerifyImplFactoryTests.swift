
import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import TestSupport

final class FunctionVerifyImplFactoryTests: XCTestCase {
    func testDeclaration() throws {
        let result = try FunctionVerifyImplFactory().declaration(
            protocolDecl: TestCases.Case1.protocolDecl,
            protocolFunctionDeclaration: TestCases.Case1.functionDecl
        )

        assertBuildResult(
            result,
            ##"""

            
            public func verify_performRequest() {
                var invocations = invocations_performRequest
                for (stub, expectation) in expectations_performRequest.reversed() {
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
                        methodSignature: #"performRequest(request: \#(stub.request.description), reportId: \#(stub.reportId.description), includeLogs: \#(stub.includeLogs.description), onSuccess: @escaping () -> Void, onPermanentFailure: @escaping (Error, String) -> Void)"#,
                        callCount: matchedCalls
                    )
                }
                for invocation in invocations {
                    XCTFail("These invocations are made but not expected: performRequest(request: \(invocation.request), reportId: \(invocation.reportId), includeLogs: \(invocation.includeLogs), onSuccess: …, onPermanentFailure: …)")
                }
            }
            """##
        )
    }
}


import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import TestSupport

final class FunctionClassMemberImplFactoryTests: XCTestCase {
    func testDeclarations() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try FunctionClassMemberImplFactory().declarations(
                protocolDecl: TestCases.Case1.protocolDecl,
                protocolFunctionDeclaration: TestCases.Case1.functionDecl
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            #"""
            public struct Stub_performRequest {
                let request: Matching<URLRequest>
                let reportId: Matching<String>
                let includeLogs: Matching<Bool>
                let onSuccess: InvokeBlock?
                let onPermanentFailure: InvokeBlock2<Error, String>?
                let returnValue: String
                func matches(_ invocation: Invocation_performRequest) -> Bool {
                    return request.predicate(invocation.request) && reportId.predicate(invocation.reportId) && includeLogs.predicate(invocation.includeLogs)
                }
            }
            public struct Invocation_performRequest {
                let request: URLRequest
                let reportId: String
                let includeLogs: Bool
                let onSuccess: Void
                let onPermanentFailure: Void
            }
            private (set) var expectations_performRequest: [(Stub_performRequest, Expectation?)] = []
            private (set) var invocations_performRequest = [Invocation_performRequest] ()
            """#
        )
    }
}

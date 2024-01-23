
import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class FunctionClassMemberImplFactoryTests: XCTestCase {
    func testDeclarations() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try FunctionClassMemberImplFactory().declarations(
                protocolDecl: TestCases.Case1.protocolDecl,
                protocolFunctionDecl: TestCases.Case1.functionDecl,
                funcUniqueName: "performRequest"
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
                let onSuccess: ()?
                let onPermanentFailure: (Error, String)?
                let returnValue: String
                func matches(_ invocation: Invocation_performRequest) -> Bool {
                    return request.predicate(invocation.request) && reportId.predicate(invocation.reportId) && includeLogs.predicate(invocation.includeLogs)
                }
            }
            private (set) var expectations_performRequest: [(Stub_performRequest, Expectation?)] = []
            public struct Invocation_performRequest {
                public let request: URLRequest
                public let reportId: String
                public let includeLogs: Bool
                public let onSuccess: Void
                public let onPermanentFailure: Void
            }
            public private (set) var invocations_performRequest = [Invocation_performRequest] ()
            """#
        )
    }

    func testDeclarations_emptyParams() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try FunctionClassMemberImplFactory().declarations(
                protocolDecl: TestCases.Case2.protocolDecl,
                protocolFunctionDecl: try! FunctionDeclSyntax(
                    #"""
                    func fetchConfig() async throws -> [String: String]
                    """#
                ),
                funcUniqueName: "fetchConfig"
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            #"""
            public struct Stub_fetchConfig {
                let returnValue: [String: String]
                func matches(_ invocation: Invocation_fetchConfig) -> Bool {
                    return true
                }
            }
            private (set) var expectations_fetchConfig: [(Stub_fetchConfig, Expectation?)] = []
            public struct Invocation_fetchConfig {
            }
            public private (set) var invocations_fetchConfig = [Invocation_fetchConfig] ()
            """#
        )
    }
}

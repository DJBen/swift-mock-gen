import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class FunctionMockImplFactoryTests: XCTestCase {
    func test_performRequest() throws {
        let result = try FunctionMockImplFactory().declaration(
            protocolDecl: TestCases.Case1.protocolDecl,
            protocolFunctionDeclaration: TestCases.Case1.functionDecl
        )

        assertBuildResult(
            result,
            #"""


            @objc public func performRequest(
                request: URLRequest,
                reportId: String,
                includeLogs: Bool,
                onSuccess: @escaping () -> Void,
                onPermanentFailure: @escaping (Error, String) -> Void
            ) -> String {
                let invocation = Invocation_performRequest(
                    request: request,
                    reportId: reportId,
                    includeLogs: includeLogs,
                    onSuccess: (),
                    onPermanentFailure: ()
                )
                invocations_performRequest.append(invocation)
                for (stub, _) in expectations_performRequest.reversed() {
                    if stub.request.predicate(request) && stub.reportId.predicate(reportId) && stub.includeLogs.predicate(includeLogs) {
                        if let _ = stub.onSuccess {
                            onSuccess()
                        }
                        if let invoke_onPermanentFailure = stub.onPermanentFailure {
                            onPermanentFailure(invoke_onPermanentFailure.0, invoke_onPermanentFailure.1)
                        }
                        return stub.returnValue
                    }
                }
                fatalError("Unexpected invocation of performRequest(request: \(request), reportId: \(reportId), includeLogs: \(includeLogs), onSuccess: …, onPermanentFailure: …). Could not continue without a return value. Did you stub it?")
            }
            """#
        )
    }

    func test_emptyParams() throws {
        let result = try FunctionMockImplFactory().declaration(
            protocolDecl: TestCases.Case2.protocolDecl,
            protocolFunctionDeclaration: try! FunctionDeclSyntax(
                #"""
                func fetchConfig() async throws -> [String: String]
                """#
            )
        )

        assertBuildResult(
            result,
            ##"""


            public func fetchConfig() async throws -> [String: String] {
                let invocation = Invocation_fetchConfig(

                )
                invocations_fetchConfig.append(invocation)
                for (stub, _) in expectations_fetchConfig.reversed() {
                    return stub.returnValue
                }
                fatalError("Unexpected invocation of fetchConfig(). Could not continue without a return value. Did you stub it?")
            }
            """##
        )
    }
}

import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import TestSupport

final class MockClassFactoryTests: XCTestCase {
    func testCase1() throws {
        let result = try MockClassFactory().classDecl(
            protocolDecl: TestCases.Case1.protocolDecl
        )

        assertBuildResult(
            result,
            ##"""
            public class SCCrashLoggerNetworkExecutorMock: NSObject, SCCrashLoggerNetworkExecuting {
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
                                onPermanentFailure(invoke_onPermanentFailure.param1, invoke_onPermanentFailure.param2)
                            }
                            return stub.returnValue
                        }
                    }
                    fatalError("Unexpected invocation of performRequest(request: \(request), reportId: \(reportId), includeLogs: \(includeLogs), onSuccess: …, onPermanentFailure: …). Could not continue without a return value. Did you stub it?")
                }

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
            }
            """##
        )
    }

    func testCase2() throws {
        let result = try MockClassFactory().classDecl(
            protocolDecl: TestCases.Case2.protocolDecl
        )

        assertBuildResult(
            result,
            ##"""
            public class ServiceMock: ServiceProtocol  {
                public init() {
                }
                public struct Stub_initialize {
                    let name: Matching<String>
                    let secondName: Matching<String?>
                    func matches(_ invocation: Invocation_initialize) -> Bool {
                        return name.predicate(invocation.name) && secondName.predicate(invocation.secondName)
                    }
                }
                public struct Invocation_initialize {
                    let name: String
                    let secondName: String?
                }
                private (set) var expectations_initialize: [(Stub_initialize, Expectation?)] = []
                private (set) var invocations_initialize = [Invocation_initialize] ()

                public func initialize(name: String, secondName: String?) {
                    let invocation = Invocation_initialize(
                        name: name,
                        secondName: secondName
                    )
                    invocations_initialize.append(invocation)
                    for (stub, _) in expectations_initialize.reversed() {
                        if stub.name.predicate(name) && stub.secondName.predicate(secondName) {
                        }
                    }
                }
            
                public func stub_initialize(name: Matching<String>, secondName: Matching<String?>) {
                    expect_initialize(
                        name: name,
                        secondName: secondName,
                        andReturn: value,
                        expectation: nil
                    )
                }
            
                public func expect_initialize(name: Matching<String>, secondName: Matching<String?>, expectation: Expectation?) {
                    let stub = Stub_initialize(
                        name: name,
                        secondName: secondName,
                        returnValue: value
                    )
                    expectations_initialize.append((stub, expectation))
                }
            
                public func verify_initialize() {
                    var invocations = invocations_initialize
                    for (stub, expectation) in expectations_initialize.reversed() {
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
                            methodSignature: #"initialize(name: \#(stub.name.description), secondName: \#(stub.secondName.description))"#,
                            callCount: matchedCalls
                        )
                    }
                    for invocation in invocations {
                        XCTFail("These invocations are made but not expected: initialize(name: \(invocation.name), secondName: \(invocation.secondName))")
                    }
                }
                public struct Stub_fetchConfig {
                    let returnValue: [String: String]
                    func matches(_ invocation: Invocation_fetchConfig) -> Bool {
                        return true
                    }
                }
                public struct Invocation_fetchConfig {
                }
                private (set) var expectations_fetchConfig: [(Stub_fetchConfig, Expectation?)] = []
                private (set) var invocations_fetchConfig = [Invocation_fetchConfig] ()
            
                public func fetchConfig() async throws -> [String: String] {
                    let invocation = Invocation_fetchConfig(
            
                    )
                    invocations_fetchConfig.append(invocation)
                    for (stub, _) in expectations_fetchConfig.reversed() {
                        return stub.returnValue
                    }
                    fatalError("Unexpected invocation of fetchConfig(). Could not continue without a return value. Did you stub it?")
                }
            
                public func stub_fetchConfig(andReturn value: String) {
                    expect_fetchConfig(
                        andReturn: value,
                        expectation: nil
                    )
                }
            
                public func expect_fetchConfig(andReturn value: String, expectation: Expectation?) {
                    let stub = Stub_fetchConfig(
                        returnValue: value
                    )
                    expectations_fetchConfig.append((stub, expectation))
                }
            
                public func verify_fetchConfig() {
                    var invocations = invocations_fetchConfig
                    for (stub, expectation) in expectations_fetchConfig.reversed() {
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
                            methodSignature: #"fetchConfig()"#,
                            callCount: matchedCalls
                        )
                    }
                    for invocation in invocations {
                        XCTFail("These invocations are made but not expected: fetchConfig()")
                    }
                }
                public struct Stub_fetchData {
                    let name: Matching<(String, count: Int)>
                    let returnValue: (() -> Void)
                    func matches(_ invocation: Invocation_fetchData) -> Bool {
                        return name.predicate(invocation.name)
                    }
                }
                public struct Invocation_fetchData {
                    let name: (String, count: Int)
                }
                private (set) var expectations_fetchData: [(Stub_fetchData, Expectation?)] = []
                private (set) var invocations_fetchData = [Invocation_fetchData] ()
            
                public func fetchData(_ name: (String, count: Int)) async -> (() -> Void) {
                    let invocation = Invocation_fetchData(
                        name: name
                    )
                    invocations_fetchData.append(invocation)
                    for (stub, _) in expectations_fetchData.reversed() {
                        if stub.name.predicate(name) {
                            return stub.returnValue
                        }
                    }
                    fatalError("Unexpected invocation of fetchData(name: \(name)). Could not continue without a return value. Did you stub it?")
                }
            
                public func stub_fetchData(name: Matching<(String, count: Int)>, andReturn value: String) {
                    expect_fetchData(
                        name: name,
                        andReturn: value,
                        expectation: nil
                    )
                }
            
                public func expect_fetchData(name: Matching<(String, count: Int)>, andReturn value: String, expectation: Expectation?) {
                    let stub = Stub_fetchData(
                        name: name,
                        returnValue: value
                    )
                    expectations_fetchData.append((stub, expectation))
                }
            
                public func verify_fetchData() {
                    var invocations = invocations_fetchData
                    for (stub, expectation) in expectations_fetchData.reversed() {
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
                            methodSignature: #"fetchData(name: \#(stub.name.description))"#,
                            callCount: matchedCalls
                        )
                    }
                    for invocation in invocations {
                        XCTFail("These invocations are made but not expected: fetchData(name: \(invocation.name))")
                    }
                }
            }
            """##
        )
    }
}

import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class MockClassFactoryTests: XCTestCase {
    func testCase1() throws {
        let result = try MockClassFactory().classDecl(
            protocolDecl: TestCases.Case1.protocolDecl
        )

        assertBuildResult(
            result,
            ##"""
            public class SCCrashLoggerNetworkExecutingMock: NSObject, SCCrashLoggerNetworkExecuting {
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

                public func stub_performRequest(request: Matching<URLRequest>, reportId: Matching<String>, includeLogs: Matching<Bool>, onSuccess: ()?, onPermanentFailure: (Error, String)?, andReturn value: String) {
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

                public func expect_performRequest(request: Matching<URLRequest>, reportId: Matching<String>, includeLogs: Matching<Bool>, onSuccess: ()?, onPermanentFailure: (Error, String)?, andReturn value: String, expectation: Expectation?) {
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

                public var name: String {
                    get {
                        getCount_name += 1
                        return underlying_name
                    }
                }
                var underlying_name: String!
                private (set) var getCount_name: Int = 0
                private (set) var setCount_name: Int = 0

                public var anyProtocol: any Codable {
                    get {
                        getCount_anyProtocol += 1
                        return underlying_anyProtocol
                    }
                    set {
                        setCount_anyProtocol += 1
                        underlying_anyProtocol = newValue
                    }
                }
                var underlying_anyProtocol: (any Codable)!
                private (set) var getCount_anyProtocol: Int = 0
                private (set) var setCount_anyProtocol: Int = 0

                public var secondName: String? {
                    get {
                        getCount_secondName += 1
                        return underlying_secondName
                    }
                }
                var underlying_secondName: String!
                private (set) var getCount_secondName: Int = 0
                private (set) var setCount_secondName: Int = 0

                public var added: () -> Void {
                    get {
                        getCount_added += 1
                        return underlying_added
                    }
                    set {
                        setCount_added += 1
                        underlying_added = newValue
                    }
                }
                var underlying_added: (() -> Void)!
                private (set) var getCount_added: Int = 0
                private (set) var setCount_added: Int = 0

                public var removed: (() -> Void)? {
                    get {
                        getCount_removed += 1
                        return underlying_removed
                    }
                    set {
                        setCount_removed += 1
                        underlying_removed = newValue
                    }
                }
                var underlying_removed: (() -> Void)!
                private (set) var getCount_removed: Int = 0
                private (set) var setCount_removed: Int = 0
                public struct Stub_initialize {
                    let name: Matching<String>
                    let secondName: Matching<String?>
                    func matches(_ invocation: Invocation_initialize) -> Bool {
                        return name.predicate(invocation.name) && secondName.predicate(invocation.secondName)
                    }
                }
                private (set) var expectations_initialize: [(Stub_initialize, Expectation?)] = []
                public struct Invocation_initialize {
                    public let name: String
                    public let secondName: String?
                }
                public private (set) var invocations_initialize = [Invocation_initialize] ()

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
                        expectation: nil
                    )
                }
            
                public func expect_initialize(name: Matching<String>, secondName: Matching<String?>, expectation: Expectation?) {
                    let stub = Stub_initialize(
                        name: name,
                        secondName: secondName
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
                private (set) var expectations_fetchConfig: [(Stub_fetchConfig, Expectation?)] = []
                public struct Invocation_fetchConfig {
                }
                public private (set) var invocations_fetchConfig = [Invocation_fetchConfig] ()
            
                public func fetchConfig() async throws -> [String: String] {
                    let invocation = Invocation_fetchConfig(
            
                    )
                    invocations_fetchConfig.append(invocation)
                    for (stub, _) in expectations_fetchConfig.reversed() {
                        return stub.returnValue
                    }
                    fatalError("Unexpected invocation of fetchConfig(). Could not continue without a return value. Did you stub it?")
                }
            
                public func stub_fetchConfig(andReturn value: [String: String]) {
                    expect_fetchConfig(
                        andReturn: value,
                        expectation: nil
                    )
                }
            
                public func expect_fetchConfig(andReturn value: [String: String], expectation: Expectation?) {
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
                private (set) var expectations_fetchData: [(Stub_fetchData, Expectation?)] = []
                public struct Invocation_fetchData {
                    public let name: (String, count: Int)
                }
                public private (set) var invocations_fetchData = [Invocation_fetchData] ()
            
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
            
                public func stub_fetchData(name: Matching<(String, count: Int)>, andReturn value: @escaping (() -> Void)) {
                    expect_fetchData(
                        name: name,
                        andReturn: value,
                        expectation: nil
                    )
                }
            
                public func expect_fetchData(name: Matching<(String, count: Int)>, andReturn value: @escaping (() -> Void), expectation: Expectation?) {
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

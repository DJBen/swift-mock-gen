import Foundation
import MockSupport
import XCTest
#if DEBUG
public class ServiceMock: NSObject, ServiceProtocol  {

    public var name: String {
        get {
            getCount_name += 1
            return underlying_name
        }
        set {
            setCount_name += 1
            underlying_name = newValue
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
        set {
            setCount_secondName += 1
            underlying_secondName = newValue
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
    public struct Stub_ffffff {
        let block: ()?
        func matches(_ invocation: Invocation_ffffff) -> Bool {
            return true
        }
    }
    public struct Invocation_ffffff {
        let block: Void
    }
    private (set) var expectations_ffffff: [(Stub_ffffff, Expectation?)] = []
    private (set) var invocations_ffffff = [Invocation_ffffff] ()

    public func ffffff(_ block: @escaping () -> Void) {
        let invocation = Invocation_ffffff(
            block: ()
        )
        invocations_ffffff.append(invocation)
        for (stub, _) in expectations_ffffff.reversed() {
            if let _ = stub.block {
                block()
            }
        }
    }

    public func stub_ffffff(block: ()?) {
        expect_ffffff(
            block: block,
            expectation: nil
        )
    }

    public func expect_ffffff(block: ()?, expectation: Expectation?) {
        let stub = Stub_ffffff(
            block: block
        )
        expectations_ffffff.append((stub, expectation))
    }

    public func verify_ffffff() {
        var invocations = invocations_ffffff
        for (stub, expectation) in expectations_ffffff.reversed() {
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
                methodSignature: #"ffffff(_ block: @escaping () -> Void)"#,
                callCount: matchedCalls
            )
        }
        for invocation in invocations {
            XCTFail("These invocations are made but not expected: ffffff(block: …)")
        }
    }
}
#endif


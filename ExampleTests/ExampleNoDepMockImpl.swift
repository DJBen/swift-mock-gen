import Foundation
#if DEBUG
public class ServiceNoDepMock: ServiceProtocol  {
    public init() {
    }

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
    public struct Invocation_initialize {
        public let name: String
        public let secondName: String?
        public let completion: Void
    }
    private (set) var invocations_initialize = [Invocation_initialize] ()

    public var handler_initialize: ((String, String?, @escaping (Error?) -> Void) -> Void)?

    public func initialize(name: String, secondName: String?, completion: @escaping (Error?) -> Void) {
        let invocation = Invocation_initialize(
            name: name,
            secondName: secondName,
            completion: ()
        )
        invocations_initialize.append(invocation)
        if let handler = handler_initialize {
            handler(name, secondName, completion)
        }
    }
    public struct Invocation_fetchConfig {
    }
    private (set) var invocations_fetchConfig = [Invocation_fetchConfig] ()

    public var handler_fetchConfig: (() async throws -> [String: String])?

    public func fetchConfig() async throws -> [String: String] {
        let invocation = Invocation_fetchConfig(

        )
        invocations_fetchConfig.append(invocation)
        if let handler = handler_fetchConfig {
            return try await handler()
        }
        fatalError("Please set handler_fetchConfig")
    }
    public struct Invocation_fetchData {
        public let name: (String, count: Int)
    }
    private (set) var invocations_fetchData = [Invocation_fetchData] ()

    public var handler_fetchData: (((String, count: Int)) async -> (() -> Void))?

    public func fetchData(_ name: (String, count: Int)) async -> (() -> Void) {
        let invocation = Invocation_fetchData(
            name: name
        )
        invocations_fetchData.append(invocation)
        if let handler = handler_fetchData {
            return await handler(name)
        }
        fatalError("Please set handler_fetchData")
    }
}
#endif


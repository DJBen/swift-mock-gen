import Foundation

// Consider replace this with #Predicate for iOS 17+ only.

public struct Matching<Param> {
    let predicate: (Param?) -> Bool
    let description: String

    public init(_ predicate: @escaping (Param?) -> Bool, description: String? = nil) {
        self.predicate = predicate
        self.description = description ?? "<predicate>"
    }

    public func matches(_ value: Param) -> Bool {
        predicate(value)
    }
}

extension Matching {
    public static func any() -> Matching {
        Matching({ _ in true }, description: "<any>")
    }

    public static func isNil() -> Matching {
        Matching({ $0 == nil }, description: "<any>")
    }
}

extension Matching: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init({ $0 == nil })
    }
}

extension Matching: ExpressibleByFloatLiteral where Param == Float {
    public init(floatLiteral value: Float) {
        self.init({ $0 == value })
    }
}

extension Matching: ExpressibleByStringLiteral, ExpressibleByUnicodeScalarLiteral, ExpressibleByExtendedGraphemeClusterLiteral where Param == String {
    public init(stringLiteral value: String) {
        self.init({ $0 == value })
    }

    public init(unicodeScalarLiteral value: String) {
        self.init({ $0 == value })
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init({ $0 == value })
    }
}

extension Matching: ExpressibleByBooleanLiteral where Param == Bool {
    public init(booleanLiteral value: Bool) {
        self.init({ $0 == value })
    }
}

extension Matching: ExpressibleByIntegerLiteral where Param == Int {
    public init(integerLiteral value: Int) {
        self.init({ $0 == value })
    }
}

extension Matching where Param: Equatable {
    public static func eq(_ otherParam: Param) -> Matching {
        Matching({ $0 == otherParam }, description: "==\(otherParam)")
    }
}

extension Matching where Param == URLRequest {
    public static func url(_ url: URL) -> Matching {
        Matching({ $0?.url == url }, description: "==\(url)")
    }
}

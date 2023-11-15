import Foundation
import XCTest

public struct Expectation {
    public enum CallCountPredicate: Equatable, ExpressibleByIntegerLiteral {
        case any
        case exact(Int)
        case gt(Int)
        case gte(Int)
        case lt(Int)
        case lte(Int)
        case range(ClosedRange<Int>)

        public init(integerLiteral value: Int) {
            self = .exact(value)
        }

        func matches(_ callCount: Int) -> Bool {
            switch self {
            case .any:
                return true
            case .exact(let count):
                return callCount == count
            case .gt(let count):
                return callCount > count
            case .gte(let count):
                return callCount >= count
            case .lt(let count):
                return callCount < count
            case .lte(let count):
                return callCount <= count
            case .range(let range):
                return range.contains(callCount)
            }
        }

        func verify(methodSignature: String, callCount: Int) {
            if !matches(callCount) {
                let message = violationDescription(
                    methodSignature: methodSignature,
                    actualCall: callCount
                )
                XCTFail(message)
            }
        }

        private func violationDescription(methodSignature: String, actualCall: Int) -> String {
            switch self {
            case .any:
                return "Any number of calls are expected, but \(actualCall) calls are made for \(methodSignature)."
            case .exact(let count):
                return "Exactly \(count) calls are expected, but \(actualCall) calls are made for \(methodSignature)."
            case .gt(let count):
                return "More than \(count) calls are expected, but \(actualCall) calls are made for \(methodSignature)."
            case .gte(let count):
                return "\(count) or more calls are expected, but \(actualCall) calls are made for \(methodSignature)."
            case .lt(let count):
                return "Less than \(count) calls are expected, but \(actualCall) calls are made for \(methodSignature)."
            case .lte(let count):
                return "\(count) or fewer calls are expected, but \(actualCall) calls are made for \(methodSignature)."
            case .range(let range):
                return "Between \(range.lowerBound) and \(range.upperBound) calls are expected, but \(actualCall) calls are made for \(methodSignature)."
            }
        }
    }

    let callCountPredicate: CallCountPredicate

    public static func count(_ predicate: CallCountPredicate) -> Expectation {
        Expectation(callCountPredicate: predicate)
    }
 }

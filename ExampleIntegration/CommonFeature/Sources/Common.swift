import Foundation

public protocol Common: Identifiable where ID == String {
    func common() -> Int
}
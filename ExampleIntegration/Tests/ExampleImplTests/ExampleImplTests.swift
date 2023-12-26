import XCTest
import Example
@testable import ExampleImpl

final class ExampleImplTests: XCTestCase {
    func testExample() throws {
        XCTAssertEqual(ExampleImpl().helloWorld(), "Hello world")
    }
}

import XCTest
import Example
@testable import ExampleImpl

// ExampleMock is a generated target consisting of all the mock impls of the protocols from the `Example` target.
import ExampleMock

final class ExampleImplTests: XCTestCase {
    struct TestClass {
        let example: Example

        func greetings() -> String {
            return "This is a greeting: \(example.helloWorld())"
        }
    }

    func testExample() throws {
        XCTAssertEqual(ExampleImpl().helloWorld(), "Hello world")
    }

    func testDemoExampleMock() throws {
        let example = ExampleMock()
        example.handler_helloWorld = {
            return "Mocked!"
        }
        let testClassInstance = TestClass(example: example)
        XCTAssertEqual(testClassInstance.greetings(), "This is a greeting: Mocked!")
    }
}

import XCTest
import Example
@testable import OtherImpl

// ExampleMock is a generated target consisting of all the mock impls of the protocols from the `Example` target.
import ExampleForAlphaMock

final class OtherImplTests: XCTestCase {
    func testOtherImpl() throws {
        let example = ExampleMock()
        example.handler_helloWorld = {
            return "Mocked!"
        }
        let otherImplInstance = OtherImpl(example: example)
        XCTAssertEqual(otherImplInstance.yell(), "Mocked!")
    }
}

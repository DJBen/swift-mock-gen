import XCTest
import MockSupport

class TestedClass {
    let executor: ServiceProtocol

    init(executor: ServiceProtocol) {
        self.executor = executor
    }

    func fetchData(
    ) async -> (() -> Void) {
        return await executor.fetchData(("", 1))
    }

    func processName() {
        print("\(executor.name) \(executor.secondName)")
    }
}

final class ExampleTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNoDepMock() async throws {
        let mock = ServiceNoDepMock()
        let container = TestedClass(executor: mock)

        mock.underlying_name = "Name 1"
        mock.underlying_secondName = "Name 2"
        container.processName()

        XCTAssertEqual(mock.getCount_secondName, 1)

        mock.handler_fetchData = { name in
            return {}
        }

        let _ = await container.fetchData()
        let invocation = try XCTUnwrap(mock.invocations_fetchData.first)
        XCTAssertEqual(invocation.name.0, "")
        XCTAssertEqual(invocation.name.1, 1)
    }
}

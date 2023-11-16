// Copyright © 2023 Snap, Inc. All rights reserved.

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

    func testExample() async throws {
        let mock = ServiceMock()
        let container = TestedClass(executor: mock)

        mock.expect_fetchData(
            name: Matching({ _ in
                return true
            }),
            andReturn: {},
            expectation: .count(1)
        )

        let _ = await container.fetchData()

        mock.verify_fetchData()
    }

    func testExample2() async throws {
        let mock = ServiceMock()
        let container = TestedClass(executor: mock)

        mock.underlying_name = "Name 1"
        mock.underlying_secondName = "Name 2"
        container.processName()

        XCTAssertEqual(mock.getCount_secondName, 1)
    }
}

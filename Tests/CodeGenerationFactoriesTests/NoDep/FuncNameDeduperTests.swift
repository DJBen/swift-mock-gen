import XCTest
@testable import CodeGenerationFactories

final class FuncNameDeduperTests: XCTestCase {
    func testDeduper() throws {
        let deduper = FuncNameDeduper(
            protocolDecl: TestCases.Case3.protocolDecl,
            funcDecls: TestCases.Case3.funcDecls
        )

        // func reportError(_ error: Error)
        let func1 = TestCases.Case3.funcDecls[0]
        XCTAssertEqual(deduper.name(for: func1), "reportError")

        // func reportError(_ error: Error, description: String)
        let func2 = TestCases.Case3.funcDecls[1]
        XCTAssertEqual(deduper.name(for: func2), "reportErrorDescription")

        // func reportError(_ error: Error, metadata: [String: Any]?)
        let func3 = TestCases.Case3.funcDecls[2]
        XCTAssertEqual(deduper.name(for: func3), "reportErrorMetadata")

        // func reportError(_ error: Error, metadata: [String: Any]?, completion: @escaping () -> Void)
        let func4 = TestCases.Case3.funcDecls[3]
        XCTAssertEqual(deduper.name(for: func4), "reportErrorMetadataCompletion")
    }

    func testDeduper_case2() throws {
        let deduper = FuncNameDeduper(
            protocolDecl: TestCases.Case1.protocolDecl,
            funcDecls: [TestCases.Case1.functionDecl]
        )

        let func1 = TestCases.Case1.functionDecl
        XCTAssertEqual(deduper.name(for: func1), "performRequest")
    }
}

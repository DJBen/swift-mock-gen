import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class NoDepSourceFactoryTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func test_onlyGenerateForPublicProtocols() throws {
        let result = try NoDepSourceFactory().decls(
            protocolDecl: try! ProtocolDeclSyntax(#"""
            protocol P: P1 {
                func p1()
            }
            """#),
            surroundWithPoundIfDebug: false,
            excludeProtocols: [],
            importDeclsToCopy: [],
            customGenericTypes: [:],
            onlyGenerateForPublicProtocols: true,
            verbose: false
        )
        XCTAssertEqual(result, [])
    }
}

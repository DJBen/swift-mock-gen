import XCTest
import SwiftSyntax
@testable import CodeGenerationFactories

final class FuncNameDeduperTests: XCTestCase {
    func testDeduper() throws {
        let deduper = FuncNameDeduper(
            protocolDecl: TestCases.Case3.protocolDecl,
            funcDecls: TestCases.Case3.funcDecls
        )

        // func reportError(_ error: Error)
        let func1 = TestCases.Case3.funcDecls[0]
        XCTAssertEqual(deduper.name(for: func1), "reportErrorError")

        // func reportError(_ error: Error, description: String)
        let func2 = TestCases.Case3.funcDecls[1]
        XCTAssertEqual(deduper.name(for: func2), "reportErrorErrorDescription")

        // func reportError(_ error: Error, metadata: [String: Any]?)
        let func3 = TestCases.Case3.funcDecls[2]
        XCTAssertEqual(deduper.name(for: func3), "reportErrorErrorMetadata")

        // func reportError(_ error: Error, metadata: [String: Any]?, completion: @escaping () -> Void)
        let func4 = TestCases.Case3.funcDecls[3]
        XCTAssertEqual(deduper.name(for: func4), "reportErrorErrorMetadataCompletion")
    }

    func testDeduper_case2() throws {
        let deduper = FuncNameDeduper(
            protocolDecl: TestCases.Case1.protocolDecl,
            funcDecls: [TestCases.Case1.functionDecl]
        )

        let func1 = TestCases.Case1.functionDecl
        XCTAssertEqual(deduper.name(for: func1), "performRequest")
    }
    
    func testDeduper_secondName() throws {
        let func1 = try! FunctionDeclSyntax(
            #"""
            func createDoc(
                from image: UIImage,
                creationDate: Date
            ) -> Future<Document>
            """#
        )
        let func2 = try! FunctionDeclSyntax(
            #"""
            func createDoc(
                from video: AVAsset,
                creationDate: Date
            ) -> Future<Document>
            """#
        )
        
        let protocolDecl = try! ProtocolDeclSyntax(
        #"""
        @objc
        public protocol DocumentCreator: NSObjectProtocol {
            func createDoc(
                from image: UIImage,
                creationDate: Date
            ) -> Future<Document>
        
            func createDoc(
                from video: AVAsset,
                creationDate: Date
            ) -> Future<Document>
        }
        """#
        )

        let deduper = FuncNameDeduper(
            protocolDecl: protocolDecl,
            funcDecls: [func1, func2]
        )

        XCTAssertEqual(
            deduper.name(for: func1),
            "createDocImage"
        )
        
        XCTAssertEqual(
            deduper.name(for: func2),
            "createDocVideo"
        )
    }

    func testDeduper_wildcard() throws {
        let func1 = try! FunctionDeclSyntax(
            #"""
            func log(_ error: SomeError)
            """#
        )

        let func2 = try! FunctionDeclSyntax(
            #"""
            func log(_ checkpoint: SomeCheckpoint)
            """#
        )

        let protocolDecl = try! ProtocolDeclSyntax(
        #"""
        @objc
        public protocol Logger: NSObjectProtocol {
            func log(_ error: SomeError)
            func log(_ checkpoint: SomeCheckpoint)
        }
        """#
        )

        let deduper = FuncNameDeduper(
            protocolDecl: protocolDecl,
            funcDecls: [func1, func2]
        )

        XCTAssertEqual(
            deduper.name(for: func1),
            "logError"
        )

        XCTAssertEqual(
            deduper.name(for: func2),
            "logCheckpoint"
        )
    }
    
    func testDeduper_wildcard2() throws {
        let func1 = try! FunctionDeclSyntax(
            #"""
            func set(_ anObject: Any?, forKey aKey: String)
            """#
        )

        let func2 = try! FunctionDeclSyntax(
            #"""
            func set(_ value: Bool, forKey aKey: String)
            """#
        )
        
        let func3 = try! FunctionDeclSyntax(
            #"""
            func set(_ aData: Data?, forKey aKey: String)
            """#
        )
        
        let func4 = try! FunctionDeclSyntax(
            #"""
            func set(_ aDictionary: [String: Any]?, forKey aKey: String)
            """#
        )
        
        let func5 = try! FunctionDeclSyntax(
            #"""
            func set(_ value: Double, forKey aKey: String)
            """#
        )

        let protocolDecl = try! ProtocolDeclSyntax(
        #"""
        public protocol KVStore {
            func set(_ anObject: Any?, forKey aKey: String)
            func set(_ value: Bool, forKey aKey: String)
            func set(_ aData: Data?, forKey aKey: String)
            func set(_ aDictionary: [String: Any]?, forKey aKey: String)
            func set(_ value: Double, forKey aKey: String)
        }
        """#
        )

        let deduper = FuncNameDeduper(
            protocolDecl: protocolDecl,
            funcDecls: [func1, func2, func3, func4, func5]
        )

        XCTAssertEqual(
            deduper.name(for: func1),
            "setAnObject"
        )

        XCTAssertEqual(
            deduper.name(for: func2),
            "setValue"
        )
        
        XCTAssertEqual(
            deduper.name(for: func3),
            "setAData"
        )
        
        XCTAssertEqual(
            deduper.name(for: func4),
            "setADictionary"
        )
        
        XCTAssertEqual(
            deduper.name(for: func5),
            "setValue1"
        )
    }
}

//
//  ProtocolDepResolverTests.swift
//  
//
//  Created by Sihao Lu on 12/19/23.
//

import XCTest
@testable import CLIUtils
import SwiftSyntax
import SwiftSyntaxBuilder

final class ProtocolDepResolverTests: XCTestCase {

    let protocol1 = try! ProtocolDeclSyntax(#"""
    protocol P1: NSObjectProtocol, P2, P3 {
        func p1()
    }
    """#)

    let protocol2 = try! ProtocolDeclSyntax(#"""
    protocol P2: P4 {
        func p2()
    }
    """#)

    let protocol3 = try! ProtocolDeclSyntax(#"""
    protocol P3 {
        func p3()
    }
    """#)

    let protocol4 = try! ProtocolDeclSyntax(#"""
    protocol P4 {
        func p4()
    }
    """#)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMergeImports() throws {
        let p2 = ProtocolDeclResult(
            decl: protocol2,
            imports: [
                try ImportDeclSyntax("import Foo"),
                try ImportDeclSyntax("import Bar"),
            ],
            fileName: nil
        )
        let p1 = ProtocolDeclResult(
            decl: protocol1,
            imports: [
                try ImportDeclSyntax("import Bar"),
                try ImportDeclSyntax("import Baz"),
            ],
            fileName: nil
        )
        let result = p2.melding(into: p1)
        let expected = try! ProtocolDeclSyntax(#"""
        protocol P1: NSObjectProtocol, P2, P3 {
            func p2()
            func p1()
        }
        """#)
        XCTAssertEqual(
            result.decl.formatted().description,
            expected.formatted().description
        )
        XCTAssertEqual(
            result.imports.map { $0.trimmed.formatted().description },
            [
                "import Bar",
                "import Baz",
                "import Foo",
            ]
        )
    }

    func testMergeProtocols() throws {
        let resolver = ProtocolDepResolver(
            fileIteratorProvider: { fatalError() }
        )
        var protocols: [String: ProtocolDeclResult] = [
            "P1": ProtocolDeclResult(protocol1),
            "P2": ProtocolDeclResult(protocol2),
            "P3": ProtocolDeclResult(protocol3),
            "P4": ProtocolDeclResult(protocol4)
        ]
        let sortedDeps = try resolver.mergeProtocols(
            [
                ProtocolDeps(
                    name: "P1",
                    deps: ["P2", "P3"]
                ),
                ProtocolDeps(
                    name: "P2",
                    deps: ["P4"]
                ),
                ProtocolDeps(
                    name: "P3",
                    deps: []
                ),
                ProtocolDeps(
                    name: "P4",
                    deps: []
                )
            ],
            protocols: &protocols
        )
        XCTAssertEqual(
            sortedDeps,
            [
                ProtocolDeps(
                    name: "P3",
                    deps: []
                ),
                ProtocolDeps(
                    name: "P4",
                    deps: []
                ),
                ProtocolDeps(
                    name: "P2",
                    deps: ["P4"]
                ),
                ProtocolDeps(
                    name: "P1",
                    deps: ["P2", "P3"]
                )
            ]
        )
        let expectedP2 = try! ProtocolDeclSyntax(#"""
        protocol P2: P4 {
            func p4()
            func p2()
        }
        """#)
        XCTAssertEqual(
            protocols["P2"]!.decl.formatted().description,
            expectedP2.formatted().description
        )

        let expectedP1 = try! ProtocolDeclSyntax(#"""
        protocol P1: NSObjectProtocol, P2, P3 {
            func p4()
            func p2()
            func p3()
            func p1()
        }
        """#)
        XCTAssertEqual(protocols["P1"]!.decl.formatted().description, expectedP1.formatted().description)
        XCTAssertEqual(protocols["P3"]!.decl.formatted().description, protocol3.formatted().description)
        XCTAssertEqual(protocols["P4"]!.decl.formatted().description, protocol4.formatted().description)
    }

    func testMergeProtocols_NSObjectProtocol() throws {
        let resolver = ProtocolDepResolver(
            fileIteratorProvider: { fatalError() }
        )
        var protocols: [String: ProtocolDeclResult] = [
            "P2": ProtocolDeclResult(
                try! ProtocolDeclSyntax(
                #"""
                protocol P2: P3 {
                    func p2()
                }
                """#
               )
            ),
            "P1": ProtocolDeclResult(
                try! ProtocolDeclSyntax(
                #"""
                protocol P1: P2 {
                    func p1()
                }
                """#
               )
            ),
            "P3": ProtocolDeclResult(
                try! ProtocolDeclSyntax(
                #"""
                protocol P3: NSObjectProtocol, P4 {
                    func p3()
                }
                """#
               )
            )
        ]
        let sortedDeps = try resolver.mergeProtocols(
            [
                ProtocolDeps(
                    name: "P2",
                    deps: ["P3"]
                ),
                ProtocolDeps(
                    name: "P1",
                    deps: ["P2"]
                ),
                ProtocolDeps(
                    name: "P3",
                    deps: []
                )
            ],
            protocols: &protocols
        )
        XCTAssertEqual(
            sortedDeps,
            [
                ProtocolDeps(
                    name: "P3",
                    deps: []
                ),
                ProtocolDeps(
                    name: "P2",
                    deps: ["P3"]
                ),
                ProtocolDeps(
                    name: "P1",
                    deps: ["P2"]
                ),
            ]
        )
        let expectedP2 = try! ProtocolDeclSyntax(#"""
        protocol P2: NSObjectProtocol, P3 {
            func p3()
            func p2()
        }
        """#)
        XCTAssertEqual(
            protocols["P2"]!.decl.formatted().description,
            expectedP2.formatted().description
        )

        let expectedP1 = try! ProtocolDeclSyntax(#"""
        protocol P1: NSObjectProtocol, P2 {
            func p3()
            func p2()
            func p1()
        }
        """#)
        XCTAssertEqual(protocols["P1"]!.decl.formatted().description, expectedP1.formatted().description)
    }
}

extension ProtocolDeclResult {
    init(_ decl: ProtocolDeclSyntax) {
        self.init(decl: decl, imports: [], fileName: "")
    }
}

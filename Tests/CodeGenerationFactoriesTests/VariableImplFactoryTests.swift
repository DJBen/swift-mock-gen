
import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class VariableImplFactoryTests: XCTestCase {
    func testGeneration_var1() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try VariableImplFactory().decls(
                protocolDecl: TestCases.Case2.protocolDecl,
                protocolVariableDecl: TestCases.Case2.varDecl1
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            ##"""


            public var name: String {
                get {
                    getCount_name += 1
                    return underlying_name
                }
            }
            var underlying_name: String!
            private (set) var getCount_name: Int = 0
            private (set) var setCount_name: Int = 0
            """##
        )
    }

    func testGeneration_var2() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try VariableImplFactory().decls(
                protocolDecl: TestCases.Case2.protocolDecl,
                protocolVariableDecl: TestCases.Case2.varDecl2
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }
        
        assertBuildResult(
            result,
            ##"""


            public var removed: (() -> Void)? {
                get {
                    getCount_removed += 1
                    return underlying_removed
                }
                set {
                    setCount_removed += 1
                    underlying_removed = newValue
                }
            }
            var underlying_removed: (() -> Void)!
            private (set) var getCount_removed: Int = 0
            private (set) var setCount_removed: Int = 0
            """##
        )
    }

    func testGeneration_objcProtocol() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try VariableImplFactory().decls(
                protocolDecl: try! ProtocolDeclSyntax(#"""
                public protocol ObjcProtocol: NSObjectProtocol {
                    @objc var param: Int { get }
                }
                """#),
                protocolVariableDecl: try! VariableDeclSyntax(#"""
                @objc var param: Int { get }
                """#)
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            ##"""


            @objc public var param: Int {
                get {
                    getCount_param += 1
                    return underlying_param
                }
            }
            var underlying_param: Int!
            private (set) var getCount_param: Int = 0
            private (set) var setCount_param: Int = 0
            """##
        )
    }
}

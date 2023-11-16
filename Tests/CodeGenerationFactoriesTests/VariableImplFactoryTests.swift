
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
                set {
                    setCount_name += 1
                    underlying_name = newValue
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
}

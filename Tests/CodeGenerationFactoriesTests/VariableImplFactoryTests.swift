
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
            public var underlying_name: String!
            public private (set) var getCount_name: Int = 0
            public private (set) var setCount_name: Int = 0
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
            public var underlying_removed: (() -> Void)!
            public private (set) var getCount_removed: Int = 0
            public private (set) var setCount_removed: Int = 0
            """##
        )
    }

    func testGeneration_objcProtocol_objcVariableShouldAnnotateWithAtObjc() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try VariableImplFactory().decls(
                protocolDecl: try! ProtocolDeclSyntax(#"""
                public protocol ObjcProtocol: NSObjectProtocol {
                    @objc var param: NSNumber { get }
                }
                """#),
                protocolVariableDecl: try! VariableDeclSyntax(#"""
                @objc var param: NSNumber { get }
                """#)
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            ##"""


            @objc public var param: NSNumber {
                get {
                    getCount_param += 1
                    return underlying_param
                }
            }
            public var underlying_param: NSNumber!
            public private (set) var getCount_param: Int = 0
            public private (set) var setCount_param: Int = 0
            """##
        )
    }

    func testGeneration_objcProtocol_nonObjcVariableShouldNotAnnotateWithAtObjc() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try VariableImplFactory().decls(
                protocolDecl: try! ProtocolDeclSyntax(#"""
                public protocol ObjcProtocol: NSObjectProtocol {
                    var param: Int { get }
                }
                """#),
                protocolVariableDecl: try! VariableDeclSyntax(#"""
                var param: Int { get }
                """#)
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            ##"""


            public var param: Int {
                get {
                    getCount_param += 1
                    return underlying_param
                }
            }
            public var underlying_param: Int!
            public private (set) var getCount_param: Int = 0
            public private (set) var setCount_param: Int = 0
            """##
        )
    }

    func testGeneration_weakVar_shouldSythesizeOptionalVariable() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try VariableImplFactory().decls(
                protocolDecl: try! ProtocolDeclSyntax(#"""
                @objc public protocol SomeProtocol {
                    weak var delegate: SomeDelegate? { get set }
                }
                """#),
                protocolVariableDecl: try! VariableDeclSyntax(#"""
                weak var delegate: SomeDelegate? { get set }
                """#)
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            ##"""


            public var delegate: SomeDelegate? {
                get {
                    getCount_delegate += 1
                    return underlying_delegate
                }
                set {
                    setCount_delegate += 1
                    underlying_delegate = newValue
                }
            }
            public var underlying_delegate: SomeDelegate!
            public private (set) var getCount_delegate: Int = 0
            public private (set) var setCount_delegate: Int = 0
            """##
        )

        let result2 = try MemberBlockItemListSyntax {
            for member in try VariableImplFactory().decls(
                protocolDecl: try! ProtocolDeclSyntax(#"""
                @objc public protocol SomeProtocol {
                    weak var delegate: (Delegate1 & Delegate2 & Delegate3)? { get set }
                }
                """#),
                protocolVariableDecl: try! VariableDeclSyntax(#"""
                weak var delegate: (Delegate1 & Delegate2 & Delegate3)? { get set }
                """#)
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result2,
            ##"""


            public var delegate: (Delegate1 & Delegate2 & Delegate3)? {
                get {
                    getCount_delegate += 1
                    return underlying_delegate
                }
                set {
                    setCount_delegate += 1
                    underlying_delegate = newValue
                }
            }
            public var underlying_delegate: (Delegate1 & Delegate2 & Delegate3)!
            public private (set) var getCount_delegate: Int = 0
            public private (set) var setCount_delegate: Int = 0
            """##
        )
    }

    func testGeneration_staticVariable() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try VariableImplFactory().decls(
                protocolDecl: try! ProtocolDeclSyntax(#"""
                @objc public protocol SomeProtocol {
                    static var global: SomeProtocol? { get }
                }
                """#),
                protocolVariableDecl: try! VariableDeclSyntax(#"""
                static var global: SomeProtocol? { get }
                """#)
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            ##"""


            static public var global: SomeProtocol? {
                get {
                    getCount_global += 1
                    return underlying_global
                }
            }
            static public var underlying_global: SomeProtocol!
            static public private (set) var getCount_global: Int = 0
            static public private (set) var setCount_global: Int = 0
            """##
        )
    }
}

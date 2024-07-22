
import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class FunctionInvocationImplFactoryTests: XCTestCase {
    func test_handler1() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try FunctionInvocationImplFactory().decls(
                protocolDecl: TestCases.Case2.protocolDecl,
                protocolFunctionDecl: try FunctionDeclSyntax(
                    "func initialize(name: String, secondName: String?, completion: @escaping (Error?) -> Void)"
                ),
                funcUniqueName: "initialize"
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            #"""
            public struct Invocation_initialize {
                public let name: String
                public let secondName: String?
            }
            public private (set) var invocations_initialize = [Invocation_initialize] ()
            """#
        )
    }

    func test_handler2() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try FunctionInvocationImplFactory().decls(
                protocolDecl: TestCases.Case2.protocolDecl,
                protocolFunctionDecl: try FunctionDeclSyntax(
                    "func initialize(name: String, secondName: String?, completion: @escaping SomeBlock)"
                ),
                funcUniqueName: "initialize"
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            #"""
            public struct Invocation_initialize {
                public let name: String
                public let secondName: String?
                public let completion: SomeBlock
            }
            public private (set) var invocations_initialize = [Invocation_initialize] ()
            """#
        )
    }

    func test_static() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try FunctionInvocationImplFactory().decls(
                protocolDecl: TestCases.Case2.protocolDecl,
                protocolFunctionDecl: try FunctionDeclSyntax(
                    "static func shared() -> ConfigHeuristicRecoveryManager"
                ),
                funcUniqueName: "shared"
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            #"""
            public struct Invocation_shared {
            }
            static public private (set) var invocations_shared = [Invocation_shared] ()
            """#
        )
    }
    
    func test_handlerNaming() throws {
        let result = try MemberBlockItemListSyntax {
            for member in try FunctionInvocationImplFactory().decls(
                protocolDecl: try ProtocolDeclSyntax(
                #"""
                public protocol ServiceProtocol {
                    func doThing(handler: ()-> Void)
                }
                """#
                ),
                protocolFunctionDecl: try FunctionDeclSyntax(
                    "func doThing(handler: ()-> Void)"
                ),
                funcUniqueName: "doThing"
            ) {
                MemberBlockItemSyntax(decl: member)
            }
        }

        assertBuildResult(
            result,
            #"""
            public struct Invocation_doThing {
            }
            public private (set) var invocations_doThing = [Invocation_doThing] ()
            """#
        )
        
    }
}

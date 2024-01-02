// Copyright © 2024 Snap, Inc. All rights reserved.

import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class NoDepMockClassFactoryTests: XCTestCase {
    // In this case, the associatedtype declares an equation.
    func testGenerics_equation() throws {
        let result = try NoDepMockClassFactory().classDecl(
            protocolDecl: try! ProtocolDeclSyntax(
            #"""
            public protocol UserGenerating<UserID> {
                associatedtype UserID = UserIDProtocol

                func generateUserIdentifier() -> UserID
            }
            """#
            )
        )

        assertBuildResult(
            result,
            ##"""
            public class UserGeneratingMock: UserGenerating {
                public typealias UserID = UserIDProtocol

                public init() {
                }
                public struct Invocation_generateUserIdentifier {
                }
                private (set) var invocations_generateUserIdentifier = [Invocation_generateUserIdentifier] ()

                public var handler_generateUserIdentifier: (() -> UserID)?

                public func generateUserIdentifier() -> UserID {
                    let invocation = Invocation_generateUserIdentifier(

                    )
                    invocations_generateUserIdentifier.append(invocation)
                    if let handler = handler_generateUserIdentifier {
                        return handler()
                    }
                    fatalError("Please set handler_generateUserIdentifier")
                }
            }
            """##
        )
    }

    // In this case, the associatedtype declares an inheritance.
    func testGenerics_inheritance() throws {
        let result = try NoDepMockClassFactory().classDecl(
            protocolDecl: try! ProtocolDeclSyntax(
            #"""
            public protocol Executor<Subject, ErrorType> {
                associatedtype Subject: ExecutorSubject
                associatedtype ErrorType = Never
                func perform(_ subjects: [Subject]) async throws -> [Subject]
            }
            """#
            )
        )

        assertBuildResult(
            result,
            ##"""
            public class ExecutorMock<P1: ExecutorSubject>: Executor {
                public typealias Subject = P1
                public typealias ErrorType = Never

                public init() {
                }
                public struct Invocation_perform {
                    public let subjects: [Subject]
                }
                private (set) var invocations_perform = [Invocation_perform] ()

                public var handler_perform: (([Subject]) async throws -> [Subject])?

                public func perform(_ subjects: [Subject]) async throws -> [Subject] {
                    let invocation = Invocation_perform(
                        subjects: subjects
                    )
                    invocations_perform.append(invocation)
                    if let handler = handler_perform {
                        return try await handler(subjects)
                    }
                    fatalError("Please set handler_perform")
                }
            }
            """##
        )
    }
}

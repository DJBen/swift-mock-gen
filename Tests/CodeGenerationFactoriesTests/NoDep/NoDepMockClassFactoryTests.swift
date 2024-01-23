// Copyright © 2024 Snap, Inc. All rights reserved.

import XCTest
@testable import CodeGenerationFactories
import SwiftSyntax
import CodeGenTesting

final class NoDepMockClassFactoryTests: XCTestCase {
    func testGenerics_plain() throws {
        let result = try NoDepMockClassFactory().classDecl(
            protocolDecl: try! ProtocolDeclSyntax(
            #"""
            public protocol UserGenerating {
                associatedtype UserID

                func generateUserIdentifier() -> UserID
            }
            """#
            )
        )

        assertBuildResult(
            result,
            ##"""
            public class UserGeneratingMock<UserID>: UserGenerating {

                public init() {
                }
                public struct Invocation_generateUserIdentifier {
                }
                public private (set) var invocations_generateUserIdentifier = [Invocation_generateUserIdentifier] ()

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
                public private (set) var invocations_generateUserIdentifier = [Invocation_generateUserIdentifier] ()

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
            public protocol Executor<Subject, Handler, ErrorType> {
                associatedtype Subject: ExecutorSubject
                associatedtype Handler: SomeHandler
                associatedtype ErrorType = Never
                func perform(_ subjects: [Subject]) async throws -> [Subject]
            }
            """#
            )
        )

        assertBuildResult(
            result,
            ##"""
            public class ExecutorMock<P1: ExecutorSubject, P2: SomeHandler>: Executor {
                public typealias Subject = P1
                public typealias Handler = P2
                public typealias ErrorType = Never

                public init() {
                }
                public struct Invocation_perform {
                    public let subjects: [Subject]
                }
                public private (set) var invocations_perform = [Invocation_perform] ()

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

    func testGenerics_whereClause() throws {
        let result = try NoDepMockClassFactory().classDecl(
            protocolDecl: try! ProtocolDeclSyntax(
            #"""
            public protocol Store<Subject>: Sendable {
                associatedtype Subject: SendToRankingSubject
                associatedtype FeatureKey: Hashable & RawRepresentable where FeatureKey.RawValue == String
                typealias Features = [Subject.ID: [FeatureKey: FeatureValue]]

                @available(iOS 13.0.0, *)
                func getFeatures(for subjects: [Subject]) async -> Features
            }
            """#
            )
        )

        assertBuildResult(
            result,
            ##"""
            public class StoreMock<P1: SendToRankingSubject, P2: Hashable & RawRepresentable>: Store where P2.RawValue == String {
                public typealias Subject = P1
                public typealias FeatureKey = P2

                public init() {
                }
                public struct Invocation_getFeatures {
                    public let subjects: [Subject]
                }
                public private (set) var invocations_getFeatures = [Invocation_getFeatures] ()

                public var handler_getFeatures: (([Subject]) async -> Features)?

                @available(iOS 13.0.0, *) public func getFeatures(for subjects: [Subject]) async -> Features {
                    let invocation = Invocation_getFeatures(
                        subjects: subjects
                    )
                    invocations_getFeatures.append(invocation)
                    if let handler = handler_getFeatures {
                        return await handler(subjects)
                    }
                    fatalError("Please set handler_getFeatures")
                }
            }
            """##
        )
    }

    func testGenerics_customGenericTypes() throws {
        let result = try NoDepMockClassFactory().classDecl(
            protocolDecl: try! ProtocolDeclSyntax(
            #"""
            public protocol Executor<Subject, Handler, ErrorType> {
                associatedtype Subject: ExecutorSubject
                associatedtype Handler: SomeHandler
                associatedtype ErrorType = Never
                func perform(_ subjects: [Subject]) async throws -> [Subject]
            }
            """#
            ),
            customGenericTypes: ["Subject": "MySubject", "Handler": "MyHandler"]
        )

        assertBuildResult(
            result,
            ##"""
            public class ExecutorMock: Executor {
                public typealias Subject = MySubject
                public typealias Handler = MyHandler
                public typealias ErrorType = Never

                public init() {
                }
                public struct Invocation_perform {
                    public let subjects: [Subject]
                }
                public private (set) var invocations_perform = [Invocation_perform] ()

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

    func testFunctionGenerics() throws {
        let result = try NoDepMockClassFactory().classDecl(
            protocolDecl: try! ProtocolDeclSyntax(
            #"""
            public protocol RendererDelegate: AnyObject {
                func renderer<Item: FloatingPoint>(
                    _ renderer: AnyObject,
                    didSelect item: Item,
                    with index: Int
                )
            }
            """#
            )
        )

        assertBuildResult(
            result,
            ##"""
            public class RendererDelegateMock: RendererDelegate {

                public init() {
                }
                public struct Invocation_renderer {
                    public let renderer: AnyObject
                    public let item: any FloatingPoint
                    public let index: Int
                }
                public private (set) var invocations_renderer = [Invocation_renderer] ()

                public var handler_renderer: ((AnyObject, any FloatingPoint, Int) -> Void)?

                public func renderer<Item: FloatingPoint>(
                        _ renderer: AnyObject,
                        didSelect item: Item,
                        with index: Int
                    ) {
                    let invocation = Invocation_renderer(
                        renderer: renderer,
                        item: item,
                        index: index
                    )
                    invocations_renderer.append(invocation)
                    if let handler = handler_renderer {
                        handler(renderer, item, index)
                    }
                }
            }
            """##
        )
    }
}


import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

enum TestCases {
    enum Case1 {
        static let protocolDecl = try! ProtocolDeclSyntax(
        #"""
        @objc
        public protocol SCCrashLoggerNetworkExecuting: NSObjectProtocol {
            @objc
            func performRequest(
                request: URLRequest,
                reportId: String,
                includeLogs: Bool,
                onSuccess: @escaping () -> Void,
                onPermanentFailure: @escaping (Error, String) -> Void
            ) -> String
        }
        """#
        )

        static let functionDecl = try! FunctionDeclSyntax(
            #"""
            @objc
            func performRequest(
                request: URLRequest,
                reportId: String,
                includeLogs: Bool,
                onSuccess: @escaping () -> Void,
                onPermanentFailure: @escaping (Error, String) -> Void
            ) -> String
            """#
        )
    }

    enum Case2 {
        static let protocolDecl = try! ProtocolDeclSyntax(#"""
        public protocol ServiceProtocol {
            var name: String {
                get
            }
            var anyProtocol: any Codable {
                get
                set
            }
            var secondName: String? {
                get
            }
            var added: () -> Void {
                get
                set
            }
            var removed: (() -> Void)? {
                get
                set
            }

            func initialize(name: String, secondName: String?)
            func fetchConfig() async throws -> [String: String]
            func fetchData(_ name: (String, count: Int)) async -> (() -> Void)
        }
        """#)
    }
}

import ArgumentParser
import Foundation

enum JSONParsingError: Error {
    case invalidEncoding
    case unexpectedType
}

struct MockGenArguments: ParsableArguments {
    @Option(
        name: [.long, .customShort("i")],
        parsing: .upToNextOption,
        help: "Additional modules to import; useful if you are compiling the generated files into a separate module, and thus needing to import the API module in which the protocols reside."
    )
    var additionalImports: [String] = []

    @Option(
        name: [.long],
        parsing: .upToNextOption,
        help: "An list of protocols that are excluded from the mock generation."
    )
    var excludeProtocols: [String] = []

    @Flag(
        name: [.long],
        inversion: .prefixedNo,
        help: """
        Support mocks of protocols with conformance to another protocol to be
        generated correcly, as long as the dependent protocol is included.
        Enabling this option may consume more memory.
        """
    )
    var transitiveProtocolConformance: Bool = true

    @Flag(
        name: [.customLong("only-public")],
        help: """
        Only generate mocks for public protocols if true.
        """
    )
    var onlyGenerateForPublicProtocols: Bool = false

    @Option(
        name: [.long],
        help: """
        A JSON formatted map of custom generic types for each protocol.
        It is used to specify a concrete type for the generic type requirement
        of the protocol. The mapping is in format of
        `{"<ProtocolName>": {"<GenericTypeName>": "<CustomType>", ...}, ...}`

        Given a protocol in the following example:
        ```
        public protocol Executor<Subject, Handler, ErrorType> {
            associatedtype Subject: ExecutorSubject
            associatedtype Handler: SomeHandler
            associatedtype ErrorType = Never
            func perform(_ subjects: [Subject]) async throws -> [Subject]
        }
        ```
        By default, a mock impl with generic parameters will be synthesized.
        ```
        public class ExecutorMock<P1: ExecutorSubject, P2: SomeHandler>: Executor {
            public typealias Subject = P1
            public typealias Handler = P2
            public typealias ErrorType = Never
            ...
        }
        ```
        If we specify a custom mapping like below,
        `{"Executor": {"Subject": "MySubject", "Handler": "MyHandler"}}`

        The generated mock's generic type requirements become the custom specified types.
        ```
        public class ExecutorMock: Executor {
            public typealias Subject = MySubject
            public typealias Handler = MyHandler
            public typealias ErrorType = Never
            ...
        }
        ```
        """
    )
    var customGenericTypes: String = "{}"

    var customGenericTypeMap: [String: [String: String]] {
        get throws {
            guard let data = customGenericTypes.data(using: .utf8) else {
                throw JSONParsingError.invalidEncoding
            }

            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dictionary = jsonObject as? [String: [String: String]] else {
                throw JSONParsingError.unexpectedType
            }

            return dictionary
        }
    }

    @Option(
        name: [.long],
        help: """
        A JSON formatted map of a snippet to appended into the generated mock of each protocol.
        
        It is used to work around cases where protocol has out-of-module dependencies, in which the user may specify additional snippet to fulfill compilation requirement.

        The mapping is in format of
        `{"<ProtocolName>": "<Snippets>"}`
        """
    )
    var customSnippets: String = "{}"

    var customSnippetsMap: [String: String] {
        get throws {
            guard let data = customSnippets.data(using: .utf8) else {
                throw JSONParsingError.invalidEncoding
            }

            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dictionary = jsonObject as? [String: String] else {
                throw JSONParsingError.unexpectedType
            }

            return dictionary
        }
    }
}

/// A command  that has arguments to parse source code
protocol MockGenCommand {
  var mockGenArguments: MockGenArguments { get }
}

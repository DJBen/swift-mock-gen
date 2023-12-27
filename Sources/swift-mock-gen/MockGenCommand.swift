import ArgumentParser
import Foundation

struct MockGenArguments: ParsableArguments {
    @Option(
        name: [.long],
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
}

/// A command  that has arguments to parse source code
protocol MockGenCommand {
  var mockGenArguments: MockGenArguments { get }
}

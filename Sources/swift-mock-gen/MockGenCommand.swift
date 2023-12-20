import ArgumentParser
import Foundation

struct MockGenArguments: ParsableArguments {
    @Option(
        name: [.long],
        help: "An list of protocols that are excluded from the mock generation."
    )
    var excludeProtocols: [String] = []
}

/// A command  that has arguments to parse source code
protocol MockGenCommand {
  var mockGenArguments: MockGenArguments { get }
}

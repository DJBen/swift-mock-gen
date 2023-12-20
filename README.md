# SwiftMockGen

Generates powerful mocks for Swift protocols, so you can relieve your responsibility of writing mock implementations for any dependencies within unit tests.

Unique feature offerings of Objective-C protocol support, transitive protocol conformances support that surpasses Mockolo or Mockingbird.

Modern `SwiftMacro` support makes integration lightweight.

## Install CLI
### Swift Package Manager
You can build `swift-mock-gen` by checking out the repo and run 
```swift build```, 
the executable should be built into `.build/debug` directory.

Alternatively, you may use `swift run swift-mock-gen ...`.
You can also open the `Package.swift` directly and building the `swift-mock-gen` target with Xcode.

### Bazel
We support building via Bazel to acheive ultimate flexibility.

```bash
bazel run :swift-mock-gen /path/to/files
```

You can even include this tool as a build rule of your existing app. (Instructions TBD)

## Generating mocks
### Swift Macro

Mark up the protocol declaration with `@GenerateMock`, a mock implementation will be generated
for DEBUG build only. You are all set for writing unit tests whose subject depends on this protocol!

```swift
import SwiftMockGen

@GenerateMock
public protocol ServiceProtocol {
   ...
}
```

### Command Line Interface (CLI)

Usage can be viewed by passing the `--help` or `-h` flag.
```bash
OVERVIEW: Generate mock for given protocols in the provided source files. The generated mock needs no dependencies.

USAGE: swift-mock-gen gen <source-paths> ... [--source <source>] [--output-dir <output-dir>] [--exclude-protocols <exclude-protocols> ...] [--transitive-protocol-conformance] [--no-transitive-protocol-conformance] [--surround-with-pound-if-debug] [--no-surround-with-pound-if-debug] [--copy-imports]

ARGUMENTS:
  <source-paths>          The source files and/or directories that should be parsed; if omitted, use stdin

OPTIONS:
  --source <source>       If passed, parse this source text instead of reading source file
  -o, --output-dir <output-dir>
                          Writes generated mocks to the output directory, if provided.
  --exclude-protocols <exclude-protocols>
                          An list of protocols that are excluded from the mock generation.
  --transitive-protocol-conformance/--no-transitive-protocol-conformance
                          Support mocks of protocols with conformance to another protocol to be
                          generated correcly, as long as the dependent protocol is included.
                          Enabling this option may use more memory. (default: --transitive-protocol-conformance)
  --surround-with-pound-if-debug/--no-surround-with-pound-if-debug
                          Surround with #if DEBUG directives. This ensures the mock only be included in DEBUG targets. (default: --no-surround-with-pound-if-debug)
  --copy-imports          Copy the original imports from the source file.
  -h, --help              Show help information.

```

### Usages

- To generate mocks for protocols within a source file into another file,

```bash
swift run swift-mock-gen gen ~/path/to/source.swift > ~/path/to/source.mock.swift
```

- To generate mocks for protocols within multiple directories / source files,
```bash
swift run swift-mock-gen gen /dir1 /dir2 /path/to/source.swift --output-dir /output-dir
```

## Writing tests

Given a protocol

```swift
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
```

Here's an example test
```swift
let mock = ServiceNoDepMock()
let container = TestedClass(executor: mock)

mock.underlying_name = "Name 1"
mock.underlying_secondName = "Name 2"
container.processName() // Its underlying impl reads mock's name and secondName properties

XCTAssertEqual(mock.getCount_secondName, 1)

mock.handler_fetchData = { name in
    return {}
}

let _ = await container.fetchData() // It invokes fetchData(("", 1))
let invocation = try XCTUnwrap(mock.invocations_fetchData.first)
XCTAssertEqual(invocation.name.0, "")
XCTAssertEqual(invocation.name.1, 1)
```

- `underlying_#variable#` is synthesized for every ivar of the protocol. You may set the value to provide an overridden value for the variable.
- `getCount_#variable#` and `setCount_#variable#` keep track of the number of accesses to the ivar's getter and setter.
- `handler_#function_name#` is synthesized for each function, and the it is expected that developer sets that to provide a return value for any non-Void function.
- `invocations_#function_name#` keeps track of every invocations of the method. Developers may assert against them in the unit tests.

## Features

### Objective-C protocol support
For protocols annotated with `@objc` and conforms to `NSObjectProtocol`, the mock will be of `NSObject` class and prevent the initializer from being synthesized.

### Effect specifiers support
- `throws` functions are supported: All the call site will have `try` preceeding the function signature.
- `async` functions are supported. All the call site will have `await` preceeding the function signature.

### Transitive protocol conformances
When a protocol conforms to another protocol, naive per-protocol generation would not include the methods of parent protocol.

For example, 
```swift
protocol P1: NSObjectProtocol, P2, P3 {
    func p1()
}

protocol P2: P4, Extra {
    func p2()
}

protocol P3 {
    func p3()
}

protocol P4 {
    func p4()
}
```

If generating protocol `P1` naively, one would only synthesize mock method `p1` but misses `p2`, `p3`, and `p4` (via P2).
`swift-mock-gen` supports generating mocks for protcols with transitive dependencies as long as they are included in the file list.

Via toposort and protocol merging, when generating mock for `P1`, it will meld protcol bodies of P1 through P4, equivalent to the protocol below.
```swift
protocol P1: NSObjectProtocol {
   func p3()
   func p4()
   func p2()
   func p1()
}
```

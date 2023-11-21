# SwiftMockGen

Generates powerful mocks for Swift protocols, so you can relieve your responsibility of writing mock implementations for any dependencies within unit tests.

You can build `swift-mock-gen` by checking out and run `swift build`, the executable should be built into `.build/debug` directory.
Alternatively if you are developing it, you may use `swift run swift-mock-gen ...`.
You can also open the `SwiftMockGen` package and building the `swift-mock-gen` target in Xcode.

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
$ .build/debug/swift-mock-gen gen -h

OVERVIEW: Generate mock for given protocols in the provided source files.

USAGE: swift-mock-gen gen [<source-file>] [--source <source>] [--fold-sequences] [--surround-with-pound-if-debug] [--no-surround-with-pound-if-debug]

ARGUMENTS:
  <source-file>           The source file that should be parsed; if omitted, use stdin

OPTIONS:
  -s, --source <source>   If passed, parse this source text instead of reading source file
  --fold-sequences        Perform sequence folding with the standard operators
  --surround-with-pound-if-debug/--no-surround-with-pound-if-debug
                          Surround with #if DEBUG directives. This ensures the mock only be included in DEBUG targets. (default: --no-surround-with-pound-if-debug)
  -h, --help              Show help information.

```
To generate mocks for all protocols within a source file into another file,
```bash
swift run swift-mock-gen gen ~/path/to/source.swift --surround-with-pound-if-debug >> ~/path/to/source.mock.swift
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

### Objective-C protocol support
For protocols annotated with `@objc` and conforms to `NSObjectProtocol`, the mock will be of `NSObject` class and prevent the initializer from being synthesized.

### Effect specifiers support
- `throws` functions are supported: All the call site will have `try` preceeding the function signature.
- `async` functions are supported. All the call site will have `await` preceeding the function signature.

### Limitations
1. Transitive protocol conformance: when a protocol conforms to another protocol, `swift-mock-gen` tool will not synthesize the parent protocol's methods.

# SwiftMockGen

Generates powerful mocks for Swift protocols, so you can relieve your responsibility of writing mock implementations for any dependencies within unit tests.

Unique feature offerings of Objective-C protocol support, transitive protocol conformances and generics, which other mock generation tools like `Mockolo` or `Mockingbird` may fail.

The package includes `SwiftMacro` support that allows lightweight integration.

## Generating mocks
There are three ways to integrate this mock generation with your project: Swift Macro, CLI or Bazel integration.

### Swift Macro

Mark up the protocol declaration with `@GenerateMock`, a mock implementation will be generated alongside the protocol source file, surrounded with `if #DEBUG` block. You are all set for writing unit tests whose subject depends on this protocol!

```swift
import SwiftMockGen

@GenerateMock
public protocol ServiceProtocol {
   ...
}
```

### Command Line Interface (CLI)
One can run the `swift-mock-gen` executable target with either Swift Pacakge Manager or Bazel.
```
swift run swift-mock-gen gen <arguments>
bazel run :swift-mock-gen gen <arguments>
```

Usage can be viewed by passing the `--help` or `-h` flag.

```bash
OVERVIEW: Generate mock for given protocols in the provided source files. The generated mock needs no dependencies.

USAGE: swift-mock-gen gen [<source-paths> ...] [--source <source>] [--output-dir <output-dir>] [-v] [--additional-imports <additional-imports> ...] [--exclude-protocols <exclude-protocols> ...] [--transitive-protocol-conformance] [--no-transitive-protocol-conformance] [--surround-with-pound-if-debug] [--no-surround-with-pound-if-debug] [--copy-imports]

ARGUMENTS:
  <source-paths>          The source files and/or directories that should be parsed; use stdin if omitted

OPTIONS:
  --source <source>       If provided, parse the source text instead of reading source file
  -o, --output-dir <output-dir>
                          If provided, writes generated mocks to the output directory in lieu of stdout.
  -v                      Enables verbose debug outputs
  -i, --additional-imports <additional-imports>
                          Additional modules to import; useful if you are compiling the generated files into a separate module, and thus
                          needing to import the API module in which the protocols reside.
  --exclude-protocols <exclude-protocols>
                          An list of protocols that are excluded from the mock generation.
  --transitive-protocol-conformance/--no-transitive-protocol-conformance
                          Support mocks of protocols with conformance to another protocol to be
                          generated correcly, as long as the dependent protocol is included.
                          Enabling this option may consume more memory. (default: --transitive-protocol-conformance)
  --surround-with-pound-if-debug/--no-surround-with-pound-if-debug
                          Surround with #if DEBUG directives. This ensures the mock only be included in DEBUG targets. (default:
                          --no-surround-with-pound-if-debug)
  --copy-imports          Copy the original imports from the source file.
  -h, --help              Show help information.
```

### Example usages

- To generate mocks from stdin sources
```bash
swift run swift-mock-gen gen
```
Now type/paste your protocol code in stdin and hit `Ctrl+D` when finishes. Mock will be directly outputted to the stdout. 

- To generate mocks for protocols within a source file into another file

```bash
swift run swift-mock-gen gen ~/path/to/source.swift > ~/path/to/source.mock.swift
```

- To generate mocks for protocols within multiple directories / source files to an output directory
```bash
swift run swift-mock-gen gen /dir1 /dir2 /path/to/source.swift --output-dir /output-dir --copy-imports
```
The generated mock will be renamed to `<original_file_name>Mock.swift` for each input swift file. In this example, `--copy-imports` is added in order to successfully compile any transitive imports from the protocol. Note that transitive protocol conformances are supported; read the **Features** section to learn more.

### Integrating with Bazel build pipeline

`generate_swift_mock.bzl` file defines a `generate_swift_mock` rule to generate mocks, and also a macro `generate_swift_mock_module` to generate a static swift mock library.

An example integration is created within `./ExampleIntegration` to demonstrate how an external Bazel package leverages mock generation.

A high level steps are as follows:

1. In `WORKSPACE`, load `swift_mock_gen` repository. This is typically done by `http_archive`.
2. In `WORKSPACE`, load dependencies by the following
```python
load(
    "@swift_mock_gen//:deps.bzl",
    "swift_mock_gen_dependencies",
)
swift_mock_gen_dependencies()
```
3. In `BUILD.bazel` file, define your API as `swift_library`.
4. In `BUILD.bazel` file, `load("@swift_mock_gen//:generate_swift_mock.bzl", "generate_swift_mock_module")`, and use `generate_swift_mock_module`.
```python
generate_swift_mock_module(
    api_module = ":Example",
    srcs = glob(["Sources/**/*.swift"]),
    exclude_protocols = [],
)
```
5. Now you may depend on the mock module 
```python
swift_test(
    name = "ExampleImplTests",
    srcs = glob(["ExampleImplTests/**/*.swift"]),
    deps = [
        ":Example",
        ":ExampleImpl",
        ":ExampleMock", # a ${Target}Mock library will be synthesized consisting of mocks of all the protocols in the api_module library.
    ],
)
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

### Generics support

The tool supports generating mock impls for protocls that have generics in them. For example the below case contains two generics: `Subject` conforms to `ExecutorSubject`, `A` and `B`, and `ErrorType` is aliased to `Never`.

```swift
public protocol Executor<Subject, ErrorType> {
    associatedtype Subject: ExecutorSubject, A, B
    associatedtype ErrorType = Never
    func perform(_ subjects: [Subject]) async throws -> [Subject]
}
```

The below mock is generated. Each associated type with inheritance requirement will produce a generic parameter, and aliased associated type is kept.

```swift
public class ExecutorMock<P1: ExecutorSubject & A & B>: Executor {
    public typealias Subject = P1
    public typealias ErrorType = Never

    // ... generated mock functions
}
```

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

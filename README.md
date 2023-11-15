# SwiftMockGen

Generates powerful mocks for Swift protocols, so you can relieve your responsibility of writing mock implementations for any dependencies within unit tests.

You can build `swift-mock-gen` by checking out and run `swift build`, the executable should be built into `.build/debug` directory.
Alternatively if you are developing it, you may use `swift run swift-mock-gen ...`.
You can also open the `SwiftMockGen` package and building the `swift-mock-gen` target in Xcode.

## Generating mocks
Usage can be viewed by passing the `--help` or `-h` flag.
```bash
$ .build/debug/swift-mock-gen -h

OVERVIEW: Generate mock for given protocols in the provided source files.

USAGE: swift-mock-gen gen-mock [<source-file>] [--source <source>] [--fold-sequences] [--surround-with-pound-if-debug] [--no-surround-with-pound-if-debug]

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
swift run swift-mock-gen gen-mock ~/path/to/source.swift --surround-with-pound-if-debug >> ~/path/to/source.mock.swift
```


## Writing tests

Given a protocol,

```swift
public protocol : NSObjectProtocol {
    @objc
    func performRequest(
        request: URLRequest,
        someId: String,
        includeValue: Bool,
        onSuccess: @escaping () -> Void,
        onPermanentFailure: @escaping (Error, String) -> Void
    ) -> String
}
```
A group of methods will be generated per method and getter / setter within that protocol.

| | Stub | Expect | Verify |
|---| --- | --- | --- |
|**Example**| stub_performRequest(...) | expect_performRequest(...) | verify_performRequest() |
|**Usage**| Make the mock impl to return a certain value when arguments satisfies criteria | Stub + setting expectation that the method will be called for a certain number of times | Verify that the expectation of the call(s) are met |

Unit tests is written with declare...expect...assert...verify pattern, an example below.
```swift
let mock = NetworkExecutorMock()
let container = TestedClass(executor: mock) // The class being tested that takes the protocol as dependency
let expectation = expectation(description: "")

mock.expect_performRequest(
    request: .url(URL(string: "https://test.com/123")!),
    someId: .eq("123"),
    includeValue: .eq(true),
    onSuccess: InvokeBlock(), // Note that the blocks are replaced by `InvokeBlock` signatures. When provided, it triggers the block with args.
    onPermanentFailure: nil,
    andReturn: "identifier", // `andReturn` appears as an additional argument to provide the stubbed return value
    expectation: .count(0) // specifies the call expecatation
)

XCTAssertEqual(
    container.run(
        reportId: "123",
        onCompletion: { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
    ),
    "identifier"
)
mock.verify_performRequest() // If expecatation fails, an XCFail message will appear.
waitForExpectations(timeout: 1)
```

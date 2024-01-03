import Example

public struct ExampleImpl: Example {
    public let id: String

    public init(id: String) {
        self.id = id
    }

    public func helloWorld() -> String {
        return "Hello world"
    }

    public func common() -> Int {
        42
    }

    public func parent() {}
}

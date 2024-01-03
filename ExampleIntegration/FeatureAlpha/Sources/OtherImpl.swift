import Example

public final class OtherImpl {
    let example: any Example

    public init(
        example: any Example
    ) {
        self.example = example
    }

    public func yell() -> String {
        example.helloWorld()
    }
}
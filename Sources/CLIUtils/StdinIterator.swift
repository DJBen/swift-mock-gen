import Foundation

public struct StdinIterator: IteratorProtocol {
    private var hasReadFromStdin = false

    public init() {
    }

    public mutating func next() -> File? {
        if hasReadFromStdin {
            return nil
        }
        let stdin = File(
            fileName: nil,
            content: [UInt8](FileHandle.standardInput.readDataToEndOfFile())
        )
        hasReadFromStdin = true
        return stdin
    }
}

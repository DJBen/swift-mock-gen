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

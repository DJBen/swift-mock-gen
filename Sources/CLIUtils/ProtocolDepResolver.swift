import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

public struct ProtocolDeclResult: Equatable {
    public let decl: ProtocolDeclSyntax
    public let imports: [ImportDeclSyntax]
    public let fileName: String?

    func melding(into result: ProtocolDeclResult) -> ProtocolDeclResult {
        ProtocolDeclResult(
            decl: decl.melding(into: result.decl),
            imports: combine(imports, result.imports),
            fileName: result.fileName
        )
    }

    // Uniquely combine multiple import decl statements
    private func combine(_ imports1: [ImportDeclSyntax], _ imports2: [ImportDeclSyntax]) -> [ImportDeclSyntax] {
        var set: Set<String> = []
        set.formUnion(imports1.map { $0.trimmed.formatted().description })
        set.formUnion(imports2.map { $0.trimmed.formatted().description })
        return Array(set).sorted().map {
            try! ImportDeclSyntax("\(raw: $0)")
        }
    }
}

struct ProtocolDeps: Equatable {
    var name: String
    var deps: [String]
}

enum ProtocolDepResolverError: Error {
    case circularProtocolConformances
}

public struct ProtocolDepResolver {
    let fileIteratorProvider: () -> any IteratorProtocol<File>

    public init(fileIteratorProvider: @escaping () -> any IteratorProtocol<File>) {
        self.fileIteratorProvider = fileIteratorProvider
    }
    
    /// Return a list of ``ProtocolDeclResult``s. Their protocl decl syntaxes are merged from their
    /// parent's, if any are inherited from parents.
    /// - Parameters:
    ///   - copyImports: Whether to copy the imports.
    ///   - additionalImports: Any additional modules to be imported.
    ///   - additionalTestableImports: Any additional @testable imports.
    /// - Returns: A tuple consisting of processed results, and a list of empty files.
    public func inheritanceMergedProtocolDecls(
        copyImports: Bool,
        additionalImports: [String] = [],
        additionalTestableImports: [String] = []
    ) throws -> ([ProtocolDeclResult], [String]) {
        var fileIterator = fileIteratorProvider()
        var protocols = [String: ProtocolDeclResult]()
        var protocolDeps = [ProtocolDeps]()
        var emptyFiles = [String]()

        while let sourceFile = fileIterator.next() {
            var isSourceFileEmpty = true
            try sourceFile.content.withUnsafeBufferPointer { sourceBuffer in
                let tree = Parser.parse(source: sourceBuffer)
                var imports: [ImportDeclSyntax] = []

                if copyImports {
                    for codeBlockItemSyntax in tree.statements {
                        if let importDecl = codeBlockItemSyntax.item.as(ImportDeclSyntax.self) {
                            imports.append(importDecl)
                        }
                    }
                }

                for additionalImport in additionalImports {
                    imports.append(try ImportDeclSyntax("import \(raw: additionalImport)"))
                }

                for additionalTestableImport in additionalTestableImports {
                    imports.append(try ImportDeclSyntax("@testable import \(raw: additionalTestableImport)"))
                }

                for codeBlockItemSyntax in tree.statements {
                    if let protocolDecl = codeBlockItemSyntax.item.as(ProtocolDeclSyntax.self) {
                        protocols[protocolDecl.name.text] = ProtocolDeclResult(
                            decl: protocolDecl,
                            imports: imports,
                            fileName: sourceFile.fileName
                        )
                        protocolDeps.append(
                            ProtocolDeps(
                                name: protocolDecl.name.trimmed.text,
                                deps: protocolDecl.conformedNonNSObjectProtocols
                            )
                        )
                        isSourceFileEmpty = false
                    }
                }

                if isSourceFileEmpty, let fileName = sourceFile.fileName {
                    emptyFiles.append(fileName)
                }
            }
        }

        // Remove extraneous protocol deps that do not exist in our scan range
        for index in 0..<protocolDeps.count {
            protocolDeps[index].deps = protocolDeps[index].deps.filter { protocols[$0] != nil }
        }

        let mergedResults = try mergeProtocols(
            protocolDeps,
            protocols: &protocols
        )
        .map { $0.name }
        .reduce(
            into: [ProtocolDeclResult](), {
                if let syntax = protocols[$1] {
                    $0.append(syntax)
                }
            }
        )

        return (mergedResults, emptyFiles)
    }

    func mergeProtocols(
        _ deps: [ProtocolDeps],
        protocols: inout [String: ProtocolDeclResult]
    ) throws -> [ProtocolDeps] {
        // Toposort Kahn algorithm
        // Find vertices with no predecessors and puts them into a new list.
        // These are the "leaders". The leaders array eventually becomes the
        // topologically sorted list.
        var leaders = deps.filter { $0.deps.isEmpty }
        var inDegree = [String: Int]()
        for protocolDep in deps {
            inDegree[protocolDep.name] = protocolDep.deps.count
        }

        // "Remove" each of the leaders. We do this by decrementing the in-degree
        // of the nodes they point to. As soon as such a node has itself no more
        // predecessors, it is added to the leaders array. This repeats until there
        // are no more vertices left.
        var l = 0
        while l < leaders.count {
            let children = deps.filter { $0.deps.contains(leaders[l].name) }
            for child in children {
                if let count = inDegree[child.name] {
                    // Meld predecessor protocol into child protocol.
                    if let leaderProtocol = protocols[leaders[l].name], let childProtocol = protocols[child.name] {
                        protocols[child.name] = leaderProtocol.melding(into: childProtocol)
                    }
                    inDegree[child.name] = count - 1
                    if count == 1 { // this leader was the last predecessor
                        leaders.append(child)  // so neighbor is now a leader itself
                    }
                }
            }
            l += 1
        }

        // Was there a cycle in the graph?
        if leaders.count != deps.count {
            throw ProtocolDepResolverError.circularProtocolConformances
        }

        return leaders
    }
}

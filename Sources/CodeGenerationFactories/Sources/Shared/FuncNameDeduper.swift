import Foundation
import SwiftSyntax

/// Deduplicates function signatures and generates a unique name for the function signature.
struct FuncNameDeduper {
    private(set) var funcNameMaps: [FuncNameDescriptor: IndexPath]

    init(
        protocolDecl: ProtocolDeclSyntax,
        funcDecls: [FunctionDeclSyntax]
    ) {
        funcNameMaps = [:]
        
        protocolDecl.memberBlock.members.compactMap { member -> FuncNameDescriptor? in
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                return nil
            }
            return FuncNameDescriptor(funcDecl: funcDecl)
        }
        .sorted()
        .forEach { funcNameDescriptor in
            // Generated type e.g. Invocation_#func_name# deduplication in case of same method name.
            // Will keep attaching param names until the name is unique.
            var indexPath = IndexPath()
            funcNameMaps[funcNameDescriptor] = indexPath
            for existingDescriptor in funcNameMaps.keys {
                if funcNameDescriptor == existingDescriptor {
                    continue
                }
                var existingIndexPath = funcNameMaps[existingDescriptor]!
                while existingDescriptor.description(existingIndexPath) == funcNameDescriptor.description(indexPath) {
                    // Because it is sorted, incrementing the latter should always yields a hit
                    indexPath = funcNameDescriptor.nextIndexPath(indexPath)!
                    existingIndexPath = existingDescriptor.nextIndexPath(existingIndexPath) ?? existingIndexPath
                }
                funcNameMaps[existingDescriptor] = existingIndexPath
                funcNameMaps[funcNameDescriptor] = indexPath
            }
        }
    }

    func name(for funcDecl: FunctionDeclSyntax) -> String {
        let descriptor = FuncNameDescriptor(funcDecl: funcDecl)
        guard let indexPath = funcNameMaps[descriptor] else {
            return funcDecl.name.trimmed.text
        }
        return descriptor.description(indexPath)
    }
}

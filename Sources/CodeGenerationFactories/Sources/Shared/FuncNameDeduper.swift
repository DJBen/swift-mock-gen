import Foundation
import SwiftSyntax

/// Deduplicates function signatures and generates a unique name for the function signature.
struct FuncNameDeduper {
    private(set) var funcNameVariant: [String: UInt] = [:]
    private(set) var funcNameMaps: [FuncNameDescriptor: IndexPath] = [:]
    private(set) var variants: [FuncNameDescriptor: UInt] = [:]
    
    init(
        protocolDecl: ProtocolDeclSyntax,
        funcDecls: [FunctionDeclSyntax]
    ) {
        for member in protocolDecl.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                continue
            }
            
            let funcNameDescriptor = FuncNameDescriptor(funcDecl: funcDecl)
            if let lastVariantIndex = variants[funcNameDescriptor] {
                variants[funcNameDescriptor] = lastVariantIndex + 1
                funcNameVariant[funcDecl.debugDescription] = lastVariantIndex + 1
            } else {
                variants[funcNameDescriptor] = 0
                funcNameVariant[funcDecl.debugDescription] = 0
            }
        }
        
        let uniqueFuncNameDescriptors = Array(Set(protocolDecl.memberBlock.members.compactMap { member -> FuncNameDescriptor? in
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                return nil
            }
            return FuncNameDescriptor(funcDecl: funcDecl)
        })).sorted()
        
        // Populate index path
        uniqueFuncNameDescriptors.forEach { funcNameMaps[$0] = IndexPath() }
        
        if uniqueFuncNameDescriptors.isEmpty {
            return
        }
        
        // For each pair of descriptor, increment them both if their names collide
        for i in 0..<uniqueFuncNameDescriptors.count - 1 {
            for j in 1..<uniqueFuncNameDescriptors.count {
                if i == j { continue }
                let descriptor1 = uniqueFuncNameDescriptors[i]
                let descriptor2 = uniqueFuncNameDescriptors[j]
                
                // Generated type e.g. Invocation_#func_name# deduplication in case of same method name.
                // Will keep attaching param names until the name is unique.
                var indexPath1 = funcNameMaps[descriptor1]!
                var indexPath2 = funcNameMaps[descriptor2]!

                while descriptor1.description(indexPath1) == descriptor2.description(indexPath2) {
                    print(descriptor1, descriptor2, descriptor1.description(indexPath1))
                    // Because the functions are sorted, trying to increment both could result in
                    // - Case 1: if function1 is shorter than function2, function1 doesn't have a longer description, it stays the current description
                    // - Case 2: both functions are of the same length, they both need to increase in length in order to disambiguate
                    indexPath1 = descriptor1.nextIndexPath(indexPath1) ?? indexPath1
                    indexPath2 = descriptor2.nextIndexPath(indexPath2)!
                }
                funcNameMaps[descriptor1] = indexPath1
                funcNameMaps[descriptor2] = indexPath2
            }
        }
    }

    func name(for funcDecl: FunctionDeclSyntax) -> String {
        let descriptor = FuncNameDescriptor(funcDecl: funcDecl)
        guard let variantIndex = funcNameVariant[funcDecl.debugDescription], let indexPath = funcNameMaps[descriptor] else {
            return funcDecl.name.trimmed.text
        }
        return descriptor.description(indexPath) + String(variantIndex == 0 ? "" : "\(variantIndex)")
    }
}

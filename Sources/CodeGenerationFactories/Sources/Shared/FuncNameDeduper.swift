import SwiftSyntax

/// Deduplicates function signatures and generates a unique name for the function signature.
struct FuncNameDeduper {
    let funcNameMaps: [FuncNameDescriptor: String]

    init(
        protocolDecl: ProtocolDeclSyntax,
        funcDecls: [FunctionDeclSyntax]
    ) {
        self.funcNameMaps = protocolDecl.memberBlock.members.compactMap { member -> FuncNameDescriptor? in
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
                return nil
            }
            return FuncNameDescriptor(funcDecl: funcDecl)
        }
        .sorted(by: { $0.paramNames.count < $1.paramNames.count })
        .reduce(into: [FuncNameDescriptor: String]()) { existingSignatureNameMap, funcNameDescriptor in
            // Generated type e.g. Invocation_#func_name# deduplication in case of same method name.
            // Will keep attaching param names until the name is unique.
            for count in 0...funcNameDescriptor.paramNames.count {
                let trimmedFuncNameDescriptor = funcNameDescriptor.keepingParams(count)
                let funcNameExists = existingSignatureNameMap.contains { _, str in
                    trimmedFuncNameDescriptor.description == str
                }
                if !funcNameExists {
                    existingSignatureNameMap[funcNameDescriptor] = trimmedFuncNameDescriptor.description
                    break
                }
            }
        }
    }

    func name(for funcDecl: FunctionDeclSyntax) -> String {
        funcNameMaps[FuncNameDescriptor(funcDecl: funcDecl)] ?? funcDecl.name.text
    }
}

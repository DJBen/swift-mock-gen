import Foundation
import SwiftSyntax

struct FuncNameDescriptor: Equatable, Hashable, CustomStringConvertible {
    let name: String
    let paramNames: [String]

    init(name: String, paramNames: [String]) {
        self.name = name
        self.paramNames = paramNames
    }

    init(funcDecl: FunctionDeclSyntax) {
        self.name = funcDecl.name.text
        self.paramNames = funcDecl.signature.parameterClause.parameters.map { param in
            param.firstName.text
        }
    }

    func keepingParams(_ count: Int) -> FuncNameDescriptor {
        return FuncNameDescriptor(
            name: name,
            paramNames: Array(paramNames.prefix(count))
        )
    }

    var description: String {
        let paramNames = paramNames.map { param in
            if param == "_" {
                return ""
            } else {
                return param.capitalizingFirstLetter()
            }
        }.joined()
        return "\(name)\(paramNames)"
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        guard let firstLetter = self.first else { return self }
        return firstLetter.uppercased() + self.dropFirst()
    }
}

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
        // When disambiguating function names, consider non-wildcard (_) first name
        // first, and second names with wildcard first names next.
        // `log(a:b:)` vs `log(a:b:c)` can be disambiguated by the first names
        // `log(_ a:)` vs `log(_ b:)` however needs to be disambiguated by the second names.
        self.paramNames = funcDecl.signature.parameterClause.parameters.compactMap { param in
            if param.firstName.tokenKind != .wildcard {
                return param.firstName.text
            }
            return nil
        } + funcDecl.signature.parameterClause.parameters.compactMap { param in
            if param.firstName.tokenKind == .wildcard {
                return param.secondName!.text
            }
            return nil
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

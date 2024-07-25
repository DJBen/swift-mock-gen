import Foundation
import SwiftSyntax

struct FuncNameDescriptor: Equatable, Hashable, Comparable, CustomDebugStringConvertible {
    struct ParamName: Equatable, Hashable, Comparable {
        // First name could be wildcard '_'
        let firstName: String
        let secondName: String?
        
        subscript(_ index: Int) -> String? {
            if index == 0 {
                if firstName == "_" {
                    return secondName!
                }
                return firstName
            } else if index == 1 {
                if firstName == "_" {
                    return nil
                }
                return secondName
            } else {
                return nil
            }
        }
        
        static func < (lhs: FuncNameDescriptor.ParamName, rhs: FuncNameDescriptor.ParamName) -> Bool {
            if let s1 = lhs.secondName, let s2 = rhs.secondName {
                return s1 < s2
            } else if let _ = lhs.secondName {
                return true
            } else if let _ = rhs.secondName {
                return false
            } else {
                return lhs.firstName < rhs.firstName
            }
        }
    }
    
    let name: String
    
    let paramNames: [ParamName]

    init(name: String, paramNames: [ParamName]) {
        self.name = name
        self.paramNames = paramNames
    }

    init(funcDecl: FunctionDeclSyntax) {
        self.name = funcDecl.name.text
        // When disambiguating function names, consider non-wildcard (_) first name
        // first, and second names with wildcard first names next.
        // `log(a:b:)` vs `log(a:b:c)` can be disambiguated by the first names
        // `log(_ a:)` vs `log(_ b:)` however needs to be disambiguated by the second names.
        self.paramNames = funcDecl.signature.parameterClause.parameters.map { param in
            ParamName(
                firstName: {
                    return param.firstName.trimmed.text
                }(),
                secondName: param.secondName?.trimmed.text
            )
        }
    }
    
    var debugDescription: String {
        let paramString = paramNames.map(\.firstName).joined(separator: ":")
        return "\(name)(\(paramString))"
    }
    
    static func < (lhs: FuncNameDescriptor, rhs: FuncNameDescriptor) -> Bool {
        if lhs.name != rhs.name {
            return lhs.name < rhs.name
        }
        if lhs.paramNames.count != rhs.paramNames.count {
            return lhs.paramNames.count < rhs.paramNames.count
        }
        for (p1, p2) in zip(lhs.paramNames, rhs.paramNames) {
            if p1 != p2 {
                return p1 < p2
            }
        }
        return false
    }
    
    func nextIndexPath(_ indexPath: IndexPath) -> IndexPath? {
        if indexPath.count >= paramNames.count {
            guard let last = indexPath.last else {
                return nil
            }
            if paramNames[indexPath.count - 1][last + 1] != nil {
                var newIndexPath = indexPath
                newIndexPath[indexPath.count - 1] = last + 1
                return newIndexPath
            } else {
                return nil
            }
        } else {
            // Param not empty
            guard let last = indexPath.last else {
                return IndexPath(index: 0)
            }
            if paramNames[indexPath.count - 1][last + 1] != nil {
                var newIndexPath = indexPath
                newIndexPath[indexPath.count - 1] = last + 1
                return newIndexPath
            } else {
                var newIndexPath = indexPath
                newIndexPath.append(0)
                return newIndexPath
            }
        }
    }
    
    func description(_ indexPath: IndexPath) -> String {
        let paramNamesString = indexPath.enumerated().map { (index, choice) in
            if paramNames[index][choice] == "_" {
                return ""
            } else {
                return paramNames[index][choice]!.capitalizingFirstLetter()
            }
        }.joined()
        return "\(name)\(paramNamesString)"
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        guard let firstLetter = self.first else { return self }
        return firstLetter.uppercased() + self.dropFirst()
    }
}

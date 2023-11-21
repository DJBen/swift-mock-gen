#if canImport(SwiftCompilerPlugin)
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftMockGenCompilerPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SwiftMockGenMacro.self,
    ]
}
#endif

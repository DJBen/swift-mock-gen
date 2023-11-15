//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import Foundation
import InstructionCounter
import SwiftDiagnostics
import SwiftOperators
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax

#if os(Windows)
import WinSDK
#endif

@main
class SwiftMockGen: ParsableCommand {
  required init() {}

  static var configuration = CommandConfiguration(
    abstract: "Utility to generate Swift mock implementations given a protocol.",
    subcommands: [
      BasicFormat.self,
      PerformanceTest.self,
      PrintDiags.self,
      PrintTree.self,
      Reduce.self,
      VerifyRoundTrip.self,
      GenerateMock.self,
    ]
  )
}

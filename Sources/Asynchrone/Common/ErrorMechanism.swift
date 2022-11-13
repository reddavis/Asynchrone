//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Async Algorithms open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@rethrows
protocol _ErrorMechanism {
    associatedtype Output
    func get() throws -> Output
}

extension _ErrorMechanism {
    func _rethrowError() rethrows -> Never {
        _ = try _rethrowGet()
        fatalError("Materialized error without being in a throwing context")
    }
  
    func _rethrowGet() rethrows -> Output {
        try get()
    }
}

extension Result: _ErrorMechanism { }

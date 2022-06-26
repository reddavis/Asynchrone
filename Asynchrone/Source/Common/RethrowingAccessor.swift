import Foundation

@rethrows
protocol RethrowingAccessor {
    associatedtype T
    func _value() throws ->  T
}

extension RethrowingAccessor {
    func _forceRethrowError() rethrows {
        _ = try _retrowValue()
        fatalError("No error")
    }
    
    func _retrowValue() rethrows -> T {
        try self._value()
    }
}

// MARK: Result

extension Result: RethrowingAccessor {
    func _value() throws -> Success {
        try self.get()
    }
}

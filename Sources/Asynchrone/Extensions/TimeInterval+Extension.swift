import Foundation

extension TimeInterval {
    var asNanoseconds: TimeInterval {
        self * 1_000_000_000
    }
}

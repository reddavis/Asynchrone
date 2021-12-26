//
//  AnyAsyncIterator.swift
//  Asynchrone
//
//  Created by Michal Zaborowski on 2021-12-26.
//

import Foundation

private protocol AsyncIteratorProtocolBox {

    /// Asynchronously advances to the next element and returns it, or ends the
    /// sequence if there is no next element.
    ///
    /// - Returns: The next element, if it exists, or `nil` to signal the end of
    ///   the sequence.
    mutating func nextObject() async throws -> Any?
}

private struct ConcreteAsyncIteratorBox<Base: AsyncIteratorProtocol>: AsyncIteratorProtocolBox {

    fileprivate private(set) var originalValue: Base

    mutating fileprivate func nextObject() async throws -> Any? {
        try await originalValue.next()
    }
}

public struct AnyAsyncIterator<T>: AsyncIteratorProtocol {

    public typealias Element = T

    // MARK: AnyAsyncIterator (Private Properties)

    private var base: AsyncIteratorProtocolBox

    // MARK: AnyAsyncIterator (Public Methods)

    public init<I: AsyncIteratorProtocol>(_ base: I) where I.Element == T {
        self.base = ConcreteAsyncIteratorBox(originalValue: base)
    }

    // MARK: AsyncIteratorProtocol

    public mutating func next() async throws -> T? {
        try await base.nextObject() as? T
    }
}

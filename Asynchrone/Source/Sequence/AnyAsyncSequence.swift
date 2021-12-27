//
//  AnyAsyncSequence.swift
//  Asynchrone
//
//  Created by Michal Zaborowski on 2021-12-26.
//

import Foundation

// MARK: - AnyAsyncSequence

public struct AnyAsyncSequence<T>: AsyncSequence, AsyncIteratorProtocol {
    public typealias Element = T

    // MARK: AnyAsyncSequence (Private Properties)

    private let base: Any
    private var iterator: AnyAsyncIterator<T>

    // MARK: AnyAsyncSequence (Public Methods)

    public init<U: AsyncSequence>(base: U) where U.Element == T {
        self.base = base
        self.iterator = AnyAsyncIterator(base.makeAsyncIterator())
    }

    public mutating func next() async -> Element? {
        await iterator.next()
    }

    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AnyAsyncIterator<T> {
        iterator
    }
}

// MARK: - AnyAsyncThrowingSequence

public struct AnyAsyncThrowingSequence<T>: AsyncSequence, AsyncIteratorProtocol {
    public typealias Element = T

    // MARK: AnyAsyncThrowingSequence (Private Properties)

    private let base: Any
    private var iterator: AnyThrowingAsyncIterator<T>

    // MARK: AnyAsyncThrowingSequence (Public Methods)

    public init<U: AsyncSequence>(base: U) where U.Element == T {
        self.base = base
        self.iterator = AnyThrowingAsyncIterator(base.makeAsyncIterator())
    }

    public mutating func next() async throws -> Element? {
        try await iterator.next()
    }

    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> AnyThrowingAsyncIterator<T> {
        iterator
    }
}

extension AsyncSequence {

    public func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
        AnyAsyncSequence<Element>(base: self)
    }

    public func eraseToAnyAsyncThrowingSequence() -> AnyAsyncThrowingSequence<Element> {
        AnyAsyncThrowingSequence<Element>(base: self)
    }
}

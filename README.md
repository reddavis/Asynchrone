# Asynchone

Extensions and additions to `AsyncSequence`, `AsyncStream` and `AsyncThrowingStream`.

## Requirements

- iOS 15.0+
- macOS 12.0+

## Installation

### Swift Package Manager

In Xcode:

1. Click `Project`.
2. Click `Package Dependencies`.
3. Click `+`.
4. Enter package URL: `https://github.com/reddavis/Asynchrone`.
5. Add `Asynchone` to your app target.

## Documentation

Documentation can be found [here](https://distracted-austin-575f34.netlify.app).

## Overview

### AsyncSequence

- [Extensions](https://distracted-austin-575f34.netlify.app/extensions/asyncsequence)

### [AnyAsyncSequenceable](https://distracted-austin-575f34.netlify.app/structs/anyasyncsequenceable)

```swift
let sequence = Just(1)
    .map(String.init)
    .eraseToAnyAsyncSequenceable()
```

### [AnyThrowingAsyncSequenceable](https://distracted-austin-575f34.netlify.app/structs/anythrowingasyncsequenceable)

```swift
let stream = Fail<Int, TestError>(error: TestError.a)
    .eraseToAnyThrowingAsyncSequenceable()
```

### [CombineLatestAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/combinelatestasyncsequence)

```swift
let streamA = .init { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    continuation.yield(4)
    continuation.finish()
}

let streamB = .init { continuation in
    continuation.yield(5)
    continuation.yield(6)
    continuation.yield(7)
    continuation.yield(8)
    continuation.yield(9)
    continuation.finish()
}

for await value in streamA.combineLatest(streamB) {
    print(value)
}

// Prints:
// (1, 5)
// (2, 6)
// (3, 7)
// (4, 8)
// (4, 9)
```

### [CombineLatest3AsyncSequence](https://distracted-austin-575f34.netlify.app/structs/combinelatest3asyncsequence)

```swift
let streamA = .init { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    continuation.yield(4)
    continuation.finish()
}

let streamB = .init { continuation in
    continuation.yield(5)
    continuation.yield(6)
    continuation.yield(7)
    continuation.yield(8)
    continuation.yield(9)
    continuation.finish()
}

let streamC = .init { continuation in
    continuation.yield(10)
    continuation.yield(11)
    continuation.finish()
}

for await value in streamA.combineLatest(streamB, streamC) {
    print(value)
}

// Prints:
// (1, 5, 10)
// (2, 6, 11)
// (3, 7, 11)
// (4, 8, 11)
// (4, 9, 11)
```

### [DebounceAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/debounceasyncsequence)

```swift
let stream = AsyncStream<Int> { continuation in
    continuation.yield(0)
    try? await Task.sleep(nanoseconds: 200_000_000)
    continuation.yield(1)
    try? await Task.sleep(nanoseconds: 200_000_000)
    continuation.yield(2)
    continuation.yield(3)
    continuation.yield(4)
    continuation.yield(5)
    continuation.finish()
}

for element in try await self.stream.debounce(for: 0.1) {
    print(element)
}

// Prints:
// 0
// 1
// 5
```

### [Fail](https://distracted-austin-575f34.netlify.app/structs/fail)

```swift
let stream = Fail<Int, TestError>(error: TestError())

do {
    for try await value in stream {
        print(value)
    }
} catch {
    print("Error!")
}

// Prints:
// Error!
```

### [Just](https://distracted-austin-575f34.netlify.app/structs/just)

```swift
let stream = Just(1)

for await value in stream {
    print(value)
}

// Prints:
// 1
```
 
### [MergeAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/mergeasyncsequence)

```swift
let streamA = .init { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    continuation.yield(4)
    continuation.finish()
}

let streamB = .init { continuation in
    continuation.yield(5)
    continuation.yield(6)
    continuation.yield(7)
    continuation.yield(8)
    continuation.yield(9)
    continuation.finish()
}

for await value in streamA.merge(with: streamB) {
    print(value)
}

// Prints:
// 1
// 5
// 2
// 6
// 3
// 7
// 4
// 8
// 9
```

### [Merge3AsyncSequence](https://distracted-austin-575f34.netlify.app/structs/merge3asyncsequence)

```swift
let streamA = .init { continuation in
    continuation.yield(1)
    continuation.yield(4)
    continuation.finish()
}

let streamB = .init { continuation in
    continuation.yield(2)
    continuation.finish()
}

let streamC = .init { continuation in
    continuation.yield(3)
    continuation.finish()
}

for await value in self.streamA.merge(with: self.streamB, self.streamC) {
    print(value)
}

// Prints:
// 1
// 2
// 3
// 4
```

### [RemoveDuplicatesAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/removeduplicatesasyncsequence)

```swift
let stream = .init { continuation in
    continuation.yield(1)
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    continuation.finish()
}

for await value in stream.removeDuplicates() {
    print(value)
}

// Prints:
// 1
// 2
// 3
```

### [ReplaceErrorAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/replaceerrorasyncsequence)

```swift
let sequence = Fail<Int, TestError>(
    error: TestError()
)
.replaceError(with: 0)

for await value in stream {
    print(value)
}

// Prints:
// 0
```

### [SharedAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/sharedasyncsequence)

```swift
let values = [
    "a",
    "ab",
    "abc",
    "abcd"
]

let stream = AsyncStream { continuation in
    for value in values {
        continuation.yield(value)
    }
    continuation.finish()
}
.shared()

Task {
    let values = try await self.stream.collect()
    // ...
}

Task.detached {
    let values = try await self.stream.collect()
    // ...
}

let values = try await self.stream.collect()
// ...
```

### [ThrottleAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/throttleasyncsequence)

```swift
let stream = AsyncStream<Int> { continuation in
    continuation.yield(0)
    try? await Task.sleep(nanoseconds: 100_000_000)
    continuation.yield(1)
    try? await Task.sleep(nanoseconds: 100_000_000)
    continuation.yield(2)
    continuation.yield(3)
    continuation.yield(4)
    continuation.yield(5)
    continuation.finish()
}

for element in try await self.stream.throttle(for: 0.05, latest: true) {
    print(element)
}

// Prints:
// 0
// 1
// 2
// 5
```

### [ZipAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/zipasyncsequence)

```swift
let streamA = .init { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.finish()
}

let streamB = .init { continuation in
    continuation.yield(5)
    continuation.yield(6)
    continuation.yield(7)
    continuation.finish()
}

for await value in streamA.zip(streamB) {
    print(value)
}

// Prints:
// (1, 5)
// (2, 6)
```

### [Zip3AsyncSequence](https://distracted-austin-575f34.netlify.app/structs/zip3asyncsequence)

```swift
let streamA = .init { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.finish()
}

let streamB = .init { continuation in
    continuation.yield(5)
    continuation.yield(6)
    continuation.yield(7)
    continuation.finish()
}

let streamC = .init { continuation in
    continuation.yield(8)
    continuation.yield(9)
    continuation.finish()
}

for await value in streamA.zip(streamB, streamC) {
    print(value)
}

// Prints:
// (1, 5, 8)
// (2, 6, 9)
```

### AsyncStream

- [Extensions](https://distracted-austin-575f34.netlify.app/extensions/asyncstream)

### AsyncStream.Continuation

- [Extensions](https://distracted-austin-575f34.netlify.app/extensions/asyncstream/continuation)

### AsyncThrowingStream

- [Extensions](https://distracted-austin-575f34.netlify.app/extensions/asyncthrowingstream)

### AsyncThrowingStream.Continuation

- [Extensions](https://distracted-austin-575f34.netlify.app/extensions/asyncthrowingstream/continuation)

## License

Whatevs.

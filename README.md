# Asynchrone

Extensions and additions for Swift's async sequence.

## Requirements

- iOS 14.0+
- macOS 12.0+
- watchOS 6.0+
- tvOS 14.0+

## Installation

### Swift Package Manager

In Xcode:

1. Click `Project`.
2. Click `Package Dependencies`.
3. Click `+`.
4. Enter package URL: `https://github.com/reddavis/Asynchrone`.
5. Add `Asynchrone` to your app target.

## Documentation

Documentation can be found [here](https://swiftpackageindex.com/reddavis/Asynchrone/main/documentation/asynchrone).

## Overview

### AsyncSequence

### Extensions

#### Assign

```swift
class MyClass {
    var value: Int = 0 {
        didSet { print("Set to \(self.value)") }
    }
}


let sequence = AsyncStream<Int> { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    continuation.finish()
}

let object = MyClass()
sequence.assign(to: \.value, on: object)

// Prints:
// Set to 1
// Set to 2
// Set to 3
```

#### First

```swift
let sequence = AsyncStream<Int> { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    continuation.finish()
}

print(await sequence.first())

// Prints:
// 1
```

#### Last

```swift
let sequence = AsyncStream<Int> { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    continuation.finish()
}

print(await sequence.last())

// Prints:
// 3
```

#### Collect

```swift
let sequence = AsyncStream<Int> { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    continuation.finish()
}

print(await sequence.collect())

// Prints:
// [1, 2, 3]
```

#### Sink

```swift
let sequence = .init { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    continuation.finish()
}

sequence.sink { print($0) }

// Prints:
// 1
// 2
// 3
```

#### Sink with completion

```swift
let sequence = .init { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    continuation.finish(throwing: TestError())
}

sequence.sink(
    receiveValue: { print("Value: \($0)") },
    receiveCompletion: { print("Complete: \($0)") }
)

// Prints:
// Value: 1
// Value: 2
// Value: 3
// Complete: failure(TestError())
```

### [AnyAsyncSequenceable](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/anyasyncsequenceable)

```swift
let sequence: AnyAsyncSequenceable<String> = Just(1)
    .map(String.init)
    .eraseToAnyAsyncSequenceable()
```

### [AnyThrowingAsyncSequenceable](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/anythrowingasyncsequenceable)

```swift
let stream = Fail<Int, TestError>(error: TestError.a)
    .eraseToAnyThrowingAsyncSequenceable()
```

### [CatchErrorAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/catcherrorasyncsequence)

```swift
let sequence = Fail<Int, TestError>(
    error: TestError()
)
.catch { error in
    Just(-1)
}

for await value in sequence {
    print(value)
}

// Prints:
// -1
```

### [ChainAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/chainasyncsequence)

```swift
let sequenceA = AsyncStream<Int> { continuation in
    continuation.yield(1)
    continuation.yield(2)
    continuation.yield(3)
    continuation.finish()
}

let sequenceB = AsyncStream<Int> { continuation in
    continuation.yield(4)
    continuation.yield(5)
    continuation.yield(6)
    continuation.finish()
}

let sequenceC = AsyncStream<Int> { continuation in
    continuation.yield(7)
    continuation.yield(8)
    continuation.yield(9)
    continuation.finish()
}

for await value in sequenceA.chain(with: sequenceB).chain(with: sequenceC) {
    print(value)
}

// Prints:
// 1
// 2
// 3
// 4
// 5
// 6
// 7
// 8
// 9
```

### [CombineLatestAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/combinelatestasyncsequence)

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

### [CombineLatest3AsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/combinelatest3asyncsequence)

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

### [CurrentElementAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/currentelementasyncsequence)

```swift
let sequence = CurrentElementAsyncSequence(0)
print(await sequence.element)

await stream.yield(1)
print(await sequence.element)

await stream.yield(2)
await stream.yield(3)
await stream.yield(4)
print(await sequence.element)

// Prints:
// 0
// 1
// 4
```

### [DebounceAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/debounceasyncsequence)

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

### [DelayAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/delayasyncsequence)

```swift
let stream = AsyncStream<Int> { continuation in
    continuation.yield(0)
    continuation.yield(1)
    continuation.yield(2)
    continuation.finish()
}

let start = Date.now
for element in try await self.stream.delay(for: 0.5) {
    print("\(element) - \(Date.now.timeIntervalSince(start))")
}

// Prints:
// 0 - 0.5
// 1 - 1.0
// 2 - 1.5
>>>>>>> main
```

### [Empty](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/empty)

```swift
Empty<Int>().sink(
    receiveValue: { print($0) },
    receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Finished")
        case .failure:
            print("Failed")
        }
    }
)

// Prints:
// Finished
```

### [Fail](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/fail)

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

### [Just](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/just)

```swift
let stream = Just(1)

for await value in stream {
    print(value)
}

// Prints:
// 1
```
 
### [MergeAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/mergeasyncsequence)

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

### [Merge3AsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/merge3asyncsequence)

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

### [NotificationCenterAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/notificationcenterasyncsequence)

```swift
let sequence = NotificationCenter.default.sequence(for: UIDevice.orientationDidChangeNotification)

for await element in sequence {
    print(element)
}

```

### [PassthroughAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/passthroughasyncsequence)

```swift
let sequence = PassthroughAsyncSequence<Int>()
sequence.yield(0)
sequence.yield(1)
sequence.yield(2)
sequence.finish()

for await value in sequence {
    print(value)
}

// Prints:
// 0
// 1
// 2
```

### [RemoveDuplicatesAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/removeduplicatesasyncsequence)

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

### [ReplaceErrorAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/replaceerrorasyncsequence)

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

### [SequenceAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/sequenceasyncsequence)

```swift
let sequence = [0, 1, 2, 3].async

for await value in sequence {
    print(value)
}

// Prints:
// 1
// 2
// 3
```

### [SharedAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/sharedasyncsequence)

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

### [ThrottleAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/throttleasyncsequence)

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

### [ThrowingPassthroughAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/throwingpassthroughasyncsequence)

```swift
let sequence = ThrowingPassthroughAsyncSequence<Int>()
sequence.yield(0)
sequence.yield(1)
sequence.yield(2)
sequence.finish(throwing: TestError())

do {
    for try await value in sequence {
      print(value)
    }
} catch {
    print("Error!")
}

// Prints:
// 0
// 1
// 2
// Error!
```

### [TimerAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/timerasyncsequence)

```swift
let sequence = TimerAsyncSequence(interval: 1)

let start = Date.now
for element in await sequence {
    print(element)
}

// Prints:
// 2022-03-19 20:49:30 +0000
// 2022-03-19 20:49:31 +0000
// 2022-03-19 20:49:32 +0000
```

### [ZipAsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/zipasyncsequence)

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

### [Zip3AsyncSequence](https://swiftpackageindex.com/reddavis/asynchrone/main/documentation/asynchrone/zip3asyncsequence)

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

## Other libraries

- [Papyrus](https://github.com/reddavis/Papyrus) - Papyrus aims to hit the sweet spot between saving raw API responses to the file system and a fully fledged database like Realm.
- [Validate](https://github.com/reddavis/Validate) - A property wrapper that can validate the property it wraps.
- [Kyu](https://github.com/reddavis/Kyu) - A persistent queue system in Swift.
- [FloatingLabelTextFieldStyle](https://github.com/reddavis/FloatingLabelTextFieldStyle) - A floating label style for SwiftUI's TextField.
- [Panel](https://github.com/reddavis/Panel) - A panel component similar to the iOS Airpod battery panel.

# Asynchone

Extensions and additions to `AsyncSequence`, `AsyncStream` and `AsyncThrowingStream`.

## Requirements

- iOS 14.0+
- macOS 12.0+

## Installation

### Swift Package Manager

In Xcode:

1. Click `Project`.
2. Click `Package Dependencies`.
3. Click `+`.
4. Enter package URL: `https://github.com/reddavis/Asynchrone`.
5. Add `Asynchrone` to your app target.

## Documentation

Documentation can be found [here](https://distracted-austin-575f34.netlify.app).

## Overview

### AsyncSequence

### [Extensions](https://distracted-austin-575f34.netlify.app/extensions/asyncsequence)

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

### [CatchErrorAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/catcherrorasyncsequenceable)

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

### [ChainAsyncSequenceable](https://distracted-austin-575f34.netlify.app/structs/chainasyncsequenceable)

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

### [CurrentElementAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/currentelementasyncsequence)

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

### [DelayAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/delayasyncsequence)

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

### [Empty](https://distracted-austin-575f34.netlify.app/structs/empty)

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

### [NotificationCenterAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/notificationcenterasyncsequence)

```swift
let sequence = NotificationCenter.default.sequence(for: UIDevice.orientationDidChangeNotification)

for await element in sequence {
    print(element)
}

```

### [PassthroughAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/passthroughasyncsequence)

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

### [SequenceAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/sequenceasyncsequence)

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

### [ThrowingPassthroughAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/throwingpassthroughasyncsequence)

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

### [TimerAsyncSequence](https://distracted-austin-575f34.netlify.app/structs/timerasyncsequence)

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

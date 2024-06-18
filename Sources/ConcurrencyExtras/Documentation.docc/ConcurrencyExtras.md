# ``ConcurrencyExtras``

Useful, testable Swift concurrency.

## Overview

This library comes with a number of tools that make working with Swift concurrency easier and more
testable.

### ActorIsolated and LockIsolated

The ``ActorIsolated`` and ``LockIsolated`` types help wrap other values in an isolated context.
`ActorIsolated` wraps the value in an actor so that the only way to access and mutate the value is
through an async/await interface. ``LockIsolated`` wraps the value in a class with a lock, which
allows you to read and write the value with a synchronous interface. You should prefer to use
`ActorIsolated` when you have access to an asynchronous context.

### Streams

The library comes with numerous helper APIs spread across the two Swift stream types:

  * There are helpers that erase any `AsyncSequence` conformance to either concrete stream type.
    This allows you to treat the stream type as a kind of "type erased" `AsyncSequence`.

    For example, suppose you have a dependency client like this:

    ```swift
    struct ScreenshotsClient {
      var screenshots: () -> AsyncStream<Void>
    }
    ```

    Then you can construct a live implementation that "erases" the
    `NotificationCenter.Notifications` async sequence to a stream:

    ```swift
    extension ScreenshotsClient {
      static let live = Self(
        screenshots: {
          NotificationCenter.default
            .notifications(named: UIApplication.userDidTakeScreenshotNotification)
            .map { _ in }
            .eraseToStream()  // ⬅️
        }
      )
    }
    ```

    Use `eraseToThrowingStream()` to propagate failures from throwing async sequences.

  * There is an API for simultaneously constructing a stream and its backing continuation. This can
    be handy in tests when overriding a dependency endpoint that returns a stream:

    ```swift
    let screenshots = AsyncStream<Void>.streamWithContinuation()
    let model = FeatureModel(screenshots: screenshots.stream)

    XCTAssertEqual(model.screenshotCount, 0)
    screenshots.continuation.yield()  // Simulate a screenshot being taken.
    XCTAssertEqual(model.screenshotCount, 1)
    ```

  * Static `AsyncStream.never` and `AsyncThrowingStream.never` helpers are provided that represent
    streams that live forever and never emit. They can be handy in tests that need to override a
    dependency endpoint with a stream that should suspend and never emit for the duration test.

  * Static `AsyncStream.finished` and `AsyncThrowingStream.finished(throwing:)` helpers are provided
    that represents streams that complete immediately without emitting. They can be handy in tests
    that need to override a dependency endpoint with a stream that completes/fails immediately.

### Tasks

The library comes with a static function, `Task.never()`, that can asynchronously return a value of
any type, but does so by suspending forever. This can be useful for satisfying a dependency
requirement in a way that does not require you to actually return data from that endpoint.

### UncheckedSendable

A wrapper type that can make any type `Sendable`, but in an unsafe and unchecked way. This type
should only be used as an alternative to `@preconcurrency import`, which turns off concurrency
checks for everything in the library. Whereas ``UncheckedSendable`` allows you to turn off
concurrency warnings for just one single usage of a particular type.

While [SE-0302][se-0302] mentions future work of ["Adaptor Types for Legacy
Codebases"][se-0302-unsafetransfer], including an `UnsafeTransfer` type that serves the same
purpose, it has not landed in Swift.

[se-0302]: https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md
[se-0302-unsafetransfer]: https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md#adaptor-types-for-legacy-codebases

### Serial execution

Some asynchronous code is [notoriously difficult][reliably-testing-swift-concurrency] to test in
Swift due to how suspension points are processed by the runtime. The library comes with a static
function, ``withMainSerialExecutor(operation:)-79jpc``, that runs all tasks spawned in an operation
serially and deterministically. This function can be used to make asynchronous tests faster and less
flakey.

Note that running async tasks serially does not mean that multiple concurrent tasks are not able to
interleave. Suspension of async tasks still works just as you would expect, but all tasks are run on
the unique, main thread.

For example, consider the following simple `ObservableObject` implementation for a feature that
wants to count the number of times a screenshot is taken of the screen:

```swift
class FeatureModel: ObservableObject {
  @Published var count = 0
  @MainActor
  func onAppear() async {
    let screenshots = NotificationCenter.default.notifications(
      named: UIApplication.userDidTakeScreenshotNotification
    )
    for await _ in screenshots {
      self.count += 1
    }
  }
}
```

This is quite a simple feature, but in the future it could start doing more complicated things,
such as performing a network request when it detects a screenshot being taken.

So, it would be great if we could get some test coverage on this feature. To do this we can create
a model, and spin up a new task to invoke the `onAppear` method:

```swift
func testBasics() async {
  let model = ViewModel()
  let task = Task { await model.onAppear() }
}
```

Then we can use `Task.yield()` to allow the subscription of the stream of notifications to start:

```swift
func testBasics() async {
  let model = ViewModel()
  let task = Task { await model.onAppear() }

  // Give the task an opportunity to start executing its work.
  await Task.yield()
}
```

Then we can simulate the user taking a screenshot by posting a notification:

```swift
func testBasics() async {
  let model = ViewModel()
  let task = Task { await model.onAppear() }

  // Give the task an opportunity to start executing its work.
  await Task.yield()

  // Simulate a screen shot being taken.
  NotificationCenter.default.post(
    name: UIApplication.userDidTakeScreenshotNotification, object: nil
  )
}
```

And then finally we can yield again to process the new notification and assert that the count
incremented by 1:

```swift
func testBasics() async {
  let model = ViewModel()
  let task = Task { await model.onAppear() }

  // Give the task an opportunity to start executing its work.
  await Task.yield()

  // Simulate a screen shot being taken.
  NotificationCenter.default.post(
    name: UIApplication.userDidTakeScreenshotNotification, object: nil
  )

  // Give the task an opportunity to update the view model.
  await Task.yield()

  XCTAssertEqual(model.count, 1)
}
```

This seems like a perfectly reasonable test, and it does pass… sometimes. If you run it enough
times you will eventually get a failure (about 6% of the time). This is happening because sometimes
the single `Task.yield()` is not enough for the subscription to the stream of notifications to
actually start. In that case we will post the notification before we have actually subscribed,
causing a test failure.

If we wrap the entire test in ``withMainSerialExecutor(operation:)-79jpc``, then it will pass
deterministically, 100% of the time:

```swift
func testBasics() async {
  await withMainSerialExecutor {
    …
  }
}
```

This is because now all tasks are enqueued on the serial, main executor, and so when we `Task.yield`
we can be sure that the `onAppear` method will execute until it reaches a suspension point. This
guarantees that the subscription to the stream of notifications will start when we expect it to.

You can also use ``withMainSerialExecutor(operation:)-7fqt1`` to wrap an entire test case by
overriding the `invokeTest` method:

```swift
final class FeatureModelTests: XCTestCase {
  override func invokeTest() {
    withMainSerialExecutor {
      super.invokeTest()
    }
  }
  …
}
```

Now the entire `FeatureModelTests` test case will be run on the main, serial executor.

Note that by using ``withMainSerialExecutor(operation:)-79jpc`` you are technically making your
tests behave in a manner that is different from how they would run in production. However, many
tests written on a day-to-day basis due not invoke the full-blown vagaries of concurrency. Instead
the tests want to assert that some user action happens, an async unit of work is executed, and
that causes some state to change. Such tests should be written in a way that is 100% deterministic.

If your code has truly complex asynchronous and concurrent operations, then it may be handy to write
two sets of tests: one set that targets the main executor (using
``withMainSerialExecutor(operation:)-79jpc``) so that you can deterministically assert how the core
system behaves, and then another set that targets the default, global executor that will probably
need to make weaker assertions due to non-determinism, but can still assert on some things.

[reliably-testing-swift-concurrency]: https://forums.swift.org/t/reliably-testing-code-that-adopts-swift-concurrency/57304

## Topics

### Data races

- ``ActorIsolated``
- ``LockIsolated``

### Serial execution

- ``withMainSerialExecutor(operation:)-79jpc``

### Preconcurrency

- ``UncheckedSendable``

# swift-concurrency-extras

[![CI](https://github.com/pointfreeco/swift-concurrency-extras/workflows/CI/badge.svg)](https://github.com/pointfreeco/swift-concurrency-extras/actions?query=workflow%3ACI)
[![Slack](https://img.shields.io/badge/slack-chat-informational.svg?label=Slack&logo=slack)](https://www.pointfree.co/slack-invite)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-concurrency-extras%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-concurrency-extras)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-concurrency-extras%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-concurrency-extras)

Reliably testable Swift concurrency.

  * [Motivation](#motivation)
      * [`ActorIsolated` and `LockIsolated`](#actorisolated-and-lockisolated)
      * [Streams](#streams)
      * [Tasks](#tasks)
      * [`UncheckedSendable`](#uncheckedsendable)
      * [Serial execution](#serial-execution)
  * [Documentation](#documentation)
  * [Other libraries](#other-libraries)
  * [Learn more](#learn-more)
  * [License](#License)

## Learn more

This library was designed to support libraries and episodes produced for [Point-Free][point-free], a
video series exploring the Swift programming language hosted by [Brandon Williams][mbrandonw] and
[Stephen Celis][stephencelis].

You can watch all of the episodes [here](https://www.pointfree.co/collections/concurrency).

<a href="https://www.pointfree.co/collections/concurrency/">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0238.jpeg" width="600">
</a>

## Motivation

This library comes with a number of tools that make working with Swift concurrency easier and more
testable.

  * [`ActorIsolated` and `LockIsolated`](#actorisolated-and-lockisolated)
  * [Streams](#streams)
  * [Tasks](#tasks)
  * [`UncheckedSendable`](#uncheckedsendable)
  * [Serial execution](#serial-execution)

### `ActorIsolated` and `LockIsolated`

The `ActorIsolated` and `LockIsolated` types help wrap other values in an isolated context.
`ActorIsolated` wraps the value in an actor so that the only way to access and mutate the value is
through an async/await interface. `LockIsolated` wraps the value in a class with a lock, which
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

  * Swift 5.9's `makeStream(of:)` functions have been back-ported. It can handy in tests that need
    to override a dependency endpoint that returns a stream:

    ```swift
    let screenshots = AsyncStream.makeStream(of: Void.self)

    let model = FeatureModel(screenshots: { screenshots.stream })

    XCTAssertEqual(model.screenshotCount, 0)
    screenshots.continuation.yield()  // Simulate a screenshot being taken.
    XCTAssertEqual(model.screenshotCount, 1)
    ```

  * Static `AsyncStream.never` and `AsyncThrowingStream.never` helpers are provided that represent
    streams that live forever and never emit. They can be handy in tests that need to override a
    dependency endpoint with a stream that should suspend and never emit for the duration of the
    test.

    ```swift
    let model = FeatureModel(screenshots: { .never })
    ```

  * Static `AsyncStream.finished` and `AsyncThrowingStream.finished(throwing:)` helpers are provided
    that represents streams that complete immediately without emitting. They can be handy in tests
    that need to override a dependency endpoint with a stream that completes/fails immediately.

### Tasks

The library enhances the `Task` type with new functionality.

  * The static function `Task.never()` can asynchronously return a value of any type, but does so by
    suspending forever. This can be useful for satisfying a dependency requirement in a way that
    does not require you to actually return data from that endpoint.

    For example, suppose you have a dependency client like this:

    ```swift
    struct SettingsClient {
      var fetchSettings: () async throws -> Settings
    }
    ```

    You can override the client's `fetchSettings` endpoint in tests to suspend forever by awaiting
    `Task.never()`:

    ```swift
    SettingsClient(
      fetchSettings: { try await Task.never() }
    )
    ```

  * `Task.cancellableValue` is a property that awaits the unstructured task's `value` property while
    propagating cancellation from the current async context.

  * `Task.megaYield()` is a blunt tool that can make flakey async tests a little less flakey by
    suspending the current task a number of times and improve the odds that other async work has
    enough time to start. Prefer the reliability of [serial execution](#serial-execution) instead
    where possible.

### `UncheckedSendable`

A wrapper type that can make any type `Sendable`, but in an unsafe and unchecked way. This type
should only be used as an alternative to `@preconcurrency import`, which turns off concurrency
checks for everything in the library. Whereas `UncheckedSendable` allows you to turn off concurrency
warnings for just one single usage of a particular type.

While [SE-0302][se-0302] mentions future work of ["Adaptor Types for Legacy
Codebases"][se-0302-unsafetransfer], including an `UnsafeTransfer` type that serves the same
purpose, it has not landed in Swift.

### Serial execution

Some asynchronous code is [notoriously difficult][reliably-testing-swift-concurrency] to test in
Swift due to how suspension points are processed by the runtime. The library comes with a static
function, `withMainSerialExecutor`, that runs all tasks spawned in an operation serially and
deterministically. This function can be used to make asynchronous tests faster and less flakey.

For example, consider the following seemingly simple model that makes a network request and manages
so `isLoading` state while the request is inflight:

```swift
@Observable
class NumberFactModel {
  var fact: String?
  var isLoading = false
  var number = 0

  // Inject the request dependency explicitly to make it testable, but can also
  // be provided via a dependency management library.
  let getFact: (Int) async throws -> String

  func getFactButtonTapped() async {
    self.isLoading = true
    defer { self.isLoading = false }
    do {
      self.fact = try await self.getFact(self.number)
    } catch {
      // TODO: Handle error
    }
  }
}
```

We would love to be able to write a test that allows us to confirm that the `isLoading` state
flips to `true` and then `false`. You might hope that it is as easy as this:

```swift
func testIsLoading() async {
  let model = NumberFactModel(getFact: { "\($0) is a good number" })

  let task = Task { await model.getFactButtonTapped() }
  XCTAssertEqual(model.isLoading, true)
  XCTAssertEqual(model.fact, nil)

  await task.value
  XCTAssertEqual(model.isLoading, false)
  XCTAssertEqual(model.fact, "0 is a good number.")
}
```

However this fails almost 100% of the time. The problem is that the line immediately after creating
the unstructured `Task` executes before the line _inside_ the unstructured task, and so we never
detect the moment the `isLoading` state flips to `true`.

You might hope you can wiggle yourself in between the moment the `getFactButtonTapped` method is
called and the moment the request finishes by using a `Task.yield`:

```diff
 func testIsLoading() async {
   let model = NumberFactModel(getFact: { "\($0) is a good number" })

   let task = Task { await model.getFactButtonTapped() }
+  await Task.yield()
   XCTAssertEqual(model.isLoading, true)
   XCTAssertEqual(model.fact, nil)

   await task.value
   XCTAssertEqual(model.isLoading, false)
   XCTAssertEqual(model.fact, "0 is a good number.")
 }
```

But that still fails the vast majority of times.

These problems, and more, can be fixed by running this entire test on the main serial executor:

```diff
 func testIsLoading() async {
+  withMainSerialExecutor {
     let model = NumberFactModel(getFact: { "\($0) is a good number" })

     let task = Task { await model.getFactButtonTapped() }
     await Task.yield()
     XCTAssertEqual(model.isLoading, true)
     XCTAssertEqual(model.fact, nil)

     await task.value
     XCTAssertEqual(model.isLoading, false)
     XCTAssertEqual(model.fact, "0 is a good number.")
+  }
 }
```

That one change makes this test pass deterministically, 100% of the time.


## Documentation

The latest documentation for this library is available [here][concurrency-extras-docs].

## Credits and thanks

Thanks to Pat Brown and [Thomas Grapperon](https://twitter.com/tgrapperon) for providing feedback on
the library before its release. Special thanks to [Kabir Oberai](https://twitter.com/kabiroberai)
who helped us work around an Xcode bug and ship serial execution tools with the library.

## Other libraries

Concurrency Extras is just one library that makes it easier to write testable code in Swift.

  * [Case Paths][swift-case-paths]: Tools for working with and testing enums.

  * [Clocks][swift-clocks]: A few clocks that make working with Swift concurrency more testable and
    more versatile.

  * [Combine Schedulers][combine-schedulers]: A few schedulers that make working with Combine more
    testable and more versatile.

  * [Composable Architecture][swift-composable-architecture]: A library for building applications in
    a consistent and understandable way, with composition, testing, and ergonomics in mind.

  * [Custom Dump][swift-custom-dump]: A collection of tools for debugging, diffing, and testing your
    application's data structures.

  * [Dependencies][swift-dependencies]: A dependency management library inspired by SwiftUI's
    "environment."

  * [Snapshot Testing][swift-snapshot-testing]: Assert on your application by recording and
    and asserting against artifacts.

  * [XCTest Dynamic Overlay][xctest-dynamic-overlay]: Call `XCTFail` and other typically test-only
    helpers from application code.

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-async-algorithms]: http://github.com/apple/swift-async-algorithms
[point-free]: https://www.pointfree.co
[mbrandonw]: https://github.com/mbrandonw
[stephencelis]: https://github.com/stephencelis
[concurrency-testing-collection]: https://www.pointfree.co/collections/concurrency/testing-async-code
[concurrency-extras-docs]: http://pointfreeco.github.io/swift-concurrency-extras/main/documentation/concurrencyextras
[se-0302]: https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md
[se-0302-unsafetransfer]: https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md#adaptor-types-for-legacy-codebases
[reliably-testing-swift-concurrency]: https://forums.swift.org/t/reliably-testing-code-that-adopts-swift-concurrency/57304
[swift-case-paths]: http://github.com/pointfreeco/swift-case-paths
[swift-clocks]: http://github.com/pointfreeco/swift-clocks
[combine-schedulers]: http://github.com/pointfreeco/combine-schedulers
[swift-composable-architecture]: http://github.com/pointfreeco/swift-composable-architecture
[swift-custom-dump]: http://github.com/pointfreeco/swift-custom-dump
[swift-dependencies]: http://github.com/pointfreeco/swift-dependencies
[swift-snapshot-testing]: http://github.com/pointfreeco/swift-snapshot-testing
[xctest-dynamic-overlay]: http://github.com/pointfreeco/xctest-dynamic-overlay

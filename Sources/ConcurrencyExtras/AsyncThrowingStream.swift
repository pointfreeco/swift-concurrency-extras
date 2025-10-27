import Foundation

extension AsyncThrowingStream where Failure == Error {
  /// Produces an `AsyncThrowingStream` from an `AsyncSequence` by consuming the sequence till it
  /// terminates, rethrowing any failure.
  ///
  /// - Parameter sequence: An async sequence.
  public init<S: AsyncSequence>(_ sequence: S) where S.Element == Element, S: Sendable {
    let lock = NSLock()
    let iterator = UncheckedBox<S.AsyncIterator?>(wrappedValue: nil)
    self.init {
      lock.withLock {
        if iterator.wrappedValue == nil {
          iterator.wrappedValue = sequence.makeAsyncIterator()
        }
      }
      return try await iterator.wrappedValue?.next()
    }
  }

  @available(
    *, deprecated,
    message: "Explicitly wrap the given async sequence with 'UncheckedSendable' first."
  )
  @_disfavoredOverload
  public init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
    self.init(UncheckedSendable(sequence))
  }

  /// An `AsyncThrowingStream` that never emits and never completes unless cancelled.
  public static var never: Self {
    Self { _ in }
  }

  /// An `AsyncThrowingStream` that completes immediately.
  ///
  /// - Parameter error: An optional error the stream completes with.
  public static func finished(throwing error: Failure? = nil) -> Self {
    Self { $0.finish(throwing: error) }
  }
}

extension AsyncSequence {
  /// Erases this async sequence to an async throwing stream that produces elements till this
  /// sequence terminates, rethrowing any error on failure.
  public func eraseToThrowingStream() -> AsyncThrowingStream<Element, Error> where Self: Sendable {
    AsyncThrowingStream(self)
  }

  @available(
    *, deprecated,
    message:
      "Explicitly wrap this async sequence with 'UncheckedSendable' before erasing to throwing stream."
  )
  public func eraseToThrowingStream() -> AsyncThrowingStream<Element, Error> {
    AsyncThrowingStream(UncheckedSendable(self))
  }
}

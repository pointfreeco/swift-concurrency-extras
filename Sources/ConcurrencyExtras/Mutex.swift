#if compiler(>=6)
  import Foundation

  /// A synchronization primitive that protects shared mutable state via mutual exclusion.
  ///
  /// A back-port of Swift's `Mutex` type for wider platform availability.
  @_staticExclusiveOnly
  @available(iOS, obsoleted: 18, message: "Use 'Synchronization.Mutex', instead.")
  @available(macOS, obsoleted: 15, message: "Use 'Synchronization.Mutex', instead.")
  @available(tvOS, obsoleted: 18, message: "Use 'Synchronization.Mutex', instead.")
  @available(visionOS, obsoleted: 2, message: "Use 'Synchronization.Mutex', instead.")
  @available(watchOS, obsoleted: 11, message: "Use 'Synchronization.Mutex', instead.")
  public struct Mutex<Value: ~Copyable>: ~Copyable {
    private let lock = NSLock()
    private let box: Box

    /// Initializes a value of this mutex with the given initial state.
    ///
    /// - Parameter initialValue: The initial value to give to the mutex.
    public init(_ initialValue: consuming sending Value) {
      box = Box(initialValue)
    }

    private final class Box {
      var value: Value
      init(_ initialValue: consuming sending Value) {
        value = initialValue
      }
    }
  }

  extension Mutex: @unchecked Sendable where Value: ~Copyable {}

  extension Mutex where Value: ~Copyable {
    /// Calls the given closure after acquiring the lock and then releases ownership.
    public borrowing func withLock<Result: ~Copyable, E: Error>(
      _ body: (inout sending Value) throws(E) -> sending Result
    ) throws(E) -> sending Result {
      lock.lock()
      defer { lock.unlock() }
      return try body(&box.value)
    }

    /// Attempts to acquire the lock and then calls the given closure if successful.
    public borrowing func withLockIfAvailable<Result: ~Copyable, E: Error>(
      _ body: (inout sending Value) throws(E) -> sending Result
    ) throws(E) -> sending Result? {
      guard lock.try() else { return nil  }
      defer { lock.unlock() }
      return try body(&box.value)
    }
  }

  extension Mutex where Value == Void {
    public borrowing func _unsafeLock() {
      lock.lock()
    }

    public borrowing func _unsafeTryLock() -> Bool {
      lock.try()
    }

    public borrowing func _unsafeUnlock() {
      lock.unlock()
    }
  }
#endif

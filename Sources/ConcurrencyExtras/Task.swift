import Foundation

extension Task where Success == Never, Failure == Never {
  /// Suspends the current task a number of times before resuming with the goal of allowing other
  /// tasks to start their work.
  ///
  /// This function can be used to make flakey async tests less flakey, as described in
  /// [this Swift Forums post](https://forums.swift.org/t/reliably-testing-code-that-adopts-swift-concurrency/57304).
  /// You may, however, prefer to use ``withMainSerialExecutor(operation:)-79jpc`` to improve the
  /// reliability of async tests, and to make their execution deterministic.
  ///
  /// > Note: When invoked from ``withMainSerialExecutor(operation:)-79jpc``, or when
  /// > ``uncheckedUseMainSerialExecutor`` is set to `true`, `Task.megaYield()` is equivalent to
  /// > a single `Task.yield()`.
  public static func megaYield(count: Int = _defaultMegaYieldCount) async {
    // TODO: Investigate why mega yields are still necessary in TCA's test suite.
    // guard !uncheckedUseMainSerialExecutor else {
    //   await Task.yield()
    //   return
    // }
    for _ in 0..<count {
      await Task<Void, Never>.detached(priority: .background) { await Task.yield() }.value
    }
  }
}

/// The number of yields `Task.megaYield()` invokes by default.
///
/// Can be overridden by setting the `TASK_MEGA_YIELD_COUNT` environment variable.
public let _defaultMegaYieldCount = max(
  0,
  min(
    ProcessInfo.processInfo.environment["TASK_MEGA_YIELD_COUNT"].flatMap(Int.init) ?? 20,
    10_000
  )
)

extension Task where Failure == Never {
  /// An async function that never returns.
  public static func never() async throws -> Success {
    for await element in AsyncStream<Success>.never {
      return element
    }
    throw _Concurrency.CancellationError()
  }
}

extension Task where Success == Never, Failure == Never {
  /// An async function that never returns.
  public static func never() async throws {
    for await _ in AsyncStream<Never>.never {}
    throw _Concurrency.CancellationError()
  }
}

extension Task where Failure == Never {
  /// Waits for the result of the task, propagating cancellation to the task.
  ///
  /// Equivalent to wrapping a call to `Task.value` in `withTaskCancellationHandler`.
  public var cancellableValue: Success {
    get async {
      await withTaskCancellationHandler {
        await self.value
      } onCancel: {
        self.cancel()
      }
    }
  }
}

extension Task where Failure == Error {
  /// Waits for the result of the task, propagating cancellation to the task.
  ///
  /// Equivalent to wrapping a call to `Task.value` in `withTaskCancellationHandler`.
  public var cancellableValue: Success {
    get async throws {
      try await withTaskCancellationHandler {
        try await self.value
      } onCancel: {
        self.cancel()
      }
    }
  }
}

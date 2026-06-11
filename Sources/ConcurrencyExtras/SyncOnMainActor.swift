import Foundation

/// Executes operation syncroniously on MainActor
///
/// This function does not cause a deadlock when called
/// from MainActor
///
/// - Parameters:
///   - operation: Closure to execute
/// - Throws: Error from the operation if any
/// - Returns: Result of the operation if any
@discardableResult
@inlinable
public func syncOnMainActor<T: Sendable>(
  perform operation: @MainActor () throws -> T
) rethrows -> T {
  guard Thread.isMainThread
  else { return try DispatchQueue.main.sync(execute: operation) }

  return try MainActor.assumeIsolated(operation)
}

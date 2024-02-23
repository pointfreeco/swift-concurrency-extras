import Foundation

/// Perform an operation on the main serial executor.
///
/// Some asynchronous code is [notoriously
/// difficult](https://forums.swift.org/t/reliably-testing-code-that-adopts-swift-concurrency/57304)
/// to test in Swift due to how suspension points are processed by the runtime. This function runs
/// all tasks spawned in the given operation serially and deterministically. It makes asynchronous
/// tests faster and less flakey.
///
/// ```swift
/// await withMainSerialExecutor {
///   // Everything performed in this scope is performed serially...
/// }
/// ```
///
/// - Parameter operation: An operation to be performed on the main serial executor.
@MainActor
public func withMainSerialExecutor(
  @_implicitSelfCapture operation: @MainActor @Sendable () async throws -> Void
) async rethrows {
  let didUseMainSerialExecutor = uncheckedUseMainSerialExecutor
  defer { uncheckedUseMainSerialExecutor = didUseMainSerialExecutor }
  uncheckedUseMainSerialExecutor = true
  try await operation()
}

/// Perform an operation on the main serial executor.
///
/// A synchronous version of ``withMainSerialExecutor(operation:)-79jpc`` that can be used in
/// `XCTestCase.invokeTest` to ensure all async tests are performed serially:
///
/// ```swift
/// class BaseTestCase: XCTestCase {
///   override func invokeTest() {
///     withMainSerialExecutor {
///       super.invokeTest()
///     }
///   }
/// }
/// ```
///
/// - Parameter operation: An operation to be performed on the main serial executor.
public func withMainSerialExecutor(
  @_implicitSelfCapture operation: () throws -> Void
) rethrows {
  let didUseMainSerialExecutor = uncheckedUseMainSerialExecutor
  defer { uncheckedUseMainSerialExecutor = didUseMainSerialExecutor }
  uncheckedUseMainSerialExecutor = true
  try operation()
}

/// Overrides Swift's global executor with the main serial executor in an unchecked fashion.
///
/// > Warning: When set to `true`, all tasks will be enqueued on the main serial executor till set
/// > back to `false`. Consider using ``withMainSerialExecutor(operation:)-79jpc``, instead, which
/// > scopes this work to the duration of a given operation.
public var uncheckedUseMainSerialExecutor: Bool {
  get { swift_task_enqueueGlobal_hook != nil }
  set {
    swift_task_enqueueGlobal_hook =
      newValue
      ? { job, _ in MainActor.shared.enqueue(job) }
      : nil
  }
}

private typealias Original = @convention(thin) (UnownedJob) -> Void
private typealias Hook = @convention(thin) (UnownedJob, Original) -> Void

private var swift_task_enqueueGlobal_hook: Hook? {
  get { _swift_task_enqueueGlobal_hook.pointee }
  set { _swift_task_enqueueGlobal_hook.pointee = newValue }
}
private let _swift_task_enqueueGlobal_hook: UnsafeMutablePointer<Hook?> =
  dlsym(dlopen(nil, 0), "swift_task_enqueueGlobal_hook").assumingMemoryBound(to: Hook?.self)

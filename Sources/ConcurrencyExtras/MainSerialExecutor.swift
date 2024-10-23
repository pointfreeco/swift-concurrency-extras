#if !os(WASI) && !os(Windows) && !os(Android)
  import Foundation

  #if compiler(>=6)
    /// Perform an operation on the main serial executor.
    ///
    /// Some asynchronous code is [notoriously
    /// difficult](https://forums.swift.org/t/reliably-testing-code-that-adopts-swift-concurrency/57304)
    /// to test in Swift due to how suspension points are processed by the runtime. This function
    /// attempts to run all tasks spawned in the given operation serially and deterministically. It
    /// makes asynchronous tests faster and less flakey.
    ///
    /// ```swift
    /// await withMainSerialExecutor {
    ///   // Everything performed in this scope is performed serially...
    /// }
    /// ```
    ///
    /// See <doc:ReliablyTestingAsync> for more information on why this tool is needed to test
    /// async code and how to use it.
    ///
    /// > Warning: This API is only intended to be used from tests to make them more reliable. Please do
    /// > not use it from application code.
    /// >
    /// > We say that it "_attempts_ to run all tasks spawned in an operation serially and
    /// > deterministically" because under the hood it relies on a global, mutable variable in the Swift
    /// > runtime to do its job, and there are no scoping _guarantees_ should this mutable variable change
    /// > during the operation.
    ///
    /// - Parameter operation: An operation to be performed on the main serial executor.
    @MainActor
    public func withMainSerialExecutor(
      @_implicitSelfCapture operation: @isolated(any) () async throws -> Void
    ) async rethrows {
      let didUseMainSerialExecutor = uncheckedUseMainSerialExecutor
      defer { uncheckedUseMainSerialExecutor = didUseMainSerialExecutor }
      uncheckedUseMainSerialExecutor = true
      try await operation()
    }
  #else
    @MainActor
    public func withMainSerialExecutor(
      @_implicitSelfCapture operation: @Sendable () async throws -> Void
    ) async rethrows {
      let didUseMainSerialExecutor = uncheckedUseMainSerialExecutor
      defer { uncheckedUseMainSerialExecutor = didUseMainSerialExecutor }
      uncheckedUseMainSerialExecutor = true
      try await operation()
    }
  #endif

  /// Perform an operation on the main serial executor.
  ///
  /// A synchronous version of ``withMainSerialExecutor(operation:)-7fqt1`` that can be used in
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
  /// > back to `false`. Consider using ``withMainSerialExecutor(operation:)-7fqt1``, instead, which
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
    get { _swift_task_enqueueGlobal_hook.wrappedValue.pointee }
    set { _swift_task_enqueueGlobal_hook.wrappedValue.pointee = newValue }
  }
  private let _swift_task_enqueueGlobal_hook = UncheckedSendable(
    dlsym(dlopen(nil, 0), "swift_task_enqueueGlobal_hook").assumingMemoryBound(to: Hook?.self)
  )
#endif

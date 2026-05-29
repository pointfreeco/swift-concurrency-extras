#if compiler(>=6.1)
  public import Testing

  extension Trait {
    /// Override a task local value for the duration of a test or suite.
    ///
    /// ```swift
    /// @Suite(.taskLocal($myValue, 42)) struct MyTests {
    ///   // ...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - taskLocal: The task local to override.
    ///   - value: The value to set.
    public static func taskLocal<Value: Sendable>(
      _ taskLocal: TaskLocal<Value>,
      _ value: Value
    ) -> Self
    where Self == TaskLocalTrait<Value> {
      TaskLocalTrait(taskLocal: taskLocal, value: value)
    }
  }

  extension TaskLocal {
    /// Override a task local value for the duration of a test or suite.
    ///
    /// A convenience method version of ``Testing/Trait/taskLocal(_:_:)``:
    ///
    /// ```swift
    /// @Suite($myValue.set(42)) struct MyTests {
    ///   // ...
    /// }
    /// ```
    ///
    /// - Parameter value: The value to set.
    public func `set`(_ value: Value) -> TaskLocalTrait<Value> {
      .taskLocal(self, value)
    }
  }

  /// A test trait that overrides a task local value for the scope of a test.
  ///
  /// Apply this trait to a suite or test to run it with a specific task local value:
  ///
  /// ```swift
  /// @Suite(.taskLocal($myValue, 42))
  /// struct MyTests {
  ///   @Test func example() {
  ///     #expect(myValue == 42)
  ///   }
  /// }
  /// ```
  public struct TaskLocalTrait<Value: Sendable>: SuiteTrait, TestScoping, TestTrait {
    public let isRecursive = true

    fileprivate let taskLocal: TaskLocal<Value>
    fileprivate let value: Value

    public func provideScope(
      for test: Test,
      testCase: Test.Case?,
      performing function: @concurrent () async throws -> Void
    ) async throws {
      try await taskLocal.withValue(value) {
        try await function()
      }
    }
  }
#endif

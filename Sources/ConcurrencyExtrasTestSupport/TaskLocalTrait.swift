import Testing

/// A test trait that overrides a task local value for the scope of a test.
///
/// Apply this trait to a suite or test to run it with a specific task local value:
///
/// ```swift
/// @Suite(.taskLocal(\.myValue, 42))
/// struct MyTests {
///   @Test func example() {
///     #expect(MyLocal.myValue == 42)
///   }
/// }
/// ```
public struct TaskLocalTrait<Value: Sendable>: SuiteTrait, TestTrait, TestScoping {
  public let isRecursive = true
  let taskLocal: TaskLocal<Value>
  let value: Value

  public func provideScope(
    for test: Test,
    testCase: Test.Case?,
    performing function: @Sendable () async throws -> Void
  ) async throws {
    guard testCase != nil else {
      try await function()
      return
    }
    try await taskLocal.withValue(value) {
      try await function()
    }
  }
}

extension Trait {
  /// Override a task local value for the duration of a test or suite.
  ///
  /// - Parameters:
  ///   - taskLocal: The task local to override.
  ///   - value: The value to set.
  public static func taskLocal<Value: Sendable>(
    _ taskLocal: TaskLocal<Value>,
    _ value: Value
  ) -> Self where Self == TaskLocalTrait<Value> {
    TaskLocalTrait(taskLocal: taskLocal, value: value)
  }
}

extension Result where Failure == Swift.Error {
  /// Creates a new result by evaluating an async throwing closure, capturing the returned value as
  /// a success, or any thrown error as a failure.
  ///
  /// - Parameter body: A throwing closure to evaluate.
  @_transparent
  @_unsafeInheritExecutor
  public static func catching(_ body: () async throws -> Success) async -> Self {
    do {
      return .success(try await body())
    } catch {
      return .failure(error)
    }
  }

  // NB: `@_unsafeInheritExecutor` is not compatible with initializers.
  @available(*, unavailable, renamed: "Result.catching")
  public init(catching body: () async throws -> Success) async {
    fatalError()
  }
}

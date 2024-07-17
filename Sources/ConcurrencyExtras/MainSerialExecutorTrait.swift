#if canImport(Testing)
  @_spi(Experimental) import Testing

  @_spi(Experimental)
  extension Trait where Self == _MainSerialExecutorTrait {
    public static var mainSerialExecutor: Self {
      _MainSerialExecutorTrait()
    }
  }

  @_spi(Experimental)
  public struct _MainSerialExecutorTrait: CustomExecutionTrait, SuiteTrait, TestTrait {
    public let isRecursive = true

    public func execute(
      _ function: @Sendable @escaping () async throws -> Void,
      for test: Test,
      testCase: Test.Case?
    ) async throws {
      try await withMainSerialExecutor {
        try await function()
      }
    }
  }
#endif

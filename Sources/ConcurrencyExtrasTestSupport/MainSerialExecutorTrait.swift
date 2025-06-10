#if !os(WASI) && !os(Windows) && !os(Android)
  import ConcurrencyExtras

  #if canImport(Testing)
  import Testing
  public struct _MainSerialExecutorTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
  }

  public extension Trait where Self == _MainSerialExecutorTrait {
    static var mainSerialExecutor: Self { Self() }
  }

    #if compiler(>=6.1)
    extension _MainSerialExecutorTrait: TestScoping {
      public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
      ) async throws {
        try await withMainSerialExecutor {
          try await function()
        }
      }
    }
    #endif
  #endif
#endif

#if compiler(>=6.4)
  import ConcurrencyExtras
  import Testing

  @MainActor
  struct TaskNeverTests {
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: 1...1000)
    func `Task.never() immediately unsuspends when cancelled`(_: Int) async throws {
      var didFinish = false
      _ = Task.immediate {
        withUnsafeCurrentTask { $0?.cancel() }
        try? await Task.never()
        didFinish = true
      }
      #expect(didFinish == true)
    }

    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: 1...1000)
    func `Task.never() immediately unsuspends when cancelled - return value`(_: Int) async throws {
      var didFinish = false
      _ = Task.immediate {
        withUnsafeCurrentTask { $0?.cancel() }
        #expect((try? await Task.never() as Int) == nil)
        didFinish = true
      }
      #expect(didFinish == true)
    }

    @Test func `Task.never() throws when cancelled while suspending`() async {
      await withTaskGroup(of: Void.self) { group in
        for _ in 0..<8 {
          group.addTask {
            for _ in 0..<50_000 {
              let parent = Task {
                try await withThrowingTaskGroup(of: Void.self) { group in
                  group.addTask { try await Task.never() }
                  group.addTask { _ = try await Task.never() as Int }
                  try await group.next()
                }
              }
              parent.cancel()
              if case .success = await parent.result {
                Issue.record("'Task.never()' returned instead of throwing")
              }
            }
          }
        }
      }
    }
  }
#endif

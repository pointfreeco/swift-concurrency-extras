import ConcurrencyExtras
import Testing

@MainActor
struct TaskNeverTests {
  @available(iOS 26, macOS 26, tvOS 26, watchOS 26, visionOS 26, *)
  @Test func `Task.never() immediately unsuspends when cancelled`() async throws {
    var didFinish = false
    _ = Task.immediate {
      withUnsafeCurrentTask { $0?.cancel() }
      try? await Task.never()
      didFinish = true
    }
    #expect(didFinish == true)
  }

  @available(iOS 26, macOS 26, tvOS 26, watchOS 26, visionOS 26, *)
  @Test func `Task.never() immediately unsuspends when cancelled - return value`() async throws {
    var didFinish = false
    _ = Task.immediate {
      withUnsafeCurrentTask { $0?.cancel() }
      let _ = try? await Task.never() as Int
      didFinish = true
    }
    #expect(didFinish == true)
  }
}

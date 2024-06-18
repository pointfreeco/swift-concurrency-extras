import ConcurrencyExtras
import XCTest

final class MainSerialExecutorTests: XCTestCase {
  func testSerializedExecution() async {
    let xs = LockIsolated<[Int]>([])
    await withMainSerialExecutor {
      await withTaskGroup(of: Void.self) { group in
        for x in 1...1000 {
          group.addTask {
            xs.withValue { $0.append(x) }
          }
        }
      }
    }
    XCTAssertEqual(Array(1...1000), xs.value)
  }

  func testSerializedExecution_WithActor() async {
    let xs = ActorIsolated<[Int]>([])
    await withMainSerialExecutor {
      await withTaskGroup(of: Void.self) { group in
        for x in 1...1000 {
          group.addTask {
            await xs.withValue { $0.append(x) }
          }
        }
      }
    }
    let value = await xs.value
    XCTAssertEqual(Array(1...1000), value)
  }

  func testSerializedExecution_YieldEveryOtherValue() async {
    let xs = LockIsolated<[Int]>([])
    await withMainSerialExecutor {
      await withTaskGroup(of: Void.self) { group in
        for x in 1...1000 {
          group.addTask {
            if x.isMultiple(of: 2) { await Task.yield() }
            xs.withValue { $0.append(x) }
          }
        }
      }
    }
    XCTAssertEqual(
      Array(0...499).map { $0 * 2 + 1 } + Array(1...500).map { $0 * 2 },
      xs.value
    )
  }

  func testSerializedExecution_UnstructuredTasks() async {
    await withMainSerialExecutor {
      let xs = LockIsolated<[Int]>([])
      for x in 1...1000 {
        Task { xs.withValue { $0.append(x) } }
      }
      while xs.count < 1_000 { await Task.yield() }
      XCTAssertEqual(Array(1...1000), xs.value)
    }
  }

  func testUncheckedUseMainSerialExecutor() async {
    uncheckedUseMainSerialExecutor = true
    defer { uncheckedUseMainSerialExecutor = false }

    let xs = LockIsolated<[Int]>([])
    await withTaskGroup(of: Void.self) { group in
      for x in 1...1000 {
        group.addTask {
          xs.withValue { $0.append(x) }
        }
      }
    }
    XCTAssertEqual(Array(1...1000), xs.value)
  }

  func testOverlappingTaskOutsideOfScope() async throws {
    guard #available(macOS 13, iOS 16, watchOS 9, tvOS 16, *) else { return }

    let overlappingTask = Task {
      try await Task.sleep(for: .milliseconds(500))
      Task {
        XCTAssertEqual({ Thread.current.isMainThread }(), true)
      }
    }

    try await withMainSerialExecutor {
      try await Task.sleep(for: .seconds(1))
    }

    try await overlappingTask.value
  }

  func testDetachedTask() async {
    await withMainSerialExecutor {
      await Task.detached {
        XCTAssertEqual({ Thread.current.isMainThread }(), true)
      }.value
    }
  }

  func testUnstructuredTask() async {
    await withMainSerialExecutor {
      await Task {
        XCTAssertTrue({ Thread.current.isMainThread }())
      }.value
    }
  }

}

final class MainSerialExecutorInvocationTests: XCTestCase {
  override func invokeTest() {
    withMainSerialExecutor {
      super.invokeTest()
    }
  }

  func testSerializedExecution() async {
    let xs = LockIsolated<[Int]>([])
    await withTaskGroup(of: Void.self) { group in
      for x in 1...1000 {
        group.addTask {
          xs.withValue { $0.append(x) }
        }
      }
    }
    XCTAssertEqual(Array(1...1000), xs.value)
  }

  func testSerializedExecution_UnstructuredTasks() async {
    let xs = LockIsolated<[Int]>([])
    for x in 1...1000 {
      Task { xs.withValue { $0.append(x) } }
    }
    await Task.yield()
    XCTAssertEqual(Array(1...1000), xs.value)
  }
}

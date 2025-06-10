#if !os(WASI) && !os(Windows) && !os(Android)
  #if canImport(Testing)
    import ConcurrencyExtras
    import ConcurrencyExtrasTestSupport
    import Testing

    @Suite(.mainSerialExecutor)
    struct MainSerialExecutorSuiteTraitTests {
      @Test func serializedExecution_Suite() async {
        let xs = LockIsolated<[Int]>([])
        await withTaskGroup(of: Void.self) { group in
          for x in 1...1000 {
            group.addTask {
              xs.withValue { $0.append(x) }
            }
          }
        }
        #expect(Array(1...1000) == xs.value)
      }

      @Test func testSerializedExecution_UnstructuredTasks_Suite() async {
        let xs = LockIsolated<[Int]>([])
        for x in 1...1000 {
          Task { xs.withValue { $0.append(x) } }
        }
        while xs.value.count < 1_000 { await Task.yield() }
        #expect(xs.value.count == 1000)
      }
    }

    @Test(.mainSerialExecutor)
    func serializedExecution_Test() async {
      let xs = LockIsolated<[Int]>([])
      await withTaskGroup(of: Void.self) { group in
        for x in 1...1000 {
          group.addTask {
            xs.withValue { $0.append(x) }
          }
        }
      }
      #expect(Array(1...1000) == xs.value)
    }

    @Test(.mainSerialExecutor)
    func testSerializedExecution_UnstructuredTasks_Test() async {
      let xs = LockIsolated<[Int]>([])
      for x in 1...1000 {
        Task { xs.withValue { $0.append(x) } }
      }
      while xs.value.count < 1_000 { await Task.yield() }
      #expect(xs.value.count == 1000)
    }
  #endif
#endif

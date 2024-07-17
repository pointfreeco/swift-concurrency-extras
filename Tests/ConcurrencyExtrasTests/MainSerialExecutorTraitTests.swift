#if canImport(Testing)
  @_spi(Experimental) import ConcurrencyExtras
  import Testing

@Test(.mainSerialExecutor)
func serializedExecution() async {
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
  #expect(Array(1...1000) == xs.value)
}

@Suite(.mainSerialExecutor)
struct MainSerialExecutorSuite {
  @Test 
  func serializedExecution() async {
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
    #expect(Array(1...1000) == xs.value)
  }
}
#endif

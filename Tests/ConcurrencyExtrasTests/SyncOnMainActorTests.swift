import Testing
import Foundation
import ConcurrencyExtras

@Suite
struct SyncOnMainActorTests {
  @MainActor
  private struct MainActorIsolatedType {}

  @Test
  func testOnMainActor() async {
    await Task { @MainActor in
      var count: Int = 0

      syncOnMainActor {
        _ = MainActorIsolatedType()
        count = 1
      }

      // Closure executed syncroniously without deadlock on main actor
      #expect(count == 1)
    }.value
  }

  @Test
  func testOnDetachedTask() async {
    await Task.detached {
      var count: Int = 0

      syncOnMainActor {
        _ = MainActorIsolatedType()
        count = 1
      }

      // Closure executed syncroniously
      #expect(count == 1)
    }.value
  }

  @Test
  func testOnMainQueue() async {
    DispatchQueue.main.asyncAndWait {
      var count: Int = 0

      syncOnMainActor {
        _ = MainActorIsolatedType()
        count = 1
      }

      // Closure executed syncroniously without deadlock on main queue
      #expect(count == 1)
    }
  }

  @Test
  func testOnBackgroundQueue() async {
    DispatchQueue.global(qos: .background).asyncAndWait {
      var count: Int = 0

      syncOnMainActor {
        _ = MainActorIsolatedType()
        count = 1
      }

      // Closure executed syncroniously
      #expect(count == 1)
    }
  }
}

import ConcurrencyExtras
import Testing

struct ResultTests {
  struct SomeError: Error, Equatable {}
  func f(_ value: Int) async throws -> Int {
    if value == 42 {
      return 42
    } else {
      throw SomeError()
    }
  }

  @Test func basics() async throws {
    do {
      let res = await Result { try await f(42) }
      #expect(try res.get() == 42)
    }
    do {
      let res = await Result { try await f(0) }
      do {
        _ = try res.get()
      } catch let error as SomeError {
        #expect(error == SomeError())
      } catch {
        Issue.record(error, "unexpected error: \(error)")
      }
    }
  }

  #if compiler(>=6)
    func g(_ value: Int) async throws(SomeError) -> Int {
      if value == 42 {
        return 42
      } else {
        throw SomeError()
      }
    }

    @Test func typedThrows() async {
      let res = await Result { () async throws(SomeError) -> Int in try await g(0) }
      do {
        _ = try res.get()
      } catch {
        #expect(error == SomeError())
      }
    }

    func h() async throws(SomeError) -> Int {
      throw SomeError()
    }

    @Test func typedThrowsInference() async {
      let res = await Result(catching: h)
      do {
        _ = try res.get()
      } catch {
        #expect(error == SomeError())
      }
    }
  #endif
}

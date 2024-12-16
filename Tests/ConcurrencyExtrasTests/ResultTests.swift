import ConcurrencyExtras
import XCTest

final class ResultTests: XCTestCase {
  struct SomeError: Error, Equatable {}
  func f(_ value: Int) async throws -> Int {
    if value == 42 {
      return 42
    } else {
      throw SomeError()
    }
  }

  func testBasics() async {
    do {
      let res = await Result { try await f(42) }
      XCTAssertEqual(try res.get(), 42)
    }
    do {
      let res = await Result { try await f(0) }
      do {
        _ = try res.get()
      } catch let error as SomeError {
        XCTAssertEqual(error, SomeError())
      } catch {
        XCTFail("unexpected error: \(error)")
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

    func testTypedThrows() async {
      let res = await Result { () async throws(SomeError) -> Int in try await g(0) }
      do {
        _ = try res.get()
      } catch {
        XCTAssertEqual(error, SomeError())
      }
    }

    func h() async throws(SomeError) -> Int {
      throw SomeError()
    }

    func testTypedThrowsInference() async {
      let res = await Result(catching: h)
      do {
        _ = try res.get()
      } catch {
        XCTAssertEqual(error, SomeError())
      }
    }
  #endif
}

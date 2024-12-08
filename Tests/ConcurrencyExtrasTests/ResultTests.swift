import ConcurrencyExtras
import XCTest

final class ResultTests: XCTestCase {
  struct SomeError: Error, Equatable { }
  func f(_ value: Int) async throws -> Int {
    if value == 42 {
      return 42
    } else {
      throw SomeError()
    }
  }

  func testBasics() async throws {
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

  func g(_ value: Int) async throws(SomeError) -> Int {
    if value == 42 {
      return 42
    } else {
      throw SomeError()
    }
  }

  func testTypedThrows() async throws {
    do {
      let res = await Result { () async throws(SomeError) -> Int in try await g(0) }
      do {
        _ = try res.get()
      } catch {
        XCTAssertEqual(error, SomeError())
      }
    }
  }
}

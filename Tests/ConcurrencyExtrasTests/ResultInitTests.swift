import ConcurrencyExtras
import XCTest

final class ResultInitTests: XCTestCase {
  func testIntFactory() async {
    let zero = await IntFactory().zero()
    switch zero {
    case .success(let success):
      XCTAssertEqual(success, 0)
    case .failure(let failure):
      XCTFail(failure.localizedDescription)
    }
  }
}

func makeInt(closure: @escaping () async throws -> Int) async throws -> Int {
  try await closure()
}

actor IntFactory {
  func zero() async -> Result<Int, Error> {
    await Result {
      try await makeInt { 0 }
    }
  }
}

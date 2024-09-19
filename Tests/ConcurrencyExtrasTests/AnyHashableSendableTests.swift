import ConcurrencyExtras
import XCTest

final class AnyHashableSendableTests: XCTestCase {
  func testBasics() {
    XCTAssertEqual(AnyHashableSendable(1), AnyHashableSendable(1))
    XCTAssertNotEqual(AnyHashableSendable(1), AnyHashableSendable(2))

    func make(_ base: some Hashable & Sendable) -> AnyHashableSendable {
      AnyHashableSendable(base)
    }

    let flat = make(1)
    let nested = make(flat)

    XCTAssertEqual(flat, nested)
  }
}

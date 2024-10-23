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

  func testExistential() {
    let base: (any Hashable & Sendable)? = 1
    let wrapped = base.map(AnyHashableSendable.init)
    XCTAssertEqual(wrapped, AnyHashableSendable(1))
  }

  func testAnyHashable() {
    XCTAssertEqual(AnyHashableSendable(1), 1 as AnyHashable)
  }

  func testLiterals() {
    XCTAssertEqual(AnyHashableSendable(true), true)
    XCTAssertEqual(AnyHashableSendable(1), 1)
    XCTAssertEqual(AnyHashableSendable(4.2), 4.2)
    XCTAssertEqual(AnyHashableSendable("Blob"), "Blob")

    let bool: AnyHashableSendable = true
    XCTAssertEqual(bool.base as? Bool, true)
    XCTAssertEqual(bool as AnyHashable as? Bool, true)
  }
}

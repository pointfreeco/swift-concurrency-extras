import ConcurrencyExtras
import XCTest

final class LockIsolatedTests: XCTestCase {
	func testLockThreadSafety() {
		let value = LockIsolated(0)
		let iterations = 100_000
		let group = DispatchGroup()
		
		for _ in 1 ... iterations {
			group.enter()
			DispatchQueue.global().async {
				value.withValue { value in
					value += 1
				}
				group.leave()
			}
		}
		
		for _ in 1 ... iterations {
			group.enter()
			DispatchQueue.global().async {
				_ = value.value
				group.leave()
			}
		}
		
		group.wait()
		XCTAssertEqual(value.value, iterations)
	}
	
	func testInitializationWithValue() {
		let value = 10
		let lockIsolated = LockIsolated(value)
		XCTAssertEqual(lockIsolated.value, value)
	}
	
	func testInitializationWithClosure() {
		let lockIsolated = LockIsolated<Int>(
			1 + 1
		)
		XCTAssertEqual(lockIsolated.value, 2)
	}
	
	func testDynamicMemberLookup() {
		struct TestValue: Sendable {
			var x = 0
			var y = 10
		}
		
		let testValue = TestValue()
		let lockIsolated = LockIsolated(testValue)
		
		XCTAssertEqual(lockIsolated.x, testValue.x)
		XCTAssertEqual(lockIsolated.y, testValue.y)
	}
	
	func testWithValue() {
		let initialValue = 0
		let lockIsolated = LockIsolated(initialValue)
		let result = lockIsolated.withValue { value in
			value += 1
			return String(value)
		}
		
		XCTAssertEqual(result, "1")
		XCTAssertEqual(lockIsolated.value, 1)
	}
	
	func testSetValue() {
		let initialValue = 0
		let lockIsolated = LockIsolated(initialValue)
		lockIsolated.setValue(2)
		XCTAssertEqual(lockIsolated.value, 2)
	}
	
	func testEquatable() {
		let firstValue = 2
		let secondValue = 2
		let thirdValue = 3
		let firstLockIsolated = LockIsolated(firstValue)
		let secondLockIsolated = LockIsolated(secondValue)
		let thirdLockIsolated = LockIsolated(thirdValue)
		
		XCTAssertTrue(firstLockIsolated == secondLockIsolated)
		XCTAssertFalse(firstLockIsolated == thirdLockIsolated)
	}
	
	func testHashable() {
		let firstValue = 1
		let secondValue = 1
		let thirdValue = 2
		let firstLockIsolated = LockIsolated(firstValue)
		let secondLockIsolated = LockIsolated(secondValue)
		let thirdLockIsolated = LockIsolated(thirdValue)
		
		XCTAssertEqual(firstLockIsolated.hashValue, secondLockIsolated.hashValue)
		XCTAssertNotEqual(firstLockIsolated.hashValue, thirdLockIsolated.hashValue)
	}
}

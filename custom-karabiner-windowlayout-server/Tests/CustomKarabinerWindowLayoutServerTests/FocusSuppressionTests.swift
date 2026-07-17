import XCTest

@testable import CustomKarabinerWindowLayoutServer

final class FocusSuppressionTests: XCTestCase {
  private let now = ContinuousClock.now

  func testSuppressesRepeatedEventsForExpectedWindow() {
    var suppression = FocusSuppression<Int>(ttl: .milliseconds(200))
    suppression.register(key: 42, now: now)

    XCTAssertEqual(suppression.decide(key: 42, now: now), .suppressed)
    XCTAssertEqual(
      suppression.decide(key: 42, now: now + .milliseconds(100)),
      .suppressed)
  }

  func testDifferentWindowResetsAndClearsSuppression() {
    var suppression = FocusSuppression<Int>(ttl: .milliseconds(200))
    suppression.register(key: 42, now: now)

    XCTAssertEqual(suppression.decide(key: 99, now: now), .resetCleared)
    XCTAssertEqual(suppression.decide(key: 42, now: now), .noSuppression)
  }

  func testExpiredSuppressionResetsAndClears() {
    var suppression = FocusSuppression<Int>(ttl: .milliseconds(100))
    suppression.register(key: 42, now: now)

    XCTAssertEqual(
      suppression.decide(key: 42, now: now + .milliseconds(100)),
      .expiredCleared)
    XCTAssertEqual(suppression.decide(key: 42, now: now), .noSuppression)
  }

  func testRegisterReplacesExpectedWindow() {
    var suppression = FocusSuppression<Int>(ttl: .milliseconds(200))
    suppression.register(key: 42, now: now)
    suppression.register(key: 77, now: now)

    XCTAssertEqual(suppression.decide(key: 77, now: now), .suppressed)
    XCTAssertEqual(suppression.decide(key: 42, now: now), .resetCleared)
  }

  func testClearRemovesSuppression() {
    var suppression = FocusSuppression<Int>(ttl: .milliseconds(200))
    suppression.register(key: 42, now: now)
    suppression.clear()

    XCTAssertEqual(suppression.decide(key: 42, now: now), .noSuppression)
  }
}

import XCTest

@testable import CustomKarabinerWindowLayoutServer

final class ObserverRegistrationRetryPolicyTests: XCTestCase {
  private let policy = ObserverRegistrationRetryPolicy(
    maxRetries: 3,
    baseDelay: .milliseconds(10))

  func testRetriesWithExponentialBackoff() {
    XCTAssertEqual(
      policy.decision(after: 0, sameApplicationFrontmost: true),
      .retry(after: .milliseconds(10)))
    XCTAssertEqual(
      policy.decision(after: 2, sameApplicationFrontmost: true),
      .retry(after: .milliseconds(40)))
  }

  func testStopsAfterRetryBudgetIsExhausted() {
    XCTAssertEqual(
      policy.decision(after: 3, sameApplicationFrontmost: true),
      .giveUp(.retriesExhausted))
  }

  func testStopsWhenApplicationIsNoLongerFrontmost() {
    XCTAssertEqual(
      policy.decision(after: 0, sameApplicationFrontmost: false),
      .giveUp(.applicationNoLongerFrontmost))
  }

  func testBackoffIsCapped() {
    let policy = ObserverRegistrationRetryPolicy(
      maxRetries: 100,
      baseDelay: .milliseconds(10))
    XCTAssertEqual(
      policy.decision(after: 100, sameApplicationFrontmost: true),
      .giveUp(.retriesExhausted))
    XCTAssertEqual(
      policy.decision(after: 6, sameApplicationFrontmost: true),
      policy.decision(after: 99, sameApplicationFrontmost: true))
  }
}

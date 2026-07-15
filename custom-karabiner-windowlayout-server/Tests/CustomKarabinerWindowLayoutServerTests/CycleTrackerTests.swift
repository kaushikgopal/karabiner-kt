import XCTest

@testable import CustomKarabinerWindowLayoutServer

private struct TestWindowToken: WindowCycleToken {
  let bundleIdentifier: String
  let elementHash: UInt
}

final class CycleTrackerTests: XCTestCase {
  func testRepeatedCommandCyclesAndWraps() {
    var tracker = CycleTracker<TestWindowToken>()
    let window = token(bundleIdentifier: "example.app", elementHash: 1)

    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "left", window: window, stepCount: 3), 0)
    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "left", window: window, stepCount: 3), 1)
    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "left", window: window, stepCount: 3), 2)
    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "left", window: window, stepCount: 3), 0)
  }

  func testChangingCommandOrWindowResetsCycle() {
    var tracker = CycleTracker<TestWindowToken>()
    let firstWindow = token(bundleIdentifier: "example.app", elementHash: 1)
    let secondWindow = token(bundleIdentifier: "example.app", elementHash: 2)

    _ = tracker.nextIndex(commandIdentifier: "left", window: firstWindow, stepCount: 3)
    XCTAssertEqual(
      tracker.nextIndex(commandIdentifier: "right", window: firstWindow, stepCount: 3), 0)
    XCTAssertEqual(
      tracker.nextIndex(commandIdentifier: "right", window: secondWindow, stepCount: 3), 0)
  }

  func testApplicationFocusChangeResetsCycle() {
    var tracker = CycleTracker<TestWindowToken>()
    let window = token(bundleIdentifier: "example.app", elementHash: 1)

    _ = tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2)
    tracker.applicationDidActivate(bundleIdentifier: "another.app")

    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2), 0)
  }

  func testFocusedWindowChangeResetsCycleEvenWhenReturningToSameWindow() {
    var tracker = CycleTracker<TestWindowToken>()
    let window = token(bundleIdentifier: "example.app", elementHash: 1)

    _ = tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2)
    tracker.focusedWindowDidChange()
    tracker.focusedWindowDidChange()

    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2), 0)
  }

  func testSameApplicationActivationPreservesCycle() {
    var tracker = CycleTracker<TestWindowToken>()
    let window = token(bundleIdentifier: "example.app", elementHash: 1)

    _ = tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2)
    tracker.applicationDidActivate(bundleIdentifier: "example.app")

    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2), 1)
  }

  func testApplicationChangeResetDisabledPreservesCycleAcrossApplications() {
    var tracker = CycleTracker<TestWindowToken>()
    tracker.cyclePolicy = CyclePolicy(
      resetOnApplicationChange: false,
      resetOnFocusedWindowChange: true,
      resetWhenTargetNotFrontmost: false)
    let window = token(bundleIdentifier: "example.app", elementHash: 1)

    _ = tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2)
    tracker.applicationDidActivate(bundleIdentifier: "another.app")

    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2), 1)
  }

  func testFocusedWindowChangeResetDisabledPreservesCycle() {
    var tracker = CycleTracker<TestWindowToken>()
    tracker.cyclePolicy = CyclePolicy(
      resetOnApplicationChange: true,
      resetOnFocusedWindowChange: false,
      resetWhenTargetNotFrontmost: false)
    let window = token(bundleIdentifier: "example.app", elementHash: 1)

    _ = tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2)
    tracker.focusedWindowDidChange()
    tracker.focusedWindowDidChange()

    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2), 1)
  }

  func testResetWhenTargetNotFrontmostForcesFirstLayout() {
    var tracker = CycleTracker<TestWindowToken>()
    let window = token(bundleIdentifier: "example.app", elementHash: 1)

    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2), 0)
    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2), 1)
    XCTAssertEqual(
      tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2, reset: true), 0)
    XCTAssertEqual(tracker.nextIndex(commandIdentifier: "app", window: window, stepCount: 2), 1)
  }

  private func token(bundleIdentifier: String, elementHash: UInt) -> TestWindowToken {
    TestWindowToken(bundleIdentifier: bundleIdentifier, elementHash: elementHash)
  }
}

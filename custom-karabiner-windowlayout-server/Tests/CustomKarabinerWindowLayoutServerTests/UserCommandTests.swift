import XCTest

@testable import CustomKarabinerWindowLayoutServer

final class UserCommandTests: XCTestCase {
  func testDecodesGenericApplicationLayoutCommand() throws {
    let command = try UserCommand.decode(
      json: commandPayload(target: [
        "type": "application",
        "bundle_identifier": "example.app",
        "open_if_needed": true,
        "activate": true,
        "activate_all_windows": true,
        "reset_cycle_when_not_frontmost": true,
      ]))

    guard case .cycleWindowLayout(let layoutCommand) = command else {
      return XCTFail("Expected a window layout command")
    }
    guard case .application(let applicationTarget) = layoutCommand.target else {
      return XCTFail("Expected an application target")
    }
    XCTAssertEqual(applicationTarget.bundleIdentifier, "example.app")
    XCTAssertTrue(applicationTarget.openIfNeeded)
    XCTAssertTrue(applicationTarget.activate)
    XCTAssertTrue(applicationTarget.activateAllWindows)
    XCTAssertEqual(layoutCommand.cycleID, "app:example.app")
    XCTAssertEqual(layoutCommand.screenStrategy, .existing)
    XCTAssertEqual(layoutCommand.screenFrame, .visible)
    XCTAssertEqual(layoutCommand.windowScope, .all)
    XCTAssertEqual(layoutCommand.cascadeOffset.x, 48)
    XCTAssertEqual(layoutCommand.layouts.count, 1)
    XCTAssertEqual(layoutCommand.layouts[0].insets.left.fraction, 0.12)
  }

  func testDecodesFrontmostLayoutCommand() throws {
    let command = try UserCommand.decode(json: commandPayload(target: ["type": "frontmost"]))

    guard case .cycleWindowLayout(let layoutCommand) = command else {
      return XCTFail("Expected a window layout command")
    }
    guard case .frontmost = layoutCommand.target else {
      return XCTFail("Expected a frontmost target")
    }
  }

  func testRejectsUnsupportedVersion() {
    var payload = commandPayload(target: ["type": "frontmost"])
    payload["version"] = 2
    XCTAssertThrowsError(try UserCommand.decode(json: payload))
  }

  func testRejectsApplicationTargetWithoutBundleIdentifier() {
    XCTAssertThrowsError(
      try UserCommand.decode(json: commandPayload(target: ["type": "application"])))
  }

  func testRejectsContradictoryLayoutConstraints() {
    var payload = commandPayload(target: ["type": "frontmost"])
    var layouts = payload["layouts"] as! [[String: Any]]
    layouts[0]["minimum_width"] = 1200
    layouts[0]["maximum_width"] = 800
    payload["layouts"] = layouts

    XCTAssertThrowsError(try UserCommand.decode(json: payload))
  }

  func testRejectsInvalidTimeouts() {
    var payload = commandPayload(target: ["type": "frontmost"])
    payload["timeouts"] = ["poll_interval_milliseconds": 0]

    XCTAssertThrowsError(try UserCommand.decode(json: payload))
  }

  func testRejectsZeroAXMessagingTimeout() {
    var payload = commandPayload(target: ["type": "frontmost"])
    payload["timeouts"] = ["ax_messaging_timeout_seconds": 0]

    XCTAssertThrowsError(try UserCommand.decode(json: payload))
  }

  func testOmittedPolicyGroupsUseDefaultsThatPreserveHistoricalBehavior() throws {
    let command = try UserCommand.decode(json: commandPayload(target: ["type": "frontmost"]))
    guard case .cycleWindowLayout(let layoutCommand) = command else {
      return XCTFail("Expected a window layout command")
    }

    XCTAssertEqual(layoutCommand.windowFilter.standardOnly, true)
    XCTAssertEqual(layoutCommand.windowFilter.rejectMinimized, true)
    XCTAssertEqual(layoutCommand.windowFilter.rejectFullscreen, true)
    XCTAssertEqual(layoutCommand.focusAfterLayout.raiseWindow, true)
    XCTAssertEqual(layoutCommand.focusAfterLayout.refocusWindow, true)
    XCTAssertEqual(layoutCommand.cyclePolicy.resetOnApplicationChange, true)
    XCTAssertEqual(layoutCommand.cyclePolicy.resetOnFocusedWindowChange, true)
    XCTAssertEqual(layoutCommand.cyclePolicy.resetWhenTargetNotFrontmost, false)
    XCTAssertEqual(layoutCommand.timeouts.axMessagingTimeoutSeconds, 1.0)
    XCTAssertEqual(layoutCommand.timeouts.applicationWaitTimeoutMilliseconds, 5000)
    XCTAssertEqual(layoutCommand.timeouts.focusedWindowWaitTimeoutMilliseconds, 5000)
    XCTAssertEqual(layoutCommand.timeouts.pollIntervalMilliseconds, 25)
  }

  func testPartiallyOmittedWindowFilterFillsDefaults() throws {
    var payload = commandPayload(target: ["type": "frontmost"])
    payload["window_filter"] = ["reject_minimized": false]
    let command = try UserCommand.decode(json: payload)
    guard case .cycleWindowLayout(let layoutCommand) = command else {
      return XCTFail("Expected a window layout command")
    }

    XCTAssertEqual(layoutCommand.windowFilter.standardOnly, true)
    XCTAssertEqual(layoutCommand.windowFilter.rejectMinimized, false)
    XCTAssertEqual(layoutCommand.windowFilter.rejectFullscreen, true)
  }

  func testDecodesExplicitPolicyGroups() throws {
    var payload = commandPayload(target: ["type": "frontmost"])
    payload["window_filter"] = [
      "standard_only": false, "reject_minimized": false, "reject_fullscreen": false,
    ]
    payload["focus_after_layout"] = ["raise_window": false, "refocus_window": false]
    payload["cycle_policy"] = [
      "reset_on_application_change": false,
      "reset_on_focused_window_change": false,
      "reset_when_target_not_frontmost": true,
    ]
    payload["timeouts"] = [
      "ax_messaging_timeout_seconds": 2.5,
      "application_wait_timeout_milliseconds": 8000,
      "focused_window_wait_timeout_milliseconds": 6000,
      "poll_interval_milliseconds": 50,
    ]

    let command = try UserCommand.decode(json: payload)
    guard case .cycleWindowLayout(let layoutCommand) = command else {
      return XCTFail("Expected a window layout command")
    }

    XCTAssertEqual(layoutCommand.windowFilter.standardOnly, false)
    XCTAssertEqual(layoutCommand.windowFilter.rejectMinimized, false)
    XCTAssertEqual(layoutCommand.windowFilter.rejectFullscreen, false)
    XCTAssertEqual(layoutCommand.focusAfterLayout.raiseWindow, false)
    XCTAssertEqual(layoutCommand.focusAfterLayout.refocusWindow, false)
    XCTAssertEqual(layoutCommand.cyclePolicy.resetOnApplicationChange, false)
    XCTAssertEqual(layoutCommand.cyclePolicy.resetOnFocusedWindowChange, false)
    XCTAssertEqual(layoutCommand.cyclePolicy.resetWhenTargetNotFrontmost, true)
    XCTAssertEqual(layoutCommand.timeouts.axMessagingTimeoutSeconds, 2.5)
    XCTAssertEqual(layoutCommand.timeouts.applicationWaitTimeoutMilliseconds, 8000)
    XCTAssertEqual(layoutCommand.timeouts.focusedWindowWaitTimeoutMilliseconds, 6000)
    XCTAssertEqual(layoutCommand.timeouts.pollIntervalMilliseconds, 50)
  }

  func testLegacyResetCycleWhenNotFrontmostRemainsAcceptedAsFallback() throws {
    let command = try UserCommand.decode(
      json: commandPayload(target: [
        "type": "application",
        "bundle_identifier": "example.app",
        "reset_cycle_when_not_frontmost": true,
      ]))
    guard case .cycleWindowLayout(let layoutCommand) = command else {
      return XCTFail("Expected a window layout command")
    }

    XCTAssertEqual(layoutCommand.cyclePolicy.resetWhenTargetNotFrontmost, true)
  }

  func testCyclePolicyTakesPrecedenceOverLegacyField() throws {
    var payload = commandPayload(target: [
      "type": "application",
      "bundle_identifier": "example.app",
      "reset_cycle_when_not_frontmost": true,
    ])
    payload["cycle_policy"] = ["reset_when_target_not_frontmost": false]

    let command = try UserCommand.decode(json: payload)
    guard case .cycleWindowLayout(let layoutCommand) = command else {
      return XCTFail("Expected a window layout command")
    }

    XCTAssertEqual(layoutCommand.cyclePolicy.resetWhenTargetNotFrontmost, false)
  }

  func testCyclePolicyFallsBackToLegacyWhenNewKeyAbsent() throws {
    var payload = commandPayload(target: [
      "type": "application",
      "bundle_identifier": "example.app",
      "reset_cycle_when_not_frontmost": true,
    ])
    payload["cycle_policy"] = ["reset_on_application_change": false]

    let command = try UserCommand.decode(json: payload)
    guard case .cycleWindowLayout(let layoutCommand) = command else {
      return XCTFail("Expected a window layout command")
    }

    XCTAssertEqual(layoutCommand.cyclePolicy.resetOnApplicationChange, false)
    XCTAssertEqual(layoutCommand.cyclePolicy.resetWhenTargetNotFrontmost, true)
  }

  private func commandPayload(target: [String: Any]) -> [String: Any] {
    [
      "version": 3,
      "command": "cycle_window_layout",
      "cycle_id": "app:example.app",
      "target": target,
      "screen_strategy": "existing",
      "screen_frame": "visible",
      "window_scope": "all",
      "cascade_offset": ["x": 48, "y": 48],
      "layouts": [
        [
          "insets": [
            "left": ["fraction": 0.12, "points": 0],
            "top": ["fraction": 0.05, "points": 0],
            "right": ["fraction": 0.12, "points": 0],
            "bottom": ["fraction": 0.05, "points": 0],
          ],
          "resize_anchor": ["horizontal": "center", "vertical": "center"],
        ]
      ],
    ]
  }
}

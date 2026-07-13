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
    XCTAssertTrue(applicationTarget.resetCycleWhenNotFrontmost)
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

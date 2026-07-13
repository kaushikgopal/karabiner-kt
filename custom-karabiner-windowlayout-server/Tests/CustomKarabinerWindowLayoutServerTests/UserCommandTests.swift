import XCTest

@testable import CustomKarabinerWindowLayoutServer

final class UserCommandTests: XCTestCase {
  func testDecodesApplicationCycleCommand() throws {
    let command = try UserCommand.decode(json: [
      "version": 2,
      "command": "cycle_application_layout",
      "bundle_identifier": "example.app",
      "window_scope": "all",
      "cascade_offset": 24,
      "layouts": [layoutPayload],
    ])

    guard case .cycleApplication(let applicationCommand) = command else {
      return XCTFail("Expected an application cycle command")
    }
    XCTAssertEqual(applicationCommand.bundleIdentifier, "example.app")
    XCTAssertEqual(applicationCommand.layouts.count, 1)
    XCTAssertEqual(applicationCommand.windowScope, .all)
    XCTAssertEqual(applicationCommand.cascadeOffset, 24)
  }

  func testDefaultsApplicationCommandToFocusedWindow() throws {
    let command = try UserCommand.decode(json: [
      "version": 2,
      "command": "cycle_application_layout",
      "bundle_identifier": "example.app",
      "layouts": [layoutPayload],
    ])

    guard case .cycleApplication(let applicationCommand) = command else {
      return XCTFail("Expected an application cycle command")
    }
    XCTAssertEqual(applicationCommand.windowScope, .focused)
    XCTAssertEqual(applicationCommand.cascadeOffset, 0)
  }

  func testDecodesDirectionalCycleCommand() throws {
    let command = try UserCommand.decode(json: [
      "version": 2,
      "command": "cycle_frontmost_window",
      "direction": "left",
    ])

    guard case .cycleWindow(let windowCommand) = command else {
      return XCTFail("Expected a directional cycle command")
    }
    XCTAssertEqual(windowCommand.direction, .left)
  }

  func testRejectsUnsupportedVersion() {
    XCTAssertThrowsError(
      try UserCommand.decode(json: [
        "version": 1,
        "command": "cycle_frontmost_window",
        "direction": "left",
      ]))
  }

  private let layoutPayload: [String: Any] = [
    "compact_display_width": 1728,
    "regular_display_width": 2560,
    "width": [
      "min": 1050,
      "compact_ratio": 0.632,
      "regular_ratio": 0.5,
      "max": 1550,
    ],
    "height": [
      "min": 720,
      "compact_ratio": 0.923,
      "regular_ratio": 0.9,
      "max": 1500,
    ],
    "compact_horizontal_bias": 0,
    "regular_horizontal_bias": 0.055,
    "edge_padding": 12,
  ]
}

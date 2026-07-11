import CoreGraphics
import XCTest

@testable import CustomKarabinerWindowLayoutServer

final class LayoutCalculatorTests: XCTestCase {
  func testHeliumMatchesLaptopReferenceAndCascades() {
    let frames = LayoutCalculator.frames(
      command: heliumCommand,
      screen: laptopScreen,
      windowCount: 2)

    XCTAssertEqual(
      frames,
      [
        CGRect(x: 340, y: 88, width: 1092, height: 1001),
        CGRect(x: 297, y: 61, width: 1092, height: 1001),
      ])
  }

  func testGhosttyMatchesLaptopReference() {
    let frames = LayoutCalculator.frames(
      command: ghosttyCommand,
      screen: laptopScreen,
      windowCount: 1)

    XCTAssertEqual(frames, [CGRect(x: 14, y: 117, width: 1700, height: 916)])
  }

  func testHeliumUsesRoomierLargeDisplayLayout() {
    let frames = LayoutCalculator.frames(
      command: heliumCommand,
      screen: ScreenGeometry(
        frame: CGRect(x: 0, y: 0, width: 3008, height: 1692),
        visibleFrame: CGRect(x: 0, y: 30, width: 3008, height: 1662)),
      windowCount: 1)

    XCTAssertEqual(frames, [CGRect(x: 917, y: 113, width: 1504, height: 1496)])
  }

  private let laptopScreen = ScreenGeometry(
    frame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
    visibleFrame: CGRect(x: 0, y: 33, width: 1728, height: 1084))

  private let heliumCommand = LayoutCommand(
    version: 1,
    command: "open_and_layout",
    bundleIdentifier: "net.imput.helium",
    compactDisplayWidth: 1728,
    regularDisplayWidth: 2560,
    width: .init(minimum: 1050, compactRatio: 0.632, regularRatio: 0.5, maximum: 1550),
    height: .init(minimum: 720, compactRatio: 0.923, regularRatio: 0.9, maximum: 1500),
    compactHorizontalBias: 0,
    regularHorizontalBias: 0.055,
    cascadeRatio: 0.025,
    edgePadding: 12)

  private let ghosttyCommand = LayoutCommand(
    version: 1,
    command: "open_and_layout",
    bundleIdentifier: "com.mitchellh.ghostty",
    compactDisplayWidth: 1728,
    regularDisplayWidth: 2560,
    width: .init(minimum: 1200, compactRatio: 0.984, regularRatio: 0.86, maximum: 2500),
    height: .init(minimum: 650, compactRatio: 0.845, regularRatio: 0.78, maximum: 1300),
    compactHorizontalBias: 0,
    regularHorizontalBias: 0,
    cascadeRatio: 0.025,
    edgePadding: 12)
}

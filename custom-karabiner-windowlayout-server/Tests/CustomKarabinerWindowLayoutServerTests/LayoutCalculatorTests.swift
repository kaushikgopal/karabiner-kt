import CoreGraphics
import XCTest

@testable import CustomKarabinerWindowLayoutServer

final class LayoutCalculatorTests: XCTestCase {
  func testTallLayoutMatchesLaptopReference() {
    let frame = LayoutCalculator.frame(layout: tallLayout, screen: laptopScreen)

    XCTAssertEqual(frame, CGRect(x: 318, y: 75, width: 1092, height: 1001))
  }

  func testWideLayoutMatchesLaptopReference() {
    let frame = LayoutCalculator.frame(layout: wideLayout, screen: laptopScreen)

    XCTAssertEqual(frame, CGRect(x: 14, y: 117, width: 1700, height: 916))
  }

  func testTallLayoutUsesRoomierLargeDisplayLayout() {
    let frame = LayoutCalculator.frame(
      layout: tallLayout,
      screen: ScreenGeometry(
        frame: CGRect(x: 0, y: 0, width: 3008, height: 1692),
        visibleFrame: CGRect(x: 0, y: 30, width: 3008, height: 1662)))

    XCTAssertEqual(frame, CGRect(x: 917, y: 113, width: 1504, height: 1496))
  }

  func testVerticalDirectionalLayouts() {
    XCTAssertEqual(
      LayoutCalculator.frame(direction: .up, fraction: 0.5, screen: laptopScreen),
      CGRect(x: 0, y: 33, width: 1728, height: 542))
    XCTAssertEqual(
      LayoutCalculator.frame(direction: .up, fraction: 2.0 / 3.0, screen: laptopScreen),
      CGRect(x: 0, y: 33, width: 1728, height: 723))
    XCTAssertEqual(
      LayoutCalculator.frame(direction: .down, fraction: 0.5, screen: laptopScreen),
      CGRect(x: 0, y: 575, width: 1728, height: 542))
    XCTAssertEqual(
      LayoutCalculator.frame(direction: .down, fraction: 2.0 / 3.0, screen: laptopScreen),
      CGRect(x: 0, y: 394, width: 1728, height: 723))
  }

  func testHorizontalDirectionalLayouts() {
    XCTAssertEqual(
      LayoutCalculator.frame(direction: .left, fraction: 0.5, screen: laptopScreen),
      CGRect(x: 0, y: 33, width: 864, height: 1084))
    XCTAssertEqual(
      LayoutCalculator.frame(direction: .left, fraction: 1.0 / 3.0, screen: laptopScreen),
      CGRect(x: 0, y: 33, width: 576, height: 1084))
    XCTAssertEqual(
      LayoutCalculator.frame(direction: .right, fraction: 0.5, screen: laptopScreen),
      CGRect(x: 864, y: 33, width: 864, height: 1084))
    XCTAssertEqual(
      LayoutCalculator.frame(direction: .right, fraction: 2.0 / 3.0, screen: laptopScreen),
      CGRect(x: 576, y: 33, width: 1152, height: 1084))
  }

  private let laptopScreen = ScreenGeometry(
    frame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
    visibleFrame: CGRect(x: 0, y: 33, width: 1728, height: 1084))

  private let tallLayout = ResponsiveLayout(
    compactDisplayWidth: 1728,
    regularDisplayWidth: 2560,
    width: .init(minimum: 1050, compactRatio: 0.632, regularRatio: 0.5, maximum: 1550),
    height: .init(minimum: 720, compactRatio: 0.923, regularRatio: 0.9, maximum: 1500),
    compactHorizontalBias: 0,
    regularHorizontalBias: 0.055,
    edgePadding: 12)

  private let wideLayout = ResponsiveLayout(
    compactDisplayWidth: 1728,
    regularDisplayWidth: 2560,
    width: .init(minimum: 1200, compactRatio: 0.984, regularRatio: 0.86, maximum: 2500),
    height: .init(minimum: 650, compactRatio: 0.845, regularRatio: 0.78, maximum: 1300),
    compactHorizontalBias: 0,
    regularHorizontalBias: 0,
    edgePadding: 12)
}

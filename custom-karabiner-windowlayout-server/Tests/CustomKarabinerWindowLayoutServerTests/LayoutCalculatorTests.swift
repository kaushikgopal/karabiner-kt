import CoreGraphics
import XCTest

@testable import CustomKarabinerWindowLayoutServer

final class LayoutCalculatorTests: XCTestCase {
  func testBuildsFrameFromFractionalAndPointInsets() {
    let layout = makeLayout(
      left: .init(fraction: 0.1, points: 10),
      top: .init(fraction: 0.05, points: 5),
      right: .init(fraction: 0.1, points: 10),
      bottom: .init(fraction: 0.05, points: 5))

    XCTAssertEqual(
      LayoutCalculator.frame(layout: layout, screen: laptopScreen, screenFrame: .visible),
      CGRect(x: 183, y: 92, width: 1362, height: 966))
  }

  func testSupportsFullScreenReferenceFrameAndSizeConstraints() {
    let layout = makeLayout(
      left: .init(fraction: 0.1, points: 0),
      right: .init(fraction: 0.1, points: 0),
      minimumWidth: 1500,
      maximumHeight: 800)

    XCTAssertEqual(
      LayoutCalculator.frame(layout: layout, screen: laptopScreen, screenFrame: .full),
      CGRect(x: 114, y: 159, width: 1500, height: 800))
  }

  func testOffsetsCascadedWindowsWithinReferenceFrame() {
    let frame = CGRect(x: 100, y: 100, width: 1500, height: 900)
    let offset = CascadeOffset(x: 48, y: 24)

    XCTAssertEqual(
      LayoutCalculator.cascadeFrame(
        frame, index: 1, offset: offset, screen: laptopScreen, screenFrame: .visible),
      CGRect(x: 148, y: 124, width: 1500, height: 900))
    XCTAssertEqual(
      LayoutCalculator.cascadeFrame(
        frame, index: 10, offset: offset, screen: laptopScreen, screenFrame: .visible),
      CGRect(x: 228, y: 217, width: 1500, height: 900))
  }

  func testAnchorsWindowAfterApplicationAdjustsRequestedSize() {
    let target = CGRect(x: 254, y: 213, width: 2500, height: 1296)
    let actualSize = CGSize(width: 2525, height: 1220)

    XCTAssertEqual(
      LayoutCalculator.anchoredOrigin(
        targetFrame: target,
        actualSize: actualSize,
        anchor: .init(horizontal: .center, vertical: .center)),
      CGPoint(x: 242, y: 251))
    XCTAssertEqual(
      LayoutCalculator.anchoredOrigin(
        targetFrame: target,
        actualSize: actualSize,
        anchor: .init(horizontal: .right, vertical: .bottom)),
      CGPoint(x: 229, y: 289))
  }

  private func makeLayout(
    left: RelativeLength = .init(fraction: 0, points: 0),
    top: RelativeLength = .init(fraction: 0, points: 0),
    right: RelativeLength = .init(fraction: 0, points: 0),
    bottom: RelativeLength = .init(fraction: 0, points: 0),
    minimumWidth: Double? = nil,
    minimumHeight: Double? = nil,
    maximumWidth: Double? = nil,
    maximumHeight: Double? = nil
  ) -> WindowLayout {
    WindowLayout(
      insets: .init(left: left, top: top, right: right, bottom: bottom),
      resizeAnchor: .init(horizontal: .center, vertical: .center),
      minimumWidth: minimumWidth,
      minimumHeight: minimumHeight,
      maximumWidth: maximumWidth,
      maximumHeight: maximumHeight)
  }

  private let laptopScreen = ScreenGeometry(
    frame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
    visibleFrame: CGRect(x: 0, y: 33, width: 1728, height: 1084))
}

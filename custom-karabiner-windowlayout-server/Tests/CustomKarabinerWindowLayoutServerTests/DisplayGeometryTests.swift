import CoreGraphics
import XCTest

@testable import CustomKarabinerWindowLayoutServer

final class DisplayGeometryTests: XCTestCase {
  // MARK: Primary laptop screen

  func testPrimaryLaptopFrameFlipsToAXTopLeftWithMenuBarInset() {
    // AppKit bottom-left: full frame spans the whole panel; visible frame loses
    // the menu bar (top) and Dock (bottom).
    let display = DisplayGeometry(
      screenFrames: [CGRect(x: 0, y: 0, width: 1728, height: 1117)],
      visibleFrames: [CGRect(x: 0, y: 33, width: 1728, height: 1059)])

    XCTAssertEqual(display.primaryTop, 1117)
    let geometry = display.geometry(at: 0)
    XCTAssertEqual(geometry?.frame, CGRect(x: 0, y: 0, width: 1728, height: 1117))
    // Menu bar (25pt) shows up at the top in AX coords (y origin shifted up);
    // Dock (33pt) shows up at the bottom (reduced height).
    XCTAssertEqual(geometry?.visibleFrame, CGRect(x: 0, y: 25, width: 1728, height: 1059))
  }

  // MARK: Secondary displays in each direction

  func testSecondaryToTheRightOfPrimaryHasNegativeAXYWhenTaller() {
    // Secondary shares AppKit y=0 with the primary but is taller, so its top
    // rises above the primary's top → AX y-origin goes negative.
    let display = DisplayGeometry(
      screenFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 1728, y: 0, width: 2560, height: 1440),
      ],
      visibleFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 1728, y: 0, width: 2560, height: 1440),
      ])

    XCTAssertEqual(
      display.geometry(at: 1)?.frame,
      CGRect(x: 1728, y: -323, width: 2560, height: 1440))
  }

  func testSecondaryToTheLeftOfPrimaryHasNegativeAXXAndY() {
    let display = DisplayGeometry(
      screenFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: -2560, y: 0, width: 2560, height: 1440),
      ],
      visibleFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: -2560, y: 0, width: 2560, height: 1440),
      ])

    XCTAssertEqual(
      display.geometry(at: 1)?.frame,
      CGRect(x: -2560, y: -323, width: 2560, height: 1440))
  }

  func testSecondaryAbovePrimaryHasNegativeAXY() {
    // AppKit: secondary sits on top of the primary, starting at y=1117.
    let display = DisplayGeometry(
      screenFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 0, y: 1117, width: 1728, height: 1080),
      ],
      visibleFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 0, y: 1117, width: 1728, height: 1080),
      ])

    XCTAssertEqual(
      display.geometry(at: 1)?.frame,
      CGRect(x: 0, y: -1080, width: 1728, height: 1080))
  }

  func testSecondaryBelowPrimaryHasPositiveAXYBeyondPrimaryHeight() {
    // AppKit: secondary hangs below the primary, starting at y=-1080.
    let display = DisplayGeometry(
      screenFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 0, y: -1080, width: 1728, height: 1080),
      ],
      visibleFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 0, y: -1080, width: 1728, height: 1080),
      ])

    XCTAssertEqual(
      display.geometry(at: 1)?.frame,
      CGRect(x: 0, y: 1117, width: 1728, height: 1080))
  }

  // MARK: Dock / menu-bar visible-frame offsets

  func testVisibleFrameOffsetsDockOnRightAndMenuBarOnTop() {
    // Right Dock and top menu bar on a secondary display.
    let display = DisplayGeometry(
      screenFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 1728, y: 0, width: 2560, height: 1440),
      ],
      visibleFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        // AppKit visible: 80pt Dock on the right, 25pt menu bar on top, 0 Dock
        // on the bottom → minX=1728, minY=0, width=2480, maxY=1415.
        CGRect(x: 1728, y: 0, width: 2480, height: 1415),
      ])

    let secondary = display.geometry(at: 1)
    XCTAssertEqual(secondary?.visibleFrame.minX, 1728)
    // AX top edge = AppKit top edge flipped. The full frame's AX top is
    // -323; the menu bar consumes 25pt there, so the visible frame's AX
    // y-origin rises to -298. The Dock removes 80pt on the right (width
    // 2560 -> 2480).
    XCTAssertEqual(secondary?.visibleFrame.origin.y, -298)
    XCTAssertEqual(secondary?.visibleFrame.width, 2480)
    XCTAssertEqual(secondary?.visibleFrame.height, 1415)
  }

  // MARK: Selection

  func testSelectsScreenContainingCenteredWindow() {
    let display = DisplayGeometry(
      screenFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 1728, y: 0, width: 2560, height: 1440),
      ],
      visibleFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 1728, y: 0, width: 2560, height: 1440),
      ])

    // Window centered on the primary (AX frame 0,0,1728,1117).
    let centered = CGRect(x: 564, y: 358, width: 600, height: 400)
    XCTAssertEqual(display.screenContaining(frame: centered)?.frame, display.geometry(at: 0)?.frame)

    // Window centered on the secondary (AX frame 1728,-323,2560,1440).
    let centeredSecondary = CGRect(x: 1728 + 980, y: -323 + 520, width: 600, height: 400)
    XCTAssertEqual(
      display.screenContaining(frame: centeredSecondary)?.frame,
      display.geometry(at: 1)?.frame)
  }

  func testStraddlingWindowFallsBackToLargestIntersection() {
    let display = DisplayGeometry(
      screenFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 1728, y: 0, width: 2560, height: 1440),
      ],
      visibleFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 1728, y: 0, width: 2560, height: 1440),
      ])

    // Straddle the boundary with most of the window on the secondary.
    let straddling = CGRect(x: 1500, y: 200, width: 800, height: 600)
    let selected = display.screenContaining(frame: straddling)
    XCTAssertEqual(selected?.frame, display.geometry(at: 1)?.frame)
    // The secondary must own a strictly larger intersection than the primary.
    let primaryArea = display.intersectionArea(display.geometry(at: 0)!.frame, straddling)
    let secondaryArea = display.intersectionArea(display.geometry(at: 1)!.frame, straddling)
    XCTAssertGreaterThan(secondaryArea, primaryArea)
  }

  func testFullyOffscreenWindowFallsBackToPrimary() {
    let display = DisplayGeometry(
      screenFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 1728, y: 0, width: 2560, height: 1440),
      ],
      visibleFrames: [
        CGRect(x: 0, y: 0, width: 1728, height: 1117),
        CGRect(x: 1728, y: 0, width: 2560, height: 1440),
      ])

    // Far offscreen; no center contained, zero intersection with every screen.
    let offscreen = CGRect(x: 50_000, y: 50_000, width: 400, height: 300)
    XCTAssertEqual(
      display.screenContaining(frame: offscreen)?.frame,
      display.geometry(at: 0)?.frame)
  }

  func testEmptyDisplaysYieldNoGeometry() {
    let display = DisplayGeometry(screenFrames: [], visibleFrames: [])
    XCTAssertNil(display.geometry(at: 0))
    XCTAssertNil(display.screenContaining(frame: CGRect(x: 0, y: 0, width: 100, height: 100)))
  }

  // MARK: Logical-point pass-through (no Retina scaling)

  func testLogicalPointDimensionsPassThroughUnchangedOnRetina() {
    // A 2x Retina panel reports the same logical 1728x1117 in both AppKit and
    // AX; backingScaleFactor must not multiply the dimensions.
    let display = DisplayGeometry(
      screenFrames: [CGRect(x: 0, y: 0, width: 1728, height: 1117)],
      visibleFrames: [CGRect(x: 0, y: 0, width: 1728, height: 1117)])

    let geometry = display.geometry(at: 0)
    XCTAssertEqual(geometry?.frame.width, 1728)
    XCTAssertEqual(geometry?.frame.height, 1117)
    XCTAssertEqual(geometry?.visibleFrame.width, 1728)
    XCTAssertEqual(geometry?.visibleFrame.height, 1117)
  }

}

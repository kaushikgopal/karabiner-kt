import CoreGraphics

/// Converts AppKit screen frames to AX coordinates without pixel scaling.
struct DisplayGeometry {
  let screenFrames: [CGRect]
  let visibleFrames: [CGRect]
  let primaryTop: CGFloat

  init(screenFrames: [CGRect], visibleFrames: [CGRect]) {
    precondition(screenFrames.count == visibleFrames.count)
    self.screenFrames = screenFrames
    self.visibleFrames = visibleFrames
    self.primaryTop = screenFrames.first?.maxY ?? 0
  }

  var geometries: [ScreenGeometry] {
    zip(screenFrames, visibleFrames).map { frame, visibleFrame in
      ScreenGeometry(
        frame: accessibilityFrame(frame),
        visibleFrame: accessibilityFrame(visibleFrame))
    }
  }

  func accessibilityFrame(_ frame: CGRect) -> CGRect {
    CGRect(
      x: frame.minX,
      y: primaryTop - frame.maxY,
      width: frame.width,
      height: frame.height)
  }

  func screenContaining(frame: CGRect) -> ScreenGeometry? {
    let geometries = geometries
    let center = CGPoint(x: frame.midX, y: frame.midY)
    if let containing = geometries.first(where: { $0.frame.contains(center) }) {
      return containing
    }
    return geometries.max {
      intersectionArea($0.frame, frame) < intersectionArea($1.frame, frame)
    } ?? geometries.first
  }

  func geometry(at index: Int) -> ScreenGeometry? {
    guard index >= 0, index < geometries.count else { return nil }
    return geometries[index]
  }

  func intersectionArea(_ first: CGRect, _ second: CGRect) -> CGFloat {
    let intersection = first.intersection(second)
    return intersection.isNull ? 0 : intersection.width * intersection.height
  }
}

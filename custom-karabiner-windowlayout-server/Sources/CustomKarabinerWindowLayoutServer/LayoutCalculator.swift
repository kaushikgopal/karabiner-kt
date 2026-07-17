import CoreGraphics

struct ScreenGeometry: Sendable {
  let frame: CGRect
  let visibleFrame: CGRect

  func referenceFrame(_ screenFrame: ScreenFrame) -> CGRect {
    switch screenFrame {
    case .visible: visibleFrame
    case .full: frame
    }
  }
}

struct LayoutCalculator {
  static func frame(
    layout: WindowLayout,
    screen: ScreenGeometry,
    screenFrame: ScreenFrame
  ) -> CGRect {
    let referenceFrame = screen.referenceFrame(screenFrame)
    let left = resolve(layout.insets.left, referenceLength: referenceFrame.width)
    let top = resolve(layout.insets.top, referenceLength: referenceFrame.height)
    let right = resolve(layout.insets.right, referenceLength: referenceFrame.width)
    let bottom = resolve(layout.insets.bottom, referenceLength: referenceFrame.height)
    let availableWidth = max(0, referenceFrame.width - left - right)
    let availableHeight = max(0, referenceFrame.height - top - bottom)
    let width = clamp(
      minimum: min(CGFloat(layout.minimumWidth ?? 0), referenceFrame.width),
      value: availableWidth,
      maximum: min(CGFloat(layout.maximumWidth ?? .greatestFiniteMagnitude), referenceFrame.width))
    let height = clamp(
      minimum: min(CGFloat(layout.minimumHeight ?? 0), referenceFrame.height),
      value: availableHeight,
      maximum: min(
        CGFloat(layout.maximumHeight ?? .greatestFiniteMagnitude), referenceFrame.height))
    let roundedSize = CGSize(width: width.rounded(), height: height.rounded())
    let targetFrame = CGRect(
      x: referenceFrame.minX + left,
      y: referenceFrame.minY + top,
      width: availableWidth,
      height: availableHeight)

    return CGRect(
      origin: anchoredOrigin(
        targetFrame: targetFrame,
        actualSize: roundedSize,
        anchor: layout.resizeAnchor),
      size: roundedSize)
  }

  static func cascadeFrame(
    _ frame: CGRect,
    index: Int,
    offset: CascadeOffset,
    screen: ScreenGeometry,
    screenFrame: ScreenFrame
  ) -> CGRect {
    let referenceFrame = screen.referenceFrame(screenFrame)
    let x = clamp(
      minimum: referenceFrame.minX,
      value: frame.minX + CGFloat(index) * CGFloat(offset.x),
      maximum: referenceFrame.maxX - frame.width)
    let y = clamp(
      minimum: referenceFrame.minY,
      value: frame.minY + CGFloat(index) * CGFloat(offset.y),
      maximum: referenceFrame.maxY - frame.height)
    return CGRect(origin: CGPoint(x: x.rounded(), y: y.rounded()), size: frame.size)
  }

  static func anchoredOrigin(
    targetFrame: CGRect,
    actualSize: CGSize,
    anchor: WindowLayout.ResizeAnchor
  ) -> CGPoint {
    let x: CGFloat
    switch anchor.horizontal {
    case .left: x = targetFrame.minX
    case .center: x = targetFrame.midX - actualSize.width / 2
    case .right: x = targetFrame.maxX - actualSize.width
    }

    let y: CGFloat
    switch anchor.vertical {
    case .top: y = targetFrame.minY
    case .center: y = targetFrame.midY - actualSize.height / 2
    case .bottom: y = targetFrame.maxY - actualSize.height
    }

    return CGPoint(x: x.rounded(), y: y.rounded())
  }

  /// Apps may enforce a different size, so keep the re-anchored frame on its screen.
  static func constrainedAnchoredOrigin(
    targetFrame: CGRect,
    actualSize: CGSize,
    anchor: WindowLayout.ResizeAnchor,
    referenceFrame: CGRect
  ) -> CGPoint {
    let origin = anchoredOrigin(
      targetFrame: targetFrame,
      actualSize: actualSize,
      anchor: anchor)
    return CGPoint(
      x: clamp(
        minimum: referenceFrame.minX,
        value: origin.x,
        maximum: referenceFrame.maxX - actualSize.width),
      y: clamp(
        minimum: referenceFrame.minY,
        value: origin.y,
        maximum: referenceFrame.maxY - actualSize.height))
  }

  private static func resolve(_ length: RelativeLength, referenceLength: CGFloat) -> CGFloat {
    referenceLength * CGFloat(length.fraction) + CGFloat(length.points)
  }

  /// Inverted bounds mean the window is oversized, so pin its leading edge.
  private static func clamp(minimum: CGFloat, value: CGFloat, maximum: CGFloat) -> CGFloat {
    guard minimum <= maximum else { return minimum }
    return min(max(value, minimum), maximum)
  }
}
